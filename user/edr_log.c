#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/fcntl.h"
#include "user/user.h"

char buf[512];

int
main(int argc, char *argv[])
{
  int fd = open("/edr.log", O_RDONLY);
  if(fd < 0){
    printf("edr_log: no persistent log yet (/edr.log not found)\n");
    exit(0);
  }
  printf("=== EDR Persistent Log (/edr.log) ===\n");
  int n;
  while((n = read(fd, buf, sizeof(buf)-1)) > 0){
    buf[n] = 0;
    printf("%s", buf);
  }
  close(fd);
  exit(0);
}
