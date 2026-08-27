# 🏛️ Architectural Specification: xv6-edr-mlfq Kernel Subsystems

This document provides a technical overview of the internal architecture, data structures, concurrency model, and control flow of the **xv6-edr-mlfq** operating system kernel.

---

## 1. Multi-Level Feedback Queue (MLFQ) CPU Schedule

The MLFQ CPU Scheduler is implemented in `kernel/proc.c` and integrated into the timer interrupt handler in `kernel/trap.c`.

### Queue Configuration & Time Quanta
* **Priority Queue 0 (`MLFQ_K0`)**: High Priority. Quantum = `1 tick`. Target for interactive workloads.
* **Priority Queue 1 (`MLFQ_K1`)**: Medium Priority. Quantum = `4 ticks`.
* **Priority Queue 2 (`MLFQ_K2`)**: Low Priority. Quantum = `8 ticks`. Executes Round-Robin scheduling.

### Mathematical Formulations & Anti-Gaming Logic
* **Tick Accumulation**: `p->ticks_used` accumulates CPU ticks consumed in the current priority slice; `p->cumulative_run_time` tracks total actual runtime in the current queue level to prevent early yield exploitation (Anti-Gaming).
* **Priority Demotion**: When `p->ticks_used >= Quantum[p->priority]` or `p->cumulative_run_time >= Quantum[p->priority]`, the process is demoted (`p->priority = min(p->priority + 1, 2)`) and both counters (`p->ticks_used = 0`, `p->cumulative_run_time = 0`) are reset (`kernel/trap.c:97`).
* **Aging & Anti-Starvation**: Every `AGING_INTERVAL` ticks (100 ticks per `kernel/param.h:19`), all ready processes are promoted to Queue 0 (`p->priority = 0`) to avoid starvation.

---

## 2. Endpoint Detection and Response (EDR) Security Subsystem

The EDR Subsystem resides in `kernel/edr.c` and provides real-time security monitoring, telemetry buffer management, and automated process quarantine.

### Data Structures & Memory Layout

```c
// Ring Buffer Telemetry Structure (kernel/proc.c & kernel/types.h)
struct alert_entry alerts[EDR_MAX_ALERTS]; // EDR_MAX_ALERTS = 32 (kernel/param.h:25)
struct spinlock alert_lock;
int alert_head;
int alert_tail;
int alerts_dropped;
```

Alerts are consumed by `edr_daemon` through `sys_get_security_alerts(buf, max)`,
which **drains up to `max` entries per call** into user memory and resets the
`alerts_dropped` overflow counter (exported via `p_info` for `ps_monitor`).

### Binary Identity: SHA-256 Whitelist (L1 mitigation)

`scripts/gen-whitelist.sh` runs at build time and emits `kernel/whitelist.h`
containing the SHA-256 hashes of the whitelisted binaries (`init`, `sh`,
`usertests`, `forktest`) plus the trusted daemon (`edr_daemon`). At exec-time
`kexec()` hashes the whole executable (`hash_inode()`, one page at a time,
fail-closed) and matches it against this table. Privileges therefore attach to
binary **content**, not file paths.

### Adaptive Fork-Rate Window (L4 mitigation)

A system-wide exponential moving average of forks-per-window
(`edr_fork_ema_x100`, updated on window rollover in `clockintr`) widens the
per-process detection window:

```
window = EDR_FORK_RATE_WINDOW_TICKS
       + min(EDR_WINDOW_MAX_BONUS, ema * EDR_WINDOW_PER_BUSY)
```

Busy-but-legitimate workloads (e.g. `usertests`) widen the window and avoid
false positives; an idle system keeps the strict 10-tick baseline.

### Global PID-Pressure Limiter (P2 – Distributed Evasion)

Even with per-process and per-tree detectors, a *distributed* bomb can stay
under both thresholds by spreading forks across many parents. P2 adds a
system-wide limiter: `count_live_processes()` (SMP-safe) is checked in
`sys_fork()`. When live count ≥ `EDR_GLOBAL_PRESSURE_THRESHOLD 48 / CRITICAL 56 (NPROC=64)` (`kernel/param.h:39-40`),
new forks from non-whitelisted, non-trusted processes are denied (returns `-1`) with
`EDR_REASON_GLOBAL_PRESSURE` and set `is_sandboxed = 1 (WARN (1), không deschedule, alert 1 lần)` (`kernel/sysproc.c:66-76`)
để `user/pressure.c:9-14` vẫn runnable và in `GLOBAL_PRESSURE_LIMITED`. Ngược lại, Tier-1 và Tier-2 đặt `is_sandboxed = 2 (QUARANTINED (2))` và deschedule tiến trình.
The threshold is below the proc-table ceiling, preserving slots for the daemon and shell.

