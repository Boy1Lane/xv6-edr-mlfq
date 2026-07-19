# xv6-MLFQ: Hệ điều hành xv6 tích hợp Bộ lập lịch MLFQ & Hệ thống an ninh Mini-EDR

Dự án này là phiên bản cải tiến của hệ điều hành học thuật **MIT xv6-riscv** (kiến trúc RISC-V). Hệ thống được nâng cấp toàn diện bằng cách thay thế bộ lập lịch Round Robin nguyên bản bằng **Bộ lập lịch đa cấp phản hồi (MLFQ - Multi-Level Feedback Queue)** tích hợp các cơ chế chống gian lận (Anti-Gaming) và chống nghẽn (Aging). Song song với đó, hệ thống tích hợp giải pháp an ninh **Mini-EDR (Endpoint Detection and Response)** nằm trực tiếp ở nhân (Kernel space) nhằm phát hiện và cô lập các mối đe dọa cạn kiệt tài nguyên (như Fork Bomb) theo thời gian thực.

---

## 🚀 Các Tính Năng Cốt Lõi

### 1. Bộ lập lịch đa cấp phản hồi (MLFQ Scheduler)
Bộ lập lịch được thiết kế với **3 hàng đợi độ ưu tiên** (Priority levels từ 0 đến 2):
*   **Hàng đợi 0 (Cao nhất)**: Sử dụng Time Slice (Quantum) = `1 tick`. Ưu tiên cho các tiến trình tương tác nhanh, tác vụ ngắn hoặc I/O.
*   **Hàng đợi 1 (Trung bình)**: Sử dụng Time Slice (Quantum) = `4 ticks`.
*   **Hàng đợi 2 (Thấp nhất)**: Sử dụng Time Slice (Quantum) = `8 ticks`. Dành cho các tiến trình nặng tính toán (CPU-bound).
*   **Cơ chế chống nghẽn (Aging)**: Cứ sau mỗi `100 ticks` (`AGING_INTERVAL`), hệ thống tự động thúc đẩy toàn bộ tiến trình đang hoạt động về Hàng đợi 0 (`promote_all()`) để tránh tình trạng các tiến trình cấp thấp bị bỏ đói CPU (Starvation).
*   **Cơ chế chống gian lận (Anti-Gaming)**: Theo dõi thời gian chạy tích lũy của tiến trình (`cumulative_run_time`). Nếu tiến trình cố tình thực hiện cuộc gọi `sleep()` ngắn trước khi hết quantum nhằm tránh bị hạ cấp, bộ lập lịch sẽ không reset `cumulative_run_time`. Khi tổng thời gian chạy thực tế đạt ngưỡng quantum, tiến trình vẫn bị hạ cấp bình thường.

### 2. Hệ thống giám sát và phản ứng Mini-EDR (Endpoint Detection & Response)
Mini-EDR hoạt động theo mô hình phát hiện hai lớp (Tiered Detection) kết hợp cô lập luồng thực thi:
*   **Tier-1: Bộ phát hiện tần suất sinh tiến trình (Rate-based Detector)**
    *   Mỗi PCB (`struct proc`) được trang bị một Ring Buffer `fork_times` kích thước `6` để ghi nhận thời điểm gọi `fork()`.
    *   Được kiểm tra tại cuộc gọi `sys_fork()` và ngắt đồng hồ (`clockintr`).
    *   Nếu phát hiện tiến trình thực hiện `6` lần fork trong vòng `10 ticks` (~1 giây), tiến trình sẽ bị đánh dấu cảnh báo `is_sandboxed = 1` (WARN) và kích hoạt cờ lan truyền an ninh.
