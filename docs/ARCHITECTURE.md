# 🏛️ Architectural Specification: xv6-edr-mlfq Kernel Subsystems

This document provides a technical overview of the internal architecture, data structures, concurrency model, and control flow of the **xv6-edr-mlfq** operating system kernel.

---

## 1. Multi-Level Feedback Queue (MLFQ) CPU Scheduler

The MLFQ CPU Scheduler is implemented in `kernel/proc.c` and integrated into the timer interrupt handler in `kernel/trap.c`.

### Queue Configuration & Time Quanta
* **Priority Queue 0 (`MLFQ_K0`)**: High Priority. Quantum = `1 tick`. Target for interactive workloads.
* **Priority Queue 1 (`MLFQ_K1`)**: Medium Priority. Quantum = `2 ticks`.
* **Priority Queue 2 (`MLFQ_K2`)**: Low Priority. Quantum = `8 ticks`. Executes Round-Robin scheduling.

### Mathematical Formulations & Anti-Gaming Logic
* **Tick Accumulation**: `p->ticks_spent` accumulates CPU ticks consumed in the current priority level.
* **Priority Demotion**: When `p->ticks_spent >= Quantum[p->priority]`, the process is demoted (`p->priority = min(p->priority + 1, 2)`) and `p->ticks_spent` is reset to 0.
* **Aging & Anti-Starvation**: Every `STARVATION_THRESHOLD` ticks (e.g., 100 ticks), all ready processes are promoted to Queue 0 (`p->priority = 0`) to avoid starvation.

---

## 2. Endpoint Detection and Response (EDR) Security Subsystem

The EDR Subsystem resides in `kernel/edr.c` and provides real-time security monitoring, telemetry buffer management, and automated process quarantine.

### Data Structures & Memory Layout

```c
// Ring Buffer Telemetry Structure
struct edr_alert_buffer {
  struct edr_alert alerts[EDR_BUFFER_SIZE];
  int head;
  int tail;
  int count;
  struct spinlock alert_lock;
};
```

### Process Tree Traversal & Quarantine Propagation
* **Tree Volume Verification**: `count_live_descendants(struct proc *p)` recursively calculates the size of the process tree anchored at `p`.
* **Quarantine Enforcement**: When a process tree exceeds `MAX_FORK_LIMIT` or `TREE_VOLUME_LIMIT`, `propagate_sandbox(struct proc *p)` marks `p->is_sandboxed = 1` across all child descendants.
* **Syscall Blockage**: Sandboxed processes attempting sensitive operations (`fork`, `exec`, `sbrk`) are blocked or killed before causing resource exhaustion.

---

## 3. Concurrency & Locking Hierarchy

To guarantee deadlock-free execution, locks must be acquired in strict order:

1. `wait_lock`: Protects parent-child process relationships.
2. `p->lock`: Protects individual process state (`RUNNABLE`, `SLEEPING`, etc.).
3. `alert_lock`: Protects the EDR ring buffer.

> ⚠️ **Rule**: Never acquire `wait_lock` while holding `alert_lock` or an individual `p->lock`.
