\# ĐỀ XUẤT DỰ ÁN: KERNEL-LEVEL MINI-EDR SYSTEM FOR RISC-V (xv6)



\*\*Phiên bản:\*\* 5.0 — Bản hoàn thiện sau phản biện về concurrency và tương thích hệ thống tệp



\*\*Tác giả:\*\* Phan Hoàng Quốc Huy  

\*\*Mã số sinh viên:\*\* 23120048  

\*\*Đơn vị:\*\* Trường Đại học Khoa học Tự nhiên — ĐHQG-HCM (HCMUS)



\---



> ### Những cập nhật chính so với phiên bản v4

> 1. \*\*Sửa lỗi logic concurrency nghiêm trọng:\*\* tách biến \*\*tín hiệu\*\* (`edr\_work\_pending`) và \*\*khóa\*\* (`edr\_lock`). Đảm bảo chỉ khi thực sự có vi phạm và giành được lock, CPU mới thực hiện quét propagation – không còn tình trạng quét vô ích hoặc bỏ sót.

> 2. \*\*Cập nhật mô hình xác thực daemon:\*\* làm rõ cách kiểm tra đường dẫn tuyệt đối phù hợp với cấu trúc hệ thống tệp của xv6 (flat hay có thư mục), tránh giả định sai về `/bin`.

> 3. Cập nhật sơ đồ kiến trúc, mô tả deferred work và bảng các hàm thay đổi để phản ánh thiết kế mới.



\---



\## I. GIỚI THIỆU CHUNG (PROJECT OVERVIEW)



Các giải pháp bảo mật hiện đại như \*\*EDR (Endpoint Detection and Response)\*\* đóng vai trò quan trọng trong việc phát hiện và phản ứng với các hành vi độc hại ở tầng Endpoint. Tuy nhiên, hầu hết tài liệu hoặc bài học thực tế chỉ dừng lại ở việc vận hành công cụ ở tầng User‑space, thiếu đi góc nhìn sâu về cách nhân hệ điều hành (Kernel‑space) thu thập dữ liệu giám sát (Telemetry) và thực thi chính sách bảo vệ.



Dự án này đề xuất nâng cấp hệ điều hành nghiên cứu \*\*xv6 (kiến trúc RISC‑V)\*\*, tích hợp trực tiếp một giải pháp \*\*Mini‑EDR\*\* nằm trong vùng nhân (kernel‑level), tận dụng bộ lập lịch \*\*MLFQ (Multi‑Level Feedback Queue)\*\* để chủ động phát hiện, phân tích hành vi và cô lập tiến trình độc hại (ví dụ: Fork Bomb, Scheduler Gaming DoS).



\*\*Ghi chú quan trọng về MLFQ:\*\* xv6 gốc (bản MIT 6.S081/6.828) chỉ có scheduler round‑robin đơn giản, không có sẵn MLFQ. Bộ lập lịch MLFQ được giả định là kết quả của một đồ án/lab trước đó của tác giả. \*\*Trước khi bắt đầu Phase 1, cần xác nhận và trích dẫn rõ nguồn của mã MLFQ đang dùng\*\* (xem Phase 0 ở mục IV). Nếu MLFQ chưa tồn tại, khối lượng công việc cần được tính toán lại.



\---



\## II. KIẾN TRÚC HỆ THỐNG (SYSTEM ARCHITECTURE)



