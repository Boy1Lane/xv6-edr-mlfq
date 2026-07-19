// user/bench_interactive.c
// Benchmark: tiến trình tương tác vs CPU-bound trong MLFQ.
// In ra "INTERACTIVE_DONE response_ticks=<số>" — thời gian phản hồi trung bình.

#include "kernel/types.h"
#include "user/user.h"

#define ITERATIONS 10

int main(void) {
  int total = 0;

  for (int i = 0; i < ITERATIONS; i++) {
    int t1 = uptime();
    sleep(2);           // Giả lập I/O wait
    int t2 = uptime();
    total += (t2 - t1);
  }

  printf("INTERACTIVE_DONE response_ticks=%d avg=%d\n",
         total, total / ITERATIONS);
  exit(0);
}
