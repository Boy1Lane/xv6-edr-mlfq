// Create a zombie process that
// must be reparented at exit.

#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int sleep(int);
#define pause(x) sleep(x)

int
main(void)
{
  if(fork() > 0)
    pause(5);  // Let child exit before parent.
  exit(0);
}
