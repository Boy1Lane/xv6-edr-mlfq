#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"
#include "vm.h"
#include "pstat.h"

int argaddr(int, uint64 *);
extern struct proc proc[NPROC];
extern volatile int edr_work_pending;
extern struct spinlock alert_lock;
extern struct spinlock wait_lock;
extern int alerts_dropped;
uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
  kexit(n);
  return 0;  // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  int npid;
  struct proc *p = myproc();

  // EDR: tiến trình bị QUARANTINED không được phép tạo tiến trình con (SMP-safe)
  acquire(&p->lock);
  int sandboxed = p->is_sandboxed;
  release(&p->lock);
  if(sandboxed == 2)
    return -1;

  // P2: Global PID-pressure limiter – distributed fork-bomb evasion
  // C1 hardening: first denial marks WARN (1) and rate-limits alerts;
  // subsequent denials are silent. Hard quarantine (2) would deschedule
  // the offender and break legitimate pressure test (pressure.c) which
  // expects to stay runnable to print GLOBAL_PRESSURE_LIMITED. WARN
  // still allows the test to complete while preventing alert flood.
  extern int count_live_processes(void);
  if(count_live_processes() >= EDR_GLOBAL_PRESSURE_THRESHOLD){
    acquire(&p->lock);
    int wl = p->is_whitelisted;
    int trusted = p->edr_trusted;
    int already_warned = (p->is_sandboxed != 0);
    release(&p->lock);
    if(!wl && !trusted){
      if(already_warned){
        // Already warned/quarantined – deny silently, no alert flood
        return -1;
      }
      acquire(&tickslock);
      uint cur = ticks;
      release(&tickslock);
      acquire(&p->lock);
      if(p->is_sandboxed == 0){
        p->is_sandboxed = 1; // WARN, not descheduled (2 would break test)
        p->quarantine_tick = cur;
        p->sandbox_reason = EDR_REASON_GLOBAL_PRESSURE;
        release(&p->lock);
        edr_push_alert(p, EDR_REASON_GLOBAL_PRESSURE);
      } else {
        release(&p->lock);
      }
      return -1;
    }
  }

  npid = kfork();
  if(npid > 0){
    uint current_tick;

    edr_record_system_fork();

    acquire(&tickslock);
    current_tick = ticks;
    release(&tickslock);

    acquire(&p->lock);
    p->fork_times[p->fork_times_idx] = current_tick;
    p->fork_times_idx = (p->fork_times_idx + 1) % EDR_FORK_SAMPLE;
    if(p->fork_times[p->fork_times_idx] != 0){
      uint64 oldest = p->fork_times[p->fork_times_idx];
      // Adaptive window: nới ra khi hệ thống đang bận legitimately (L4).
      if(current_tick - oldest <= edr_fork_window()){
        p->is_sandboxed = 1;
        p->sandbox_reason = EDR_REASON_FORK_RATE;
        p->need_propagation = 1;
        __sync_synchronize();
        edr_work_pending = 1;
      }
    }
    release(&p->lock);
  }
  return npid;
}

// sys_unquarantine -- release hành chính một cây tiến trình bị cách ly.
// Chỉ tiến trình mang cờ edr_trusted (daemon, xác thực bằng SHA-256 tại
// exec-time) được gọi. Trả về 0 nếu ok, -1 nếu không có quyền hoặc pid
// không tồn tại.
uint64
sys_unquarantine(void)
{
  int pid;
  struct proc *root = 0;
  struct proc *pp;

  argint(0, &pid);

  struct proc *p = myproc();
  if(!p->edr_trusted)
    return -1;
  if(pid <= 0)
    return -1;

  acquire(&wait_lock);
  for(pp = proc; pp < &proc[NPROC]; pp++){
    if(pp->pid == pid && pp->state != UNUSED){
      root = pp;
      break;
    }
  }
  if(root == 0){
    release(&wait_lock);
    return -1;
  }

  for(pp = proc; pp < &proc[NPROC]; pp++){
    if(pp->state == UNUSED || pp->state == ZOMBIE)
      continue;
    if(pp != root && !is_descendant(pp, root))
      continue;
    acquire(&pp->lock);
    if(pp->is_sandboxed != 0){
      pp->is_sandboxed = 0;
      pp->sandbox_reason = EDR_REASON_NONE;
      pp->need_propagation = 0;
      pp->quarantine_tick = 0;
      pp->priority = 0;        // trở lại hàng đợi cao nhất
      pp->ticks_used = 0;
    }
    release(&pp->lock);
  }
  release(&wait_lock);
  return 0;
}

