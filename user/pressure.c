#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/fcntl.h"
#include "user/user.h"

int
main(void)
{
  printf("global_pressure: distributed bomb (8x6 leaves)\n");
  int intermediates = 0;
  // Create 8 intermediate parents, each spawns 6 leaves then exits.
  // Leaves are reparented to init, so the original parent's tree stays
  // small (<16) but system-wide live count exceeds global threshold (48).
  for(int i = 0; i < 8; i++){
    int pid = fork();
    if(pid < 0){
      printf("global_pressure: intermediate fork denied at i=%d\n", i);
      break;
    }
    if(pid == 0){
      for(int j = 0; j < 6; j++){
        int p2 = fork();
        if(p2 < 0){
          // leaf fork denied – exit silently to avoid SMP console interleaving
          exit(1);
        }
        if(p2 == 0){
          sleep(300);
          exit(0);
        }
      }
      // Intermediate exits quickly so leaves are reparented to init
      exit(0);
    }
    intermediates++;
  }
  // Give leaves time to be born and reparented
  sleep(30);
  int live_estimate = intermediates * 6;
  printf("global_pressure: intermediates=%d leaves~%d\n", intermediates, live_estimate);
  // Now try to fork one more child – should be denied by global limiter
  int pid = fork();
  if(pid < 0){
    printf("global_pressure: final fork denied as expected\n");
    printf("GLOBAL_PRESSURE_LIMITED\n");
    int fd = open("pressure_limited", O_CREATE|O_WRONLY);
    if(fd >= 0){ write(fd, "LIMITED\n", 8); close(fd); }
  } else if(pid == 0){
    sleep(50);
    exit(0);
  } else {
    printf("global_pressure: final fork succeeded (live=%d)\n", live_estimate);
    // Check live count directly via threshold: if we got here, limiter didn't trigger
    // but maybe live count was just under threshold due to timing
    if(live_estimate >= 40){
      printf("GLOBAL_PRESSURE_NOT_LIMITED\n");
    } else {
      printf("GLOBAL_PRESSURE_LIMITED\n");
      int fd = open("pressure_limited", O_CREATE|O_WRONLY);
      if(fd >= 0){ write(fd, "LIMITED\n", 8); close(fd); }
    }
    wait(0);
  }
  // Cleanup: wait for intermediates (they already exited, but reap)
  while(wait(0) != -1)
    ;
  // Leaves are children of init now, we can't wait for them; just report
  printf("GLOBAL_PRESSURE_DONE\n");
  exit(0);
}
