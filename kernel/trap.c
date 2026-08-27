#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

struct spinlock tickslock;
uint ticks;

extern char trampoline[], uservec[];
extern volatile int edr_work_pending;
extern uint edr_last_window;
extern struct spinlock edr_global_lock;

// in kernelvec.S, calls kerneltrap().
void kernelvec();

extern int devintr();

void
trapinit(void)
{
  initlock(&tickslock, "time");
}

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
  w_stvec((uint64)kernelvec);
}

// mlfq_tick -- xử lý logic MLFQ cho một timer interrupt.
// Gọi từ cả usertrap() và kerneltrap().
// Không được gọi khi không có tiến trình hiện hành (p == 0).
// Trả về 1 nếu cần yield, 0 nếu không.
// P2: Đã chuẩn hóa cho SMP – mọi truy cập p->* đều giữ p->lock,
// ticks được snapshot qua tickslock, has_higher_priority/promote_all
// đều SMP-safe.
int
mlfq_tick(void)
{
  struct proc *p = myproc();
  int need_yield = 0;
#if SCHED_MODE != 1
  uint cur_ticks;
  acquire(&tickslock);
  cur_ticks = ticks;
  release(&tickslock);
#endif

  if(p){
#if SCHED_MODE == 1
    int cur_ticks_used;
    acquire(&p->lock);
    p->ticks_used++;
    p->total_runtime++;
    p->cumulative_run_time++;
    cur_ticks_used = p->ticks_used;
    release(&p->lock);
    #define QUANTUM_RR 4
    if(cur_ticks_used >= QUANTUM_RR){
      acquire(&p->lock);
      p->ticks_used = 0;
      release(&p->lock);
      need_yield = 1;
    }
#else
    int cur_prio, cur_ticks_used, cur_cum;
    acquire(&p->lock);
    p->ticks_used++;
    p->total_runtime++;
    p->cumulative_run_time++;
    cur_prio = p->priority;
    cur_ticks_used = p->ticks_used;
    cur_cum = p->cumulative_run_time;
    release(&p->lock);

    int quantum;
    if(cur_prio == 0)      quantum = QUANTUM_0;
    else if(cur_prio == 1) quantum = QUANTUM_1;
    else                   quantum = QUANTUM_2;

    int demoted = 0;
    if(cur_ticks_used >= quantum){
      acquire(&p->lock);
      if(p->priority < 2)
        p->priority++;
      p->ticks_used = 0;
      p->cumulative_run_time = 0;
      cur_prio = p->priority;
      release(&p->lock);
      demoted = 1;
      need_yield = 1;
    } else if(cur_cum >= quantum){
      acquire(&p->lock);
      if(p->priority < 2)
        p->priority++;
      p->ticks_used = 0;
      p->cumulative_run_time = 0;
      cur_prio = p->priority;
      release(&p->lock);
      demoted = 1;
      need_yield = 1;
    }
    if(!demoted && has_higher_priority(cur_prio)){
      need_yield = 1;
    }
#endif
  }

#if SCHED_MODE != 1
  // Aging toàn hệ thống (mỗi AGING_INTERVAL ticks)
  if(cur_ticks % AGING_INTERVAL == 0){
    promote_all();
    need_yield = 1;
  }
#endif

  return need_yield;
}

//
// handle an interrupt, exception, or system call from user space.
// called from, and returns to, trampoline.S
// return value is user satp for trampoline.S to switch to.
//
uint64
usertrap(void)
{
  int which_dev = 0;

  if((r_sstatus() & SSTATUS_SPP) != 0)
    panic("usertrap: not from user mode");

  // send interrupts and exceptions to kerneltrap(),
  // since we're now in the kernel.
  w_stvec((uint64)kernelvec);  //DOC: kernelvec

  struct proc *p = myproc();
  
  // save user program counter.
  p->trapframe->epc = r_sepc();
  
  if(r_scause() == 8){
    // system call

    if(killed(p))
      kexit(-1);

    // sepc points to the ecall instruction,
    // but we want to return to the next instruction.
    p->trapframe->epc += 4;

    // an interrupt will change sepc, scause, and sstatus,
    // so enable only now that we're done with those registers.
    intr_on();

    syscall();
  } else if((which_dev = devintr()) != 0){
    // ok
  } else if((r_scause() == 15 || r_scause() == 13) &&
            vmfault(p->pagetable, r_stval(), (r_scause() == 13)? 1 : 0) != 0) {
    // page fault on lazily-allocated page
  } else {
    printf("usertrap(): unexpected scause 0x%lx pid=%d\n", r_scause(), p->pid);
    printf("            sepc=0x%lx stval=0x%lx\n", r_sepc(), r_stval());
    setkilled(p);
  }

  if(killed(p))
    kexit(-1);

  // give up the CPU if this is a timer interrupt.
  if(which_dev == 2){
    if(mlfq_tick())
      yield();
  }

  prepare_return();

  // the user page table to switch to, for trampoline.S
  uint64 satp = MAKE_SATP(p->pagetable);

  // return to trampoline.S; satp value in a0.
  return satp;
}

