#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/pstat.h"

int sleep(int);

int main(int argc, char *argv[]) {
    struct p_info info;

    // Tên trạng thái để dễ đọc hơn
    static const char *state_names[] = {
        "UNUSED", "USED", "SLEEP", "RUN", "RUNNING", "ZOMBIE"
    };

    // In header của bảng
    printf("PID\tQ\tTICKS\tTOTAL\tSTATE\t STATUS\n");
    printf("---\t-\t-----\t-----\t-----\t ------\n");

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
                const char *state_str = (info.state[i] < 6) ? state_names[info.state[i]] : "?";
                
                if (info.is_sandboxed[i] > 0) {
                    // Tiến trình bị sandbox: in màu đỏ + cờ [QUARANTINE]
                    printf("\x1b[31m%d\t%d\t%d\t%d\t%s\t[QUARANTINE]\x1b[0m\n",
                        info.pid[i], info.priority[i],
                        info.ticks_used[i], info.total_runtime[i],
                        state_str);
                } else {
                    printf("%d\t%d\t%d\t%d\t%s\n",
                        info.pid[i], info.priority[i],
                        info.ticks_used[i], info.total_runtime[i],
                        state_str);
                }
            }
        }
        
        // Ngủ 10 ticks rồi cập nhật lại
        sleep(10); 
    }
    exit(0);
}