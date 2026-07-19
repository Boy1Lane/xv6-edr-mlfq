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
  int npid = kfork();
  if(npid > 0){
    struct proc *p = myproc();
    uint current_tick;

    acquire(&tickslock);
    current_tick = ticks;
    release(&tickslock);

    acquire(&p->lock);
    p->fork_times[p->fork_times_idx] = current_tick;
    p->fork_times_idx = (p->fork_times_idx + 1) % EDR_FORK_SAMPLE;
    if(p->fork_times[p->fork_times_idx] != 0){
      uint64 oldest = p->fork_times[p->fork_times_idx];
      if(current_tick - oldest <= EDR_FORK_RATE_WINDOW_TICKS){
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

uint64
sys_get_security_alerts(void)
{
  uint64 addr;
  if(argaddr(0, &addr) < 0)
    return -1;
  struct proc *p = myproc();
  
  if (!p->edr_trusted) return -1;

  extern int alerts_dropped;
  int dropped = 0;

  acquire(&alert_lock);
  if (alert_head == alert_tail) {
    release(&alert_lock);
    return 0; // No alerts
  }
  struct alert_entry alert = alerts[alert_tail];
  alert_tail = (alert_tail + 1) % EDR_MAX_ALERTS;
  dropped = alerts_dropped;
  alerts_dropped = 0;
  release(&alert_lock);

  if (copyout(p->pagetable, addr, (char *)&alert, sizeof(alert)) < 0)
    return -1;

  return 1 + dropped;
}
