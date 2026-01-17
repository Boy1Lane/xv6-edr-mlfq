#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/pstat.h"

int sleep(int);

int main(int argc, char *argv[]) {
    struct p_info info;

    // In header của bảng
    printf("PID\tPriority\tTicks\tState\n");

    while (1) {
        // Gọi System Call lấy dữ liệu
        if (proc_info(&info) < 0) {
            printf("Error: cannot get proc info\n");
            exit(1);
        }

        // Duyệt qua các slot trong bảng tiến trình
        for (int i = 0; i < NPROC; i++) {
            // Chỉ in các tiến trình đang hoạt động (State khác 0)
            if (info.state[i] != 0) { 
                printf("%d\t%d\t\t%d\t%d\n", 
                    info.pid[i], 
                    info.priority[i], 
                    info.ticks_used[i], 
                    info.state[i]
                );
            }
        }
        
        // Ngủ 10 ticks rồi cập nhật lại
        sleep(10); 
    }
    exit(0);
}