#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main() {
  int i = 0;
  printf("CPULOAD: Dang chay vong lap vo han de chiem CPU...\n");
  
  // Vòng lặp vô tận thực hiện tính toán để đốt cháy CPU
  // Mục tiêu: Dùng hết Quantum để bị hạ Priority
  while(1) {
    i++;
    if (i == 100000000) { // Reset để tránh tràn số, không quan trọng
        i = 0; 
    }
  }
  exit(0);
}