#define NPROC        64  // maximum number of processes
#define NCPU          8  // maximum number of CPUs
#define NOFILE       16  // open files per process
#define NFILE       100  // open files per system
#define NINODE       50  // maximum number of active i-nodes
#define NDEV         10  // maximum major device number
#define ROOTDEV       1  // device number of file system root disk
#define MAXARG       32  // max exec arguments
#define MAXOPBLOCKS  10  // max # of blocks any FS op writes
#define LOGBLOCKS    (MAXOPBLOCKS*3)  // max data blocks in on-disk log
#define NBUF         (MAXOPBLOCKS*3)  // size of disk block cache
#define FSSIZE       2000  // size of file system in blocks
#define MAXPATH      128   // maximum file path name
#define USERSTACK    1     // user stack pages
#define MLFQ_LEVELS  3    
#define QUANTUM_0 1
#define QUANTUM_1 4
#define QUANTUM_2 8
#define AGING_INTERVAL 100

// EDR Configuration Constants
#define EDR_FORK_SAMPLE 6
#define EDR_FORK_RATE_WINDOW_TICKS 10
#define EDR_TREE_VOLUME_THRESHOLD 16
#define EDR_MAX_ALERTS 32

// Adaptive threshold (mitigates DESIGN.md L4): the per-process fork-rate
// detection window widens with observed system-wide fork activity.
// ema = exponential moving average of forks-per-window (x100 fixed point).
#define EDR_EMA_ALPHA_PCT 25        // smoothing factor for the EMA (%)
#define EDR_WINDOW_PER_BUSY 2       // bonus ticks added per avg fork/window
#define EDR_WINDOW_MAX_BONUS 40     // upper bound on the widening

// Last-resort release: a process quarantined this long without the daemon
// acting on it is force-killed so it cannot hold resources forever (L3).
#define EDR_QUARANTINE_TIMEOUT_TICKS 120

// P2: Global PID-pressure limiter – distributed fork-bomb evasion
#define EDR_GLOBAL_PRESSURE_THRESHOLD 48  // 75% of NPROC
#define EDR_GLOBAL_PRESSURE_CRITICAL  56  // 87% of NPROC

// P2: Persistent log path
#define EDR_LOG_PATH "/edr.log"
#define EDR_LOG_MAX  4096  // max bytes retained in the log file (for demo)

// Scheduler mode: 0 = MLFQ (default), 1 = Round Robin (cho benchmark)
// Bật qua `make qemu-rr` hoặc `make qemu SCHED_MODE=1` (Makefile tự thêm -DSCHED_MODE=1)
#ifndef SCHED_MODE
#define SCHED_MODE 0
#endif