*   **Tier-2: Bộ phát hiện quy mô cây tiến trình (Volume-based Detector)**
    *   Thực hiện bất đồng bộ tại luồng lập lịch (`scheduler`) thông qua pha **EDR Deferred Work** được bảo vệ bằng khóa nguyên tử `edr_lock`.
    *   Duyệt ngược cây phân cấp để đếm số lượng tiến trình con cháu còn sống (`count_live_descendants()`).
    *   Nếu tổng số tiến trình con cháu $\ge 16$ (`EDR_TREE_VOLUME_THRESHOLD`), tiến trình gốc và toàn bộ nhánh cây con của nó sẽ bị chuyển trạng thái cách ly `is_sandboxed = 2` (QUARANTINED).
*   **Cơ chế cô lập (Quarantine Enforcement)**
    *   Bộ lập lịch nhân kiểm tra trạng thái `is_sandboxed == 2`. Nếu đúng, tiến trình bị tước hoàn toàn CPU (không được chạy), đóng băng mọi hành vi phá hoại.
*   **Tác nhân phản ứng (EDR Daemon)**
    *   Một chương trình chạy ngầm tin cậy ở không gian người dùng (`/edr_daemon`) liên tục gọi syscall `get_security_alerts` để nhận thông tin cảnh báo từ Ring Buffer `alerts` trong nhân.
    *   Khi có cảnh báo cách ly tiến trình độc hại, Daemon sẽ hiển thị log đỏ ra màn hình và gửi tín hiệu `kill(PID)` để giải phóng tài nguyên hệ thống một cách an toàn.

### 3. Tăng cường bảo mật nhân (Kernel Hardening)
*   **Xác thực không gian địa chỉ ảo (User Pointer Validation)**: Hàm giải mã đối số con trỏ `argaddr()` được hook cơ chế duyệt bảng trang SV39 bằng `walkaddr`. Nếu địa chỉ ảo truyền từ user space chưa được ánh xạ vật lý hợp lệ, nhân lập tức từ chối thực thi để ngăn chặn các lỗi khai thác lỗi bộ nhớ gây sập nhân (Kernel Panic).
*   **Chứng thực nguồn gốc (Exec Authentication)**: Khi chạy chương trình thông qua `exec()`, nhân kiểm tra đường dẫn thực thi. Chỉ có chương trình `/edr_daemon` mới được cấp quyền đặc nhiệm `edr_trusted = 1` để gọi syscall an ninh. Các tiến trình hệ thống thiết yếu (`init`, `sh`, `usertests`) được gắn cờ `is_whitelisted = 1` để không bao giờ bị cách ly nhầm.

---

## 📊 Sơ đồ Kiến trúc Hệ thống

```
+-------------------------------------------------------------+
|                     KHÔNG GIAN NGƯỜI DÙNG                   |
|                                                             |
|  +--------------------+             +--------------------+  |
|  | Tiền trình thường  |             |     edr_daemon     |  |
|  |  hoặc Độc hại      |             |  (edr_trusted = 1) |  |
|  +---------┬----------+             +---------▲----------+  |
|            │ (syscall/trap)                   │             |
+────────────┼──────────────────────────────────┼─────────────+
|            ▼ (ecall)                          │             |
|  +--------------------+                       │             |
|  |   usertrap() /     |                       │             |
|  |   syscall()        |                       │             |
|  +---------┬----------+                       │             |
|            │                                  │             |
|            ▼                                  │             |
|  +--------------------+                       │             |
|  |     Syscalls       |                       │             |
|  | (fork, exec, open) |                       │             |
|  +────┬───────────┬───+                       │             |
|       │           │                           │             |
|       │ (sys_fork)│ (Xác thực đường dẫn)      │             |
|       ▼           ▼                           │             |
|  +────────────────────────────────+           │             |
|  |  Tier-1 Rate-based Detector    |           │             |
|  |  - Lưu trữ ticks gọi fork      |           │             |
|  |  - Gán nhãn is_sandboxed = 1   |           │             |
|  +────────────────────────────────+           │             |
|                                               │             |
|  +────────────────────────────────+           │             |
|  |  Tier-2 Volume-based Detector  |           │             |
|  |  - Đếm quy mô con cháu         |           │             |
|  |  - Cách ly hàng loạt (Cấp 2)   |           │             |
|  +────────────────┬───────────────+           │             |
|                   │                           │             |
|                   ▼ (Đưa cảnh báo vào)        │ (Lấy cảnh báo)
|  +────────────────────────────────+           │             |
|  |   Mảng vòng cảnh báo nhân      |───────────┼─────────────┘
|  |      (alerts / alert_lock)     |           │ get_security_alerts()
|  +────────────────────────────────+           │
|                                               │
|  +────────────────────────────────+           │
|  |      Luồng Lập lịch            |◄──────────┘
|  |  - Kiểm tra hàng đợi MLFQ      | (Gửi lệnh kill)
|  |  - Chặn tiến trình Quarantine  |
|  +────────────────────────────────+
|                                                             |
|                       KHÔNG GIAN NHÂN                       |
+-------------------------------------------------------------+
```

