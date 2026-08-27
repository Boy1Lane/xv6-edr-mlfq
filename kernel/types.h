typedef unsigned int   uint;
typedef unsigned short ushort;
typedef unsigned char  uchar;

typedef unsigned char uint8;
typedef unsigned short uint16;
typedef unsigned int  uint32;
typedef unsigned long uint64;

typedef uint64 pde_t;

struct alert_entry {
  int pid;
  int parent_pid;
  uint8 reason;
  char reason_str[32];
  uint64 tick;
  char name[16];
};
