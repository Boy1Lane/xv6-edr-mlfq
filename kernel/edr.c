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
extern int alert_head;
extern int alert_tail;
extern int alerts_dropped;

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
