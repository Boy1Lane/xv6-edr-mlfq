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
#define EDR_DAEMON_PATH "/edr_daemon"