### Quarantine Lifecycle

1. **Detect**: Tier-1 fork-rate (WARN flag + deferred work request), Tier-2
   tree volume ≥ `EDR_TREE_VOLUME_THRESHOLD`, or **Tier-3 global pressure**
   (`count_live_processes()`).
2. **Contain**: deferred work in `scheduler()` marks the root tree
   `is_sandboxed = 2 (QUARANTINED (2))`; quarantined processes are never scheduled again and
   their `fork`/`exec`/`sbrk` syscalls return `-1`.
3. **Report**: alerts are pushed to the ring buffer; `edr_daemon` drains them,
   **appends them to the persistent `/edr.log` (O_APPEND)**, and kills the victims.
4. **Release**:
    * Administrative: `sys_unquarantine(pid)` — daemon-only, releases the whole
      subtree and re-queues it at the highest MLFQ level.
    * Last resort: `edr_quarantine_timeout_sweep()` force-kills processes left
      in quarantine beyond `EDR_QUARANTINE_TIMEOUT_TICKS` (daemon died).

### Persistent Alert Log (P2)

Every alert drained by `edr_daemon` is appended to `EDR_LOG_PATH` (`/edr.log`)
via the new `O_APPEND` file flag (kernel `sys_open` sets `f->off = ip->size`).
The file survives daemon restarts and reboots until `fs.img` is rebuilt,
enabling post-mortem forensics with `cat /edr.log` or `edr_log`. Rotation is
triggered when `st.size > EDR_LOG_MAX` (truncate).

### Signed Whitelist (P2 – Integrity Beyond Build Time)

`kernel/whitelist.h` is now **signed**: `gen-whitelist.sh` emits `wl_signature`
as `SHA256(SECRET + hex(hashes))` where `SECRET` is a build-time signing key.
At boot `main()` calls `whitelist_verify()` which recomputes the digest with
`sha256_*` and panics on mismatch, proving the whitelist was not tampered
post-build. In production the secret would be a CI private key; here it
demonstrates the chain `build-time sign -> kernel verify`.

### Process Tree Traversal & Quarantine Propagation
* **Tree Volume Verification**: `count_live_descendants(struct proc *p)` recursively calculates the size of the process tree anchored at `p`.
* **Quarantine Enforcement**: When a process tree exceeds `EDR_TREE_VOLUME_THRESHOLD` (16 per `kernel/param.h:24`), `propagate_sandbox(struct proc *p)` marks `p->is_sandboxed = 2 (QUARANTINED)` across all child descendants (`kernel/edr.c:184`).
* **Syscall Blockage**: Sandboxed processes attempting sensitive operations (`fork`, `exec`, `sbrk`) are blocked or killed before causing resource exhaustion.

---

## 3. Concurrency & Locking Hierarchy

To guarantee deadlock-free execution, locks must be acquired in strict order:

1. `wait_lock`: Protects parent-child process relationships.
2. `p->lock`: Protects individual process state (`RUNNABLE`, `SLEEPING`, etc.).
3. `alert_lock`: Protects the EDR ring buffer.

> ⚠️ **Rule**: Never acquire `wait_lock` while holding `alert_lock` or an individual `p->lock`.

### SMP-Safe Hot Paths (P2)

Former single-hart fast paths are now SMP-safe (verified with `-smp 3`):

* `clockintr()` (kernel/trap.c): snapshots `ticks` via `tickslock`/`__atomic_load_n`,
  checks `fork_times` under `p->lock`, and only CPU 0 performs the EMA window
  rollover (CAS on `edr_last_window`) and the quarantine sweep.
* `mlfq_tick()` (kernel/trap.c): snapshots `ticks` under `tickslock`; all
  `p->priority`/`ticks_used`/`cumulative_run_time` updates hold `p->lock`;
  `has_higher_priority()` now acquires `p->lock` per entry; global `ticks`
  aging check uses the snapped `cur_ticks`.
* EMA globals (`edr_forks_in_window`, `edr_fork_ema_x100`) are updated with
  `edr_global_lock` + `__atomic_*` primitives.

The default build now runs `-smp 3`.