---

## 📂 Tổ chức Mã nguồn dự án

### Các tệp nhân bị thay đổi (Kernel space):
*   [`kernel/proc.h`](file:///c:/Users/Admin/OneDrive%20-%20VNU-HCMUS/Documents/xv6-MLFQ/xv6-riscv-MLFQ/kernel/proc.h): Bổ sung siêu dữ liệu EDR và thuộc tính phân cấp MLFQ vào cấu trúc tiến trình `proc`.
*   [`kernel/proc.c`](file:///c:/Users/Admin/OneDrive%20-%20VNU-HCMUS/Documents/xv6-MLFQ/xv6-riscv-MLFQ/kernel/proc.c): Triển khai thuật toán lập lịch MLFQ, cơ chế Aging, EDR Deferred Work duyệt cây con và cách ly tiến trình.
*   [`kernel/trap.c`](file:///c:/Users/Admin/OneDrive%20-%20VNU-HCMUS/Documents/xv6-MLFQ/xv6-riscv-MLFQ/kernel/trap.c): Tích hợp kiểm tra thời gian thực Tier-1 trong clock interrupt, thực hiện cập nhật ticks lập lịch và xử lý chuyển cấp hàng đợi.
*   [`kernel/exec.c`](file:///c:/Users/Admin/OneDrive%20-%20VNU-HCMUS/Documents/xv6-MLFQ/xv6-riscv-MLFQ/kernel/exec.c): Thực hiện gán whitelist và phân quyền daemon dựa trên đường dẫn nạp tệp ELF.
*   [`kernel/sysproc.c`](file:///c:/Users/Admin/OneDrive%20-%20VNU-HCMUS/Documents/xv6-MLFQ/xv6-riscv-MLFQ/kernel/sysproc.c): Cài đặt syscall an ninh `get_security_alerts` và syscall đo lường `proc_info`, đồng thời ghi nhận vết fork trong `sys_fork`.
*   [`kernel/syscall.c`](file:///c:/Users/Admin/OneDrive%20-%20VNU-HCMUS/Documents/xv6-MLFQ/xv6-riscv-MLFQ/kernel/syscall.c): Hook hàm `argaddr` để kiểm tra ánh xạ địa chỉ bộ nhớ ảo.

### Các tệp tiện ích được thêm mới (User space):
*   [`user/edr_daemon.c`](file:///c:/Users/Admin/OneDrive%20-%20VNU-HCMUS/Documents/xv6-MLFQ/xv6-riscv-MLFQ/user/edr_daemon.c): Tác nhân an ninh giám sát cảnh báo và loại bỏ tiến trình bị cách ly.
*   [`user/ps_monitor.c`](file:///c:/Users/Admin/OneDrive%20-%20VNU-HCMUS/Documents/xv6-MLFQ/xv6-riscv-MLFQ/user/ps_monitor.c): Công cụ kết xuất dữ liệu bộ lập lịch MLFQ ra màn hình theo thời gian thực.
*   [`user/cpuload.c`](file:///c:/Users/Admin/OneDrive%20-%20VNU-HCMUS/Documents/xv6-MLFQ/xv6-riscv-MLFQ/user/cpuload.c): Tiến trình mô phỏng tải CPU để kiểm tra việc hạ cấp độ ưu tiên lập lịch.
*   [`user/multitest.c`](file:///c:/Users/Admin/OneDrive%20-%20VNU-HCMUS/Documents/xv6-MLFQ/xv6-riscv-MLFQ/user/multitest.c): Tiến trình mô phỏng tấn công Fork bomb bằng cách tạo ra cây tiến trình lớn vượt ngưỡng.

---

## 🛠️ Hướng dẫn Biên dịch và Chạy thử nghiệm

### 1. Chuẩn bị môi trường
Bạn cần cài đặt bộ công cụ biên dịch chéo RISC-V GNU Toolchain và trình giả lập QEMU kiến trúc RISC-V 64-bit:
```bash
# Trên các hệ điều hành Ubuntu/Debian
sudo apt-get install git build-essential gdb-multiarch qemu-system-misc gcc-riscv64-linux-gnu binutils-riscv64-linux-gnu
```

### 2. Biên dịch hệ thống
Di chuyển vào thư mục dự án chứa mã nguồn và thực hiện lệnh biên dịch:
```bash
cd xv6-riscv-MLFQ
make qemu
```

### 3. Chạy các kịch bản thử nghiệm

#### Kịch bản A: Thử nghiệm Lập lịch MLFQ & Anti-Gaming
1.  Bật công cụ giám sát tiến trình ở một cửa sổ dòng lệnh:
    ```bash
    $ ps_monitor &
    ```
    Màn hình sẽ in danh sách các tiến trình cùng `Priority` (Độ ưu tiên: 0, 1, 2) và `Ticks` (Ticks đã dùng).
2.  Chạy chương trình đốt cháy CPU:
    ```bash
    $ cpuload
    ```
    Quan sát trên `ps_monitor` sẽ thấy tiến trình `cpuload` ban đầu ở mức độ ưu tiên 0, sau khi chiếm dụng CPU liên tục sẽ nhanh chóng bị nhân hạ xuống độ ưu tiên 1 rồi đến độ ưu tiên 2.

#### Kịch bản B: Thử nghiệm EDR phát hiện tấn công Fork Bomb
1.  Khởi động EDR Daemon chạy ngầm trong hệ thống:
    ```bash
    $ edr_daemon &
    ```
2.  Kích hoạt kịch bản tạo tải nhân bản lớn:
    ```bash
    $ multitest
    ```
    *   Hành vi: `multitest` sẽ sinh ra 3 worker, mỗi worker thực hiện sinh nhanh 20 tiến trình con.
    *   Phát hiện: Nhân lập tức bắt được tần suất vượt ngưỡng (Tier-1) và quy mô cây tiến trình vượt quá 16 (Tier-2). Nhân sẽ cô lập toàn bộ cây tiến trình này.
    *   Phản ứng: `edr_daemon` nhận được cảnh báo, in thông điệp lỗi màu đỏ `[EDR ALERT] PID ... quarantined!` và gửi tín hiệu `kill` giải phóng sạch sẽ các tiến trình vi phạm. Hệ thống hoạt động bình thường, không bị treo đơ.

---

## 🎓 Giá trị Học thuật và Đóng góp
Dự án này phục vụ nghiên cứu và giảng dạy thực hành hệ điều hành tại các trường đại học, minh họa chi tiết các khái niệm:
1.  **Lập lịch nâng cao**: Chuyển đổi ngữ cảnh (context switching), Time-slice quản lý theo ngắt, tiền chiếm dụng và cơ chế trừng phạt tiến trình ngốn CPU.
2.  **Lập trình Kernel an toàn**: Cách kiểm tra biên vùng nhớ chế độ người dùng bằng ánh xạ trang, đồng bộ hóa an toàn đa nhân thông qua lệnh nguyên tử phần cứng.
3.  **Hệ thống giám sát động**: Cách thức xây dựng Endpoint Protection hoạt động đồng thời tại tầng nhân (Phát hiện & Cô lập) và tầng người dùng (Phản ứng & Xử lý).
