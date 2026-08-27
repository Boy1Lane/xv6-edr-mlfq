// kernel/edr.c
// EDR (Endpoint Detection and Response) kernel subsystem.
// Implements:
//   - is_descendant(): process tree traversal
//   - count_live_descendants(): tree volume measurement
//   - edr_push_alert(): alert ring buffer management
//   - propagate_sandbox(): tree-wide quarantine enforcement
//
// Locking: All functions require wait_lock to be held by caller
//          (except edr_push_alert which manages alert_lock internally).

#include "types.h"
#include "param.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

extern struct proc proc[NPROC];
extern struct proc *initproc;
extern uint ticks;

extern struct alert_entry alerts[];
extern struct spinlock alert_lock;
extern struct spinlock tickslock;
extern struct spinlock edr_global_lock;
extern int alert_head;
extern int alert_tail;
extern int alerts_dropped;

// --- Adaptive fork-rate state (P2: protected by edr_global_lock + atomics) ---
uint edr_forks_in_window = 0;   // forks since the current window started
uint edr_fork_ema_x100 = 0;     // EMA of forks-per-window, x100 fixed point
uint edr_last_window = 0;

// edr_record_system_fork -- hệ thống đếm một fork toàn cục (gọi từ sys_fork).
void
edr_record_system_fork(void)
{
  __sync_fetch_and_add(&edr_forks_in_window, 1);
}

// edr_ema_update -- sang cửa sổ mới: cập nhật EMA và reset bộ đếm.
// Gọi từ clockintr khi ticks vượt ranh giới window. P2: SMP-safe via
// edr_global_lock and atomics.
void
edr_ema_update(void)
{
  acquire(&edr_global_lock);
  uint cur_forks = __atomic_load_n(&edr_forks_in_window, __ATOMIC_RELAXED);
  int obs = cur_forks * 100;
  edr_fork_ema_x100 += (obs - (int)edr_fork_ema_x100) * EDR_EMA_ALPHA_PCT / 100;
  __atomic_store_n(&edr_forks_in_window, 0, __ATOMIC_RELAXED);
  release(&edr_global_lock);
}

// edr_fork_window -- độ dài cửa sổ phát hiện hiện hành. Khi hệ thống đang
// bận legitimately (EMA cao), nới cửa sổ để giảm false-positive thay vì
// dùng ngưỡng cứng (DESIGN.md L4). P2: atomic load for SMP.
uint
edr_fork_window(void)
{
  uint ema = __atomic_load_n(&edr_fork_ema_x100, __ATOMIC_RELAXED);
  uint busy = ema / 100;
  uint bonus = busy * EDR_WINDOW_PER_BUSY;
  if(bonus > EDR_WINDOW_MAX_BONUS)
    bonus = EDR_WINDOW_MAX_BONUS;
  return EDR_FORK_RATE_WINDOW_TICKS + bonus;
}

// edr_quarantine_timeout_sweep -- last-resort release (mitigates L3):
// tiến trình bị QUARANTINED quá lâu mà daemon không kịp xử lý (daemon chết,
// treo...) bị đánh dấu killed để nhân tài nguyên, thay vì treo vĩnh viễn.
// Gọi định kỳ từ clockintr; an toàn trên single hart.
void
edr_quarantine_timeout_sweep(void)
{
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    acquire(&p->lock);
    if(p->state != UNUSED && p->state != ZOMBIE &&
       p->is_sandboxed == 2 && p->killed == 0 &&
       ticks - p->quarantine_tick > EDR_QUARANTINE_TIMEOUT_TICKS){
      printf("edr: pid %d (%s) force-released after %d ticks in quarantine\n",
             p->pid, p->name, EDR_QUARANTINE_TIMEOUT_TICKS);
      p->killed = 1;
      if(p->state == SLEEPING)
        p->state = RUNNABLE;
    }
    release(&p->lock);
  }
}

// is_descendant -- kiểm tra xem child có phải là con cháu của root không.
// YÊU CẦU: wait_lock phải được giữ để con trỏ parent ổn định.
int
is_descendant(struct proc *child, struct proc *root)
{
  struct proc *curr = child->parent;
  while(curr){
    if(curr == root) return 1;
    curr = curr->parent;
  }
  return 0;
}

// count_live_descendants -- đếm số tiến trình con còn sống của root.
// YÊU CẦU: wait_lock phải được giữ.
int
count_live_descendants(struct proc *root)
{
  int count = 0;
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++){
    if(p->state != UNUSED && p != root && is_descendant(p, root)){
      count++;
    }
  }
  return count;
}

// count_live_processes -- đếm số tiến trình còn sống toàn hệ thống (SMP-safe)
int
count_live_processes(void)
{
  int n = 0;
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++){
    acquire(&p->lock);
    if(p->state != UNUSED)
      n++;
    release(&p->lock);
  }
  return n;
}

// edr_push_alert -- thêm một cảnh báo vào ring buffer alerts[].
// Tự acquire/release alert_lock — không được gọi khi đang giữ alert_lock.
// Có thể gọi khi đang giữ wait_lock (không vi phạm lock hierarchy).
// p->lock không cần giữ — chỉ đọc p->pid, p->parent->pid, p->name.
// Khi buffer đầy, drop entry cũ nhất và tăng alerts_dropped.
void
edr_push_alert(struct proc *p, uint8 reason)
{
  acquire(&alert_lock);
  int next_head = (alert_head + 1) % EDR_MAX_ALERTS;
  if (next_head == alert_tail) {
    alert_tail = (alert_tail + 1) % EDR_MAX_ALERTS;
    alerts_dropped++;
  }
  alerts[alert_head].pid = p->pid;
  alerts[alert_head].parent_pid = p->parent ? p->parent->pid : 0;
  alerts[alert_head].reason = reason;
  
  if (reason == EDR_REASON_FORK_RATE)
    safestrcpy(alerts[alert_head].reason_str, "Fork Rate Limit Exceeded", 
               sizeof(alerts[alert_head].reason_str));
  else if (reason == EDR_REASON_TREE_VOLUME)
    safestrcpy(alerts[alert_head].reason_str, "Process Tree Volume Exceeded",
               sizeof(alerts[alert_head].reason_str));
  else if (reason == EDR_REASON_GLOBAL_PRESSURE)
    safestrcpy(alerts[alert_head].reason_str, "Global PID Pressure",
               sizeof(alerts[alert_head].reason_str));
  else
    safestrcpy(alerts[alert_head].reason_str, "Unknown EDR Reason",
               sizeof(alerts[alert_head].reason_str));
  
  alerts[alert_head].tick = p->quarantine_tick;
  safestrcpy(alerts[alert_head].name, p->name, sizeof(p->name));
  alert_head = next_head;
  release(&alert_lock);
}

// propagate_sandbox -- lan truyền QUARANTINED xuống toàn bộ cây con.
// YÊU CẦU: wait_lock phải được giữ.
void
propagate_sandbox(struct proc *root)
{
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++){
    if(p->state != UNUSED && p != root && is_descendant(p, root)){
      acquire(&p->lock);
      p->is_sandboxed = 2;
      p->sandbox_reason = EDR_REASON_TREE_VOLUME;
      p->quarantine_tick = ticks;
      release(&p->lock);
      edr_push_alert(p, EDR_REASON_TREE_VOLUME);
    }
  }
}
