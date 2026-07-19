// init: The initial user-level program

#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/spinlock.h"
#include "kernel/sleeplock.h"
#include "kernel/fs.h"
#include "kernel/file.h"
#include "user/user.h"
#include "kernel/fcntl.h"

char *argv[] = { "sh", 0 };

int
main(void)
{
  int wpid;

  if(open("console", O_RDWR) < 0){
    mknod("console", CONSOLE, 0);
    open("console", O_RDWR);
  }
  dup(0);  // stdout
  dup(0);  // stderr

  int sh_pid = -1;
  int edr_pid = -1;
  char *edr_argv[] = { "edr_daemon", 0 };

  for(;;){
    if (edr_pid < 0) {
      edr_pid = fork();
      if (edr_pid < 0) {
        printf("init: fork edr_daemon failed\n");
      } else if (edr_pid == 0) {
        exec("/edr_daemon", edr_argv);
        printf("init: exec edr_daemon failed\n");
        exit(1);
      }
    }

    if (sh_pid < 0) {
      printf("init: starting sh\n");
      sh_pid = fork();
      if(sh_pid < 0){
        printf("init: fork sh failed\n");
        exit(1);
      }
      if(sh_pid == 0){
        exec("sh", argv);
        printf("init: exec sh failed\n");
        exit(1);
      }
    }

    wpid = wait((int *) 0);
    if(wpid == sh_pid){
      sh_pid = -1;
    } else if(wpid == edr_pid){
      edr_pid = -1;
    } else if(wpid < 0){
      printf("init: wait returned an error\n");
      exit(1);
    } else {
      // parentless process exited, do nothing
    }
  }
}