uint64
sys_wait(void)
{
  uint64 p;
  if(argaddr(0, &p) < 0)
    return -1;
  return kwait(p);
}

uint64
sys_sbrk(void)
{
  uint64 addr;
  int t;
  int n;

  // EDR: tiến trình bị QUARANTINED không được phép cấp phát thêm bộ nhớ (SMP-safe)
  {
    struct proc *pp = myproc();
    acquire(&pp->lock);
    int sb = pp->is_sandboxed;
    release(&pp->lock);
    if(sb == 2)
      return -1;
  }

  argint(0, &n);
  argint(1, &t);
  addr = myproc()->sz;

  if(t == SBRK_EAGER || n < 0) {
    if(growproc(n) < 0) {
      return -1;
    }
  } else {
    // Lazily allocate memory for this process: increase its memory
    // size but don't allocate memory. If the processes uses the
    // memory, vmfault() will allocate it.
    if(addr + n < addr)
      return -1;
    if(addr + n > TRAPFRAME)
      return -1;
    myproc()->sz += n;
  }
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  if(n < 0)
    n = 0;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);
  return kkill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

uint64
sys_proc_info(void)
{
  uint64 addr;
  struct p_info pinfo;
  struct proc *p;

  // Lấy địa chỉ con trỏ từ user space truyền vào
  if(argaddr(0, &addr) < 0)
    return -1;

  // Duyệt qua bảng tiến trình
  int i = 0;
  for(p = proc; p < &proc[NPROC]; p++){
    // Cần giữ lock khi đọc dữ liệu để tránh race condition (tuỳ chọn nhưng nên làm)
    acquire(&p->lock);
    
    pinfo.pid[i] = p->pid;
    pinfo.state[i] = p->state;
    pinfo.priority[i] = p->priority;    
    pinfo.ticks_used[i] = p->ticks_used;
    pinfo.total_runtime[i] = p->total_runtime;
    pinfo.is_sandboxed[i]  = p->is_sandboxed;

    release(&p->lock);
    i++;
  }

  {
    extern int alerts_dropped;
    acquire(&alert_lock);
    pinfo.alerts_dropped = alerts_dropped;
    release(&alert_lock);
  }

  // Copy dữ liệu từ kernel space ra user space
  // Lưu ý: copyout trả về -1 nếu lỗi, 0 nếu thành công
  if(copyout(myproc()->pagetable, addr, (char *)&pinfo, sizeof(pinfo)) < 0)
    return -1;

  return 0;
}

extern struct alert_entry alerts[];
extern struct spinlock alert_lock;
extern int alert_head;
extern int alert_tail;

// sys_get_security_alerts -- drain toàn bộ cảnh báo đang tồn đọng vào
// buffer của caller (tối đa max entry), trả về số entry đã pop.
// Chỉ tiến trình được xác thực là EDR daemon mới được gọi (edr_trusted).
// Counter alerts_dropped (tràn buffer) được reset sau mỗi lần drain và
// được export qua sys_proc_info cho công cụ giám sát.
uint64
sys_get_security_alerts(void)
{
  uint64 addr;
  int max;
  int n = 0;

  argint(1, &max);
  if(argaddr(0, &addr) < 0)
    return -1;

  struct proc *p = myproc();
  if (!p->edr_trusted) return -1;
  if (max <= 0) return 0;

  // C5 hardening: peek without consuming; only advance tail after
  // successful copyout, otherwise the alert would be lost on -1.
  acquire(&alert_lock);
  while(n < max && alert_head != alert_tail){
    struct alert_entry alert = alerts[alert_tail];
    release(&alert_lock);

    if(copyout(p->pagetable, addr + n * sizeof(alert),
               (char *)&alert, sizeof(alert)) < 0)
      return -1;
    n++;

    acquire(&alert_lock);
    // consume the entry we just successfully copied (single consumer: daemon)
    alert_tail = (alert_tail + 1) % EDR_MAX_ALERTS;
  }
  alerts_dropped = 0;
  release(&alert_lock);

  return n;
}