//
// set up trapframe and control registers for a return to user space
//
void
prepare_return(void)
{
  struct proc *p = myproc();

  // we're about to switch the destination of traps from
  // kerneltrap() to usertrap(). because a trap from kernel
  // code to usertrap would be a disaster, turn off interrupts.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
  p->trapframe->kernel_trap = (uint64)usertrap;
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()

  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
  x |= SSTATUS_SPIE; // enable interrupts in user mode
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
}

// interrupts and exceptions from kernel code go here via kernelvec,
// on whatever the current kernel stack is.
void 
kerneltrap()
{
  int which_dev = 0;
  uint64 sepc = r_sepc();
  uint64 sstatus = r_sstatus();
  uint64 scause = r_scause();
  
  if((sstatus & SSTATUS_SPP) == 0)
    panic("kerneltrap: not from supervisor mode");
  if(intr_get() != 0)
    panic("kerneltrap: interrupts enabled");

  if((which_dev = devintr()) == 0){
    // interrupt or trap from an unknown source
    printf("scause=0x%lx sepc=0x%lx stval=0x%lx\n", scause, r_sepc(), r_stval());
    panic("kerneltrap");
  }

  // give up the CPU if this is a timer interrupt.
  if(which_dev == 2 && myproc() != 0){
    if(mlfq_tick())
      yield();
  }

  // the yield() may have caused some traps to occur,
  // so restore trap registers for use by kernelvec.S's sepc instruction.
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void
clockintr()
{
  if(cpuid() == 0){
    acquire(&tickslock);
    ticks++;
    wakeup(&ticks);
    release(&tickslock);
  }

  // Snapshot ticks for consistent view across this handler (SMP-safe)
  uint cur_ticks = __atomic_load_n(&ticks, __ATOMIC_RELAXED);

  // --- EDR Tier-1 Rate-based Detector (P2: SMP-safe) ---
  // Window rollover EMA update - only CPU0 handles it, protected by edr_global_lock
  if(cpuid() == 0){
    uint cur_win = cur_ticks / EDR_FORK_RATE_WINDOW_TICKS;
    uint last_win = __atomic_load_n(&edr_last_window, __ATOMIC_RELAXED);
    if(cur_win != last_win){
      // Use CAS to ensure only one updater wins if multiple harts race (when CPUS>1)
      if(__sync_bool_compare_and_swap(&edr_last_window, last_win, cur_win)){
        edr_ema_update();
      }
    }
  }

  struct proc *p = myproc();
  if(p){
    // Lock p to safely read fork_times ring buffer
    acquire(&p->lock);
    uint idx = p->fork_times_idx;
    uint64 oldest = p->fork_times[idx];
    release(&p->lock);

    if(oldest != 0){
      uint window = edr_fork_window();
      if(cur_ticks - oldest <= window){
        acquire(&p->lock);
        // Re-check under lock to avoid race with sys_fork updating same slot
        if(p->fork_times[p->fork_times_idx] == oldest && p->is_sandboxed == 0){
          p->is_sandboxed = 1;
          p->sandbox_reason = EDR_REASON_FORK_RATE;
          p->need_propagation = 1;
          __sync_synchronize();
          edr_work_pending = 1;
        }
        release(&p->lock);
      }
    }
  }

  // Last-resort quarantine release (L3) - only CPU0 sweeps to avoid contention
  if(cpuid() == 0 && (cur_ticks & 15) == 0)
    edr_quarantine_timeout_sweep();
  // --------------------------------------

  // ask for the next timer interrupt. this also clears
  // the interrupt request. 1000000 is about a tenth
  // of a second.
  w_stimecmp(r_time() + 1000000);
}

// check if it's an external interrupt or software interrupt,
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
  uint64 scause = r_scause();

  if(scause == 0x8000000000000009L){
    // this is a supervisor external interrupt, via PLIC.

    // irq indicates which device interrupted.
    int irq = plic_claim();

    if(irq == UART0_IRQ){
      uartintr();
    } else if(irq == VIRTIO0_IRQ){
      virtio_disk_intr();
    } else if(irq){
      printf("unexpected interrupt irq=%d\n", irq);
    }

    // the PLIC allows each device to raise at most one
    // interrupt at a time; tell the PLIC the device is
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000005L){
    // timer interrupt.
    clockintr();
    return 2;
  } else {
    return 0;
  }
}

