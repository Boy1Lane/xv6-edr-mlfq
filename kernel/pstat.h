#ifndef _PSTAT_H_
#define _PSTAT_H_

#include "param.h" // Để lấy NPROC

struct p_info {
  int pid[NPROC];
  int priority[NPROC];
  int ticks_used[NPROC];
  int state[NPROC]; // 0: UNUSED, 1: USED, 2: SLEEPING, 3: RUNNABLE, 4: RUNNING, 5: ZOMBIE
  int total_runtime[NPROC];
  uint8 is_sandboxed[NPROC];
};

#endif