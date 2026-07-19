#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
  struct alert_entry alert;
  
  printf("edr_daemon: started successfully in background.\n");

  while (1) {
    int res = get_security_alerts(&alert);
    if (res > 0) {
      int dropped = res - 1;
      if (dropped > 0) {
        printf("\x1b[33m[EDR WARNING] %d alerts dropped due to buffer overflow!\x1b[0m\n", dropped);
      }
      // Print alert in red
      printf("\x1b[31m[EDR ALERT] PID %d (PPID: %d, %s) quarantined! Reason: %s at tick %lu\x1b[0m\n", 
             alert.pid, alert.parent_pid, alert.name, alert.reason_str, alert.tick);
      
      // Kill the quarantined process to let it exit gracefully
      kill(alert.pid);
    } else if (res == 0) {
      // No alerts, wait before polling again
      sleep(10);
    } else {
      // Authentication failed
      printf("edr_daemon: authentication failed! Exiting.\n");
      exit(1);
    }
  }

  exit(0);
}
