// user/bench_int.c
// Benchmark: do thoi gian phan hoi trung binh cua tien trinh tuong tac
// (sleep lam gia lap I/O wait) KHI CO background CPU-bound load, de so sanh
// MLFQ (uu tien tuong tac) vs Round Robin (xen kei quantum).
// In ra "INTERACTIVE_DONE response_ticks=<so> avg=<so>".

#include "kernel/types.h"
#include "user/user.h"

#define ITERATIONS 10
#define LOAD_WORKERS 2

static void
load_worker(void)
{
  // Vong lap CPU-bound vo han: dai dien cho tien trinh chiem CPU.
  volatile int x = 0;
  for(;;)
    x++;
}

int main(void) {
  int total = 0;
  int pids[LOAD_WORKERS];

  // Tao contention: cac worker nay canh tranh CPU voi tien trinh do.
  for (int i = 0; i < LOAD_WORKERS; i++) {
    int pid = fork();
    if (pid == 0)
      load_worker();
    pids[i] = pid;
  }

  for (int i = 0; i < ITERATIONS; i++) {
    int t1 = uptime();
    sleep(2);           // Gia lap I/O wait
    int t2 = uptime();
    total += (t2 - t1);
  }

  // Don dep loaders de moi lan chay doc lap voi nhau.
  for (int i = 0; i < LOAD_WORKERS; i++)
    if (pids[i] > 0)
      kill(pids[i]);

  printf("INTERACTIVE_DONE response_ticks=%d avg=%d\n",
         total, total / ITERATIONS);
  exit(0);
}
