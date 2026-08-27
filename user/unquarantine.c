#include "kernel/types.h"
#include "user/user.h"

// Administrative release of a quarantined process tree. Only succeeds when
// called by a process the kernel authenticated as the EDR daemon (SHA-256).
int main(int argc, char *argv[]) {
  if (argc != 2) {
    fprintf(2, "usage: unquarantine <pid>\n");
    exit(1);
  }

  int pid = atoi(argv[1]);
  if (unquarantine(pid) == 0) {
    printf("unquarantine: pid %d released\n", pid);
    exit(0);
  }
  // -1: caller không phải EDR daemon hoặc pid không tồn tại
  printf("unquarantine: pid %d denied or not found\n", pid);
  exit(1);
}
