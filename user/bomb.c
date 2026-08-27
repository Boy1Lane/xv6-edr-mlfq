#include "kernel/types.h"
#include "kernel/fcntl.h"
#include "user/user.h"

// Controlled fork bomb for the unquarantine test.
// Spawns just enough children (tree > EDR_TREE_VOLUME_THRESHOLD) to trigger
// Tier-2 quarantine while leaving plenty of free proc-table slots for the
// test driver's own commands.
//
// The parent prints BOMB_ALIVE_AFTER_RELEASE only after it gets scheduled
// again - i.e. after the whole tree was administratively released.
int main(void) {
  printf("bomb: spawning tree\n");

  for(int i = 0; i < 20; i++){
    int pid = fork();
    if(pid == 0){
      // Children hang forever unless released or killed by the daemon.
      sleep(1000000);
      exit(0);
    }
    if(pid < 0)
      break;
  }

  // Quarantine deschedules this process; reaching this point proves the
  // unquarantine syscall brought the tree back to life.
  sleep(30);
  // P2: also persist marker to file for SMP-robust verification (console
  // prints can interleave on multi-hart UART). Test checks both.
  int fd = open("bomb_alive", O_CREATE | O_WRONLY);
  if(fd >= 0){
    write(fd, "BOMB_ALIVE_AFTER_RELEASE\n", 25);
    close(fd);
  }
  // small delay to let releasing daemon finish its own console write first
  sleep(5);
  printf("BOMB_ALIVE_AFTER_RELEASE\n");
  exit(0);
}
