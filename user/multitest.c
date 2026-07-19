#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

void worker() {
  // Spawns multiple children very fast
  for(int i = 0; i < 20; i++){
    int pid = fork();
    if(pid == 0){
      // Child
      sleep(10); 
      exit(0);
    }
  }
  // Wait for all children
  while(wait(0) != -1);
  exit(0);
}

int main(int argc, char *argv[])
{
  printf("multitest: spawning workers...\n");
  for(int i = 0; i < 3; i++) {
    int pid = fork();
    if(pid == 0) {
      worker();
    }
  }
  
  // Wait for all
  while(wait(0) != -1);
  printf("multitest: done.\n");
  exit(0);
}