```

+-------------------------------------------------------------------+

|                           USER-SPACE                              |

|                                                                    |

|   +--------------------------+     +--------------------------+   |

|   |  SOC Analyst Dashboard   |     |    Malicious Process     |   |

|   | (Process: /edr\_daemon    |     |   (e.g., Fork Bomb, DoS) |   |

|   |  hoặc /bin/edr\_daemon)   |     |                          |   |

|   +-------------+------------+     +------------+-------------+   |

+-----------------|-------------------------------|-----------------+

&#x20;                 | (sys\_get\_security\_alerts)      | (Trigger Syscalls)

==================|=================================|=================

+-----------------|-------------------------------|-----------------+

|   KERNEL-SPACE  v                               v                 |

|   +-----------------------------------------------------------+   |

|   |                  Syscall Hooking Engine                   |   |

|   +-----------------------------+-----------------------------+   |

|   | (nhẹ, O(1), trong timer tick)                             |   |

|   |             Tier‑1 Rate‑based Detector                    |   |

|   |  - Đặt cờ need\_propagation                               |   |

|   |  - Bật tín hiệu edr\_work\_pending = 1 (ghi atomic)        |   |

|   +-----------------------------+-----------+-----------------+   |

|   | (nặng, trì hoãn sang scheduler, lock riêng)              |   |

|   |   Tier‑2 Volume‑based Safety Net + Tree Propagation       |   |

|   |   - Chỉ 1 CPU xử lý nhờ edr\_lock                        |   |

|   +-----------------------------+-----------------------------+   |

|                                 | (Mitigate Signal)               |

|                                 v                                 |

|   +-----------------------------------------------------------+   |

|   |               Hardened Scheduler (MLFQ)                   |   |

|   |   - Xử lý deferred propagation (dùng signal + lock)      |   |

|   |   - Cho QUARANTINED+killed tự exit qua usertrapret()      |   |

|   |   - Anti‑Gaming Demotion Logic                            |   |

|   +-----------------------------+-----------------------------+   |

|                                 | (push alert)                    |

|                                 v                                 |

|   +-----------------------------------------------------------+   |

|   |         Alert Ring Buffer (kích thước cố định)            |   |

|   +-----------------------------------------------------------+   |

+-------------------------------------------------------------------+

```



\*\*Nguyên tắc thiết kế cốt lõi:\*\*  

\- \*\*Ngắt timer chỉ làm việc nhẹ:\*\* Tier‑1 $O(1)$, đặt cờ `need\_propagation` và bật tín hiệu `edr\_work\_pending`.  

\- \*\*Scheduler xử lý việc nặng với cơ chế signal + lock:\*\* kiểm tra `edr\_work\_pending`, nếu có thì dùng `edr\_lock` (atomic test‑and‑set) để giành quyền; sau đó tắt tín hiệu và thực hiện quét cây – đảm bảo chỉ một CPU xử lý, không bỏ sót, không dư thừa.  

\- \*\*Tiến trình QUARANTINED bị `kill`:\*\* chỉ đặt `killed`, để tiến trình tự `exit()` qua `usertrapret()` – an toàn phần cứng.



\### 1. Kernel-space (Phần nhân bảo mật)



\* \*\*Syscall Hooking Engine:\*\* can thiệp bảng gọi hàm hệ thống để thu thập metadata của `fork()`, `exec()`, `kill()`.

\* \*\*Detection Engine (phân tán):\*\*  

&#x20; - \*Tier‑1 (Rate‑based)\*: chạy trong `clockintr()` → $O(1)$.  

&#x20; - \*Tier‑2 (Volume‑based) + Propagation\*: chạy trong scheduler, điều khiển bởi `edr\_work\_pending` + `edr\_lock`.

\* \*\*Mitigation Engine:\*\* chuyển trạng thái `QUARANTINED`, đánh dấu `killed`, tận dụng đường dẫn `usertrapret()`.

\* \*\*Alert Ring Buffer:\*\* ghi từ scheduler, dùng `alert\_lock` riêng.



\### 2. User-space (Phần ứng dụng)



\* \*\*EDR Daemon:\*\* tiến trình nền được nhận diện qua đường dẫn tuyệt đối khi `exec()`; đường dẫn cụ thể phụ thuộc vào cấu trúc hệ thống tệp của xv6 đang dùng (xem III.6). Định kỳ poll `sys\_get\_security\_alerts`.



\---



\## III. CÁC TÍNH NĂNG VÀ CƠ CHẾ KỸ THUẬT CHI TIẾT



\### 1. Bộ thu thập dữ liệu nhân (Kernel Telemetry Engine)



Mở rộng `struct proc` (trong `proc.h`):



```c

struct proc {

&#x20; // ... các trường mặc định của xv6 ...



&#x20; // --- Security Metadata mở rộng ---

&#x20; uint64 fork\_times\[EDR\_FORK\_SAMPLE]; // ring buffer thời điểm (tick) của N lần fork gần nhất

&#x20; uint   fork\_times\_idx;              // con trỏ ghi ring buffer

&#x20; uint   cumulative\_run\_time;         // tổng thời gian chạy thực tế trong hàng đợi hiện tại (Anti‑Gaming)

&#x20; uint8  is\_sandboxed;                // 0 = bình thường, 1 = WARN (soft), 2 = QUARANTINED (hard)

&#x20; uint8  sandbox\_reason;              // enum lý do

&#x20; uint64 quarantine\_tick;             // thời điểm bị cô lập

&#x20; uint8  need\_propagation;            // cờ: cần lan truyền sandbox xuống cây con

};

```



