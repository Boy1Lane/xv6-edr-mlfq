#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/fcntl.h"
#include "kernel/param.h"
#include "user/user.h"

#define ALERT_BATCH 16

// P2: append a single alert to the persistent on-disk log /edr.log
static void persist_alert(struct alert_entry *a) {
  int fd = open(EDR_LOG_PATH, O_CREATE | O_RDWR | O_APPEND);
  if (fd < 0)
    return;
  struct stat st;
  if (fstat(fd, &st) == 0 && st.size > EDR_LOG_MAX) {
    close(fd);
    fd = open(EDR_LOG_PATH, O_CREATE | O_RDWR | O_TRUNC);
    if (fd < 0)
      return;
  }
  fprintf(fd, "%lu quarantined pid=%d ppid=%d reason=%d %s name=%s\n", a->tick, a->pid,
          a->parent_pid, a->reason, a->reason_str, a->name);
  close(fd);
}

int main(int argc, char *argv[]) {
  struct alert_entry batch[ALERT_BATCH];

  // Admin CLI mode: the daemon binary is the only SHA-256-trusted process,
  // so administrative releases must go through it.
  //   edr_daemon release <pid>
  if (argc == 3 && strcmp(argv[1], "release") == 0) {
    int pid = atoi(argv[2]);
    if (unquarantine(pid) == 0) {
      printf("unquarantine: pid %d released\n", pid);
      exit(0);
    }
    printf("unquarantine: pid %d denied or not found\n", pid);
    exit(1);
  }

  printf("edr_daemon: started successfully in background.\n");

  while (1) {
    // Drain toàn bộ cảnh báo tồn đọng mỗi vòng poll để giảm độ trễ cách ly.
    int res = get_security_alerts(batch, ALERT_BATCH);
    if (res < 0) {
      printf("edr_daemon: authentication failed! Exiting.\n");
      exit(1);
    }
    for (int i = 0; i < res; i++) {
      printf("\x1b[31m[EDR ALERT] PID %d (PPID: %d, %s) quarantined! Reason: %s at "
             "tick %lu\x1b[0m\n",
             batch[i].pid, batch[i].parent_pid, batch[i].name, batch[i].reason_str, batch[i].tick);
      persist_alert(&batch[i]);
      kill(batch[i].pid);
    }
    if (res == 0)
      sleep(10);
  }

  exit(0);
}
