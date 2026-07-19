// user/bench_rr.c
// Benchmark: đo tổng thời gian hoàn thành N tiến trình CPU-bound.
// Kết quả: in ra "BENCH_DONE total_ticks=<số>"
// Dùng để so sánh MLFQ vs RR overhead.

#include "kernel/types.h"
#include "user/user.h"

#define NUM_WORKERS 4
#define WORK_UNITS  200000  // số vòng lặp mỗi worker

int main(void) {
  int start = uptime();

  for (int i = 0; i < NUM_WORKERS; i++) {
    int pid = fork();
    if (pid == 0) {
      // Worker: vòng lặp CPU-bound thuần túy
      volatile int x = 0;
      for (int j = 0; j < WORK_UNITS; j++) x += j;
      exit(0);
    }
  }

  // Parent: chờ tất cả workers
  for (int i = 0; i < NUM_WORKERS; i++)
    wait(0);

  int end = uptime();
  printf("BENCH_DONE total_ticks=%d\n", end - start);
  exit(0);
}