\### 2. Mô-đun phát hiện hành vi bất thường (Detection Engine – Phân tán)



\#### A. Thuật toán phát hiện Fork Bomb – Hai tầng (Two‑Tier Detection)



\*\*Tier 1 — Rate‑based (chạy trong timer interrupt, $O(1)$):\*\*  

Mỗi khi `clockintr()` xảy ra, nếu `myproc()` không rỗng, kiểm tra tần suất fork từ ring buffer.  

Nếu vượt ngưỡng → đặt `is\_sandboxed = 1` (WARN), `need\_propagation = 1`, và bật tín hiệu `edr\_work\_pending = 1` (atomic store với memory barrier).



\*\*Tier 2 — Volume‑based + Propagation (trì hoãn, dùng signal + lock):\*\*  

Trong scheduler, trước khi chọn tiến trình, thực hiện:



```c

if (edr\_work\_pending) {

&#x20;   if (\_\_sync\_lock\_test\_and\_set(\&edr\_lock, 1) == 0) {

&#x20;       // Đã giành được lock

&#x20;       if (edr\_work\_pending) {   // double-check

&#x20;           edr\_work\_pending = 0; // tắt tín hiệu

&#x20;           for (p = proc; p < \&proc\[NPROC]; p++) {

&#x20;               acquire(\&p->lock);

&#x20;               if (p->need\_propagation) {

&#x20;                   int count = count\_live\_descendants(p);

&#x20;                   if (count >= EDR\_TREE\_VOLUME\_THRESHOLD) {

&#x20;                       p->is\_sandboxed = 2;

&#x20;                       propagate\_sandbox(p);

&#x20;                   }

&#x20;                   p->need\_propagation = 0;

&#x20;               }

&#x20;               release(\&p->lock);

&#x20;           }

&#x20;       }

&#x20;       \_\_sync\_lock\_release(\&edr\_lock);

&#x20;   }

}

```



Giải thích:

\- `edr\_work\_pending` là tín hiệu mức cao (có việc cần làm).

\- `edr\_lock` là khóa bảo vệ, đảm bảo chỉ một CPU vào critical section tại một thời điểm.

\- `test\_and\_set` trả về giá trị cũ: nếu lock đang tự do (0), CPU giành được và vào xử lý; nếu lock đã bị giữ (1), CPU bỏ qua.

\- Double‑check `edr\_work\_pending` sau khi có lock để tránh trường hợp công việc đã được CPU khác xử lý ngay trước đó.

\- Logic này khắc phục triệt để lỗi đảo ngược tín hiệu/khóa trong v4.



\#### B. Lan truyền cờ theo cây tiến trình (Process‑Tree Propagation)



Hàm `propagate\_sandbox(root\_pid)` duyệt bảng proc, dùng `wait\_lock` + `p->lock` như trước, chỉ được gọi từ scheduler (không bao giờ từ interrupt handler).



\#### C. Cơ chế chống thao túng bộ lập lịch (Anti‑Scheduler Gaming DoS)



Giữ nguyên: khi tổng `cumulative\_run\_time` đạt ngưỡng $Q\_i$, MLFQ hạ cấp tiến trình, bất kể `yield()`.



\### 3. Chiến lược đồng bộ hóa (Concurrency \& Locking Strategy)



\- \*\*Ngắt timer (`clockintr`):\*\* chỉ đọc ring buffer của `myproc()` (có thể khóa ngắn `p->lock`). Viết atomic `edr\_work\_pending = 1`.

\- \*\*Scheduler:\*\* kiểm tra `edr\_work\_pending`, nếu có thì tranh `edr\_lock`. Khi vào critical section, tắt tín hiệu và quét cây. Sử dụng `wait\_lock` + `p->lock` như cũ.

\- \*\*Alert buffer:\*\* `alert\_lock` riêng, ghi từ scheduler.

\- \*\*An toàn `killed` + `QUARANTINED`:\*\* không thao tác trực tiếp lên bộ nhớ tiến trình khác; để tiến trình tự `exit()` qua `usertrapret()`.



\### 4. Mô-đun ngăn chặn chủ động (Mitigation Engine) – An toàn phần cứng



\#### Trạng thái `QUARANTINED` và các hàm cần sửa



| Hàm | Thay đổi cần thiết |

| --- | --- |

| `scheduler()` | - Bỏ qua tiến trình `QUARANTINED` \*\*trừ khi\*\* `killed == 1`.<br>- Khi gặp `QUARANTINED` + `killed`, chuyển về `RUNNABLE` và lập lịch.<br>\*\*Không\*\* thay đổi `epc`; tiến trình sẽ theo đường `usertrapret()` để tự `exit()`.<br>- Thêm logic deferred work như mô tả ở III.2. |

| `kill()` | Chỉ đặt `p->killed = 1`. Không giải phóng bộ nhớ. Với `QUARANTINED`, không làm gì thêm. |

| `usertrapret()` | Đã có sẵn `if(p->killed) exit(-1);` – cơ chế tự hủy tự nhiên. |

| `wait()` | Hoạt động bình thường. |

| `freeproc()` | Không đổi; forensic dump có thể thực hiện trước khi free (giới hạn slot). |

| `procdump()` | Thêm `"quarantined"` vào mảng trạng thái. |

| `allocproc()` | Khởi tạo trường EDR về 0. |



\### 5. Alert Ring Buffer \& Syscall Interface



Giữ nguyên: ring buffer 32 phần tử, drop‑oldest, `alert\_lock` riêng.



\### 6. Mô hình xác thực EDR Daemon – Đường dẫn tuyệt đối (cập nhật)



Bỏ `sys\_edr\_register()` và kiểm tra `p->name`. Thay vào đó:



\- Trong hàm `exec()`, lưu đường dẫn tuyệt đối của file thực thi (có thể lấy từ tham số `path` trước khi nạp). So sánh với một hằng số cấu hình, ví dụ: `EDR\_DAEMON\_PATH`.

\- \*\*Quan trọng:\*\* xv6 gốc của MIT có hệ thống tệp phẳng (flat), mọi file nằm ở thư mục gốc `/`. Do đó, nếu dùng xv6 gốc, đường dẫn sẽ là `"/edr\_daemon"`. Nếu hệ thống đã được mở rộng hỗ trợ thư mục con (có `mkdir`), đường dẫn có thể là `"/bin/edr\_daemon"`. Cần kiểm tra thực tế bản build và đặt `EDR\_DAEMON\_PATH` cho phù hợp.

\- Chỉ tiến trình có đường dẫn khớp chính xác mới được đặt `p->edr\_trusted = 1`, và chỉ những tiến trình này mới gọi được `sys\_get\_security\_alerts`.

\- Điều này ngăn chặn hoàn toàn việc tạo file giả mạo tên `edr\_daemon` ở thư mục khác để chiếm quyền.



\### 7. Đặc tả chi tiết cơ chế Deferred Work với Signal + Lock



Biến toàn cục:



```c

volatile int edr\_work\_pending = 0;   // tín hiệu có việc

volatile int edr\_lock = 0;           // khóa bảo vệ

```



Trong `clockintr()`:

```c

if (violation\_detected) {

&#x20;   p->need\_propagation = 1;

&#x20;   \_\_sync\_synchronize();

&#x20;   edr\_work\_pending = 1;            // bật tín hiệu

}

```



Trong `scheduler()`:

```c

if (edr\_work\_pending) {

&#x20;   if (\_\_sync\_lock\_test\_and\_set(\&edr\_lock, 1) == 0) {

&#x20;       if (edr\_work\_pending) {

&#x20;           edr\_work\_pending = 0;

&#x20;           // quét và propagation (O(N^2))

&#x20;           ...

&#x20;       }

&#x20;       \_\_sync\_lock\_release(\&edr\_lock);

&#x20;   }

}

```



\---



\## IV. LỘ TRÌNH TRIỂN KHAI CHI TIẾT (ROADMAP) — 9 tuần



```

&#x20;  Phase 0        Phase 1            Phase 2             Phase 3              Phase 4           Phase 5

&#x20;(đầu Tuần 1)   (Tuần 1-2)         (Tuần 3-4)          (Tuần 5-6)           (Tuần 7-8)          (Tuần 9)

+------------+ +---------------+ +------------------+ +-------------------+ +----------------+ +--------------+

| Xác minh \& | | Telemetry     | | Detection Engine | | Mitigation +      | | Attack Sim +   | | Buffer debug |

| trích dẫn  | | - Mở rộng     | | - Tier 1 (O(1)   | | Concurrency       | | edr\_daemon     | | + regression |

| MLFQ hiện  | |   struct proc | |   trong timer)   | | - QUARANTINED    | | - Fork bomb    | | test cho     |

| có         | | - Hook fork/  | | - Deferred work  | |   + safe exit     | |   script       | | fork/exec/   |

|            | |   exec, khóa  | |   (signal+lock)  | | - Multi-hart test | | - Alert dashbrd| | wait gốc  |

+------------+ +---------------+ +------------------+ +-------------------+ +----------------+ +--------------+

```



\* \*\*Phase 0:\*\* Xác minh MLFQ, kiểm tra cấu trúc hệ thống tệp để xác định `EDR\_DAEMON\_PATH`.

\* \*\*Tuần 1-2:\*\* Telemetry, hook fork/exec, mở rộng `struct proc`.

\* \*\*Tuần 3-4:\*\* Tier‑1 trong `clockintr`, deferred work với signal+lock, Anti‑Gaming.

\* \*\*Tuần 5-6:\*\* Trạng thái `QUARANTINED`, safe‑exit qua `usertrapret()`, kiểm thử đa nhân.

\* \*\*Tuần 7-8:\*\* Attack scripts, `edr\_daemon` (đường dẫn xác thực), Alert Ring Buffer.

\* \*\*Tuần 9:\*\* Dự phòng debug, regression test (`usertests`).



\---



\## V. TIÊU CHÍ ĐÁNH GIÁ VÀ MỤC TIÊU KIỂM THỬ KỲ VỌNG



| Kịch bản kiểm thử | Hành vi hệ thống mặc định | Mục tiêu kỳ vọng với Mini‑EDR | Trạng thái mục tiêu |

| --- | --- | --- | --- |

| \*\*Fork Bomb nhanh\*\* (Tier‑1) | Hệ thống treo sau vài giây. | Timer phát hiện trong vài tick, đặt cờ deferred. Scheduler (qua signal+lock) cô lập cây. Shell vẫn chạy. | Dự kiến đạt |

| \*\*Fork Bomb chậm\*\* (né Tier‑1, chạm Tier‑2) | Process table cạn kiệt. | Scheduler phát hiện cây vượt ngưỡng, kích hoạt quarantine. | Dự kiến đạt |

| \*\*Workload hợp lệ\*\* (`make -j`, script) | Không ảnh hưởng. | Không false positive; chỉ WARN thoáng qua. Đo false positive rate. | Dự kiến đạt |

| \*\*Scheduler Gaming\*\* | Độc hại chiếm 95% CPU. | Bị ép hạ cấp, CPU chia đều. | Dự kiến đạt |

| \*\*Giả mạo EDR Daemon\*\* (file `edr\_daemon` sai đường dẫn) | — | Không được cấp quyền trusted; không thể đọc alert. | Dự kiến đạt |

| \*\*Trích xuất Alert\*\* | Không có log. | `edr\_daemon` chính thống in alert; buffer hoạt động. | Dự kiến đạt |

| \*\*Kiểm thử đa nhân\*\* | — | Không panic/deadlock; cơ chế signal+lock ngăn tranh chấp thừa và bỏ sót. | Dự kiến đạt |

| \*\*Regression test\*\* | — | Toàn bộ `usertests` gốc pass. | Dự kiến đạt |



\---



\## VI. RỦI RO VÀ GIỚI HẠN



\* \*\*Deferred work có thể trễ nếu scheduler bận:\*\* nhưng lazy‑check trong `fork()` là lớp bảo vệ bổ sung.

\* \*\*Cơ chế signal+lock:\*\* cần đảm bảo các thao tác atomic được compiler hỗ trợ (GCC RISC‑V có sẵn).

\* \*\*Đường dẫn daemon:\*\* phải cấu hình đúng với hệ thống tệp của bản xv6 đang dùng (flat hay có thư mục). Nếu không, daemon hợp lệ có thể bị từ chối quyền.

\* \*\*Heuristic rule‑based:\*\* vẫn có khả năng bị evasion bởi attacker tinh vi; đây là giới hạn chung của EDR dựa trên luật.

\* \*\*Quy mô xv6:\*\* các ngưỡng và số lượng forensic slot được thiết kế cho `NPROC=64`, không suy rộng trực tiếp cho hệ điều hành sản xuất.



\---



\## VII. HƯỚNG MỞ RỘNG (tuỳ chọn)



\* Thích ứng ngưỡng theo tải hệ thống.

\* Whitelist pattern cho shell/init để giảm false positive hơn nữa.

\* Gửi alert qua UART/console thay vì poll.

\* Cơ chế forensic memory dump chi tiết hơn (khi bộ nhớ cho phép).



\---

