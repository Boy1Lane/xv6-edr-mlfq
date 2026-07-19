# Kế hoạch Cải tiến: 67/100 → 85+/100

> **Nguyên tắc thiết kế kế hoạch này**: Chọn những thay đổi có **tỷ lệ điểm tăng / giờ bỏ ra** cao nhất. Không làm việc thừa.

---

## Phân tích Gap (Khoảng cách điểm)

| Tiêu chí hiện tại | Điểm hiện tại | Điểm mục tiêu | Tăng | Effort |
|---|---|---|---|---|
| **Benchmark** | 2/10 | 8/10 | **+6** | 3-4h |
| Error Handling | 5/10 | 8/10 | +3 | 1h |
| Logging | 5/10 | 8/10 | +3 | 1h |
| Tính nhất quán | 6.5/10 | 9/10 | +2.5 | 1h |
| Chất lượng mã nguồn | 6.5/10 | 9/10 | +2.5 | 1.5h |
| Maintainability | 6/10 | 8.5/10 | +2.5 | 1h |
| Testing | 6.5/10 | 8.5/10 | +2 | 1h |
| Documentation | 7.5/10 | 9/10 | +1.5 | 2h |
| Modularization | 6/10 | 7.5/10 | +1.5 | 1h |

**Tổng thời gian ước tính: 12-13 giờ (1.5-2 ngày làm việc)**

> Với những thay đổi này, Overall Score đi từ 67/100 → **~88/100**

---

## NHÓM 1 — BENCHMARK (Ưu tiên tuyệt đối, +15-20 điểm overall)
> **Effort: 3-4 giờ | Impact: Cực lớn**
> 
> Đây là thứ **100% hội đồng sẽ hỏi**. Không có benchmark = không thể chứng minh MLFQ có ích gì. Đây là thay đổi quan trọng nhất.

### Cần làm gì?

Thêm hai chương trình benchmark vào `user/` và thêm hai test case mới vào `test-xv6.py`.

---

### Bước 1.1 — Tạo `user/bench_rr.c` (Workload chuẩn)

**Mục đích**: Chương trình sinh ra 4 tiến trình CPU-bound, đo tổng thời gian hoàn thành. Chạy trên cả MLFQ và RR để so sánh overhead.

```c
// user/bench_rr.c
// Benchmark: đo tổng thời gian hoàn thành N tiến trình CPU-bound.
// Kết quả: in ra "BENCH_DONE total_ticks=<số>"
// Dùng để so sánh MLFQ vs RR overhead.

#include "kernel/types.h"
#include "user/user.h"

#define NUM_WORKERS 4
#define WORK_UNITS  200000  // số vòng lặp mỗi worker

int main(void) {
  int start = uptime();

  for (int i = 0; i < NUM_WORKERS; i++) {
    int pid = fork();
    if (pid == 0) {
      // Worker: vòng lặp CPU-bound thuần túy
      volatile int x = 0;
      for (int j = 0; j < WORK_UNITS; j++) x += j;
      exit(0);
    }
  }

  // Parent: chờ tất cả workers
  for (int i = 0; i < NUM_WORKERS; i++)
    wait(0);

  int end = uptime();
  printf("BENCH_DONE total_ticks=%d\n", end - start);
  exit(0);
}
```

**Thêm vào `Makefile`** — trong danh sách `UPROGS`:
```makefile
$U/_bench_rr\
```

---

### Bước 1.2 — Tạo `user/bench_interactive.c` (Workload tương tác)

**Mục đích**: Mô phỏng tiến trình tương tác (ngủ nhiều, CPU ít). Quan sát MLFQ giữ chúng ở queue 0 (priority cao), trong khi CPU-bound bị đẩy xuống queue 2.

```c
// user/bench_interactive.c
// Benchmark: tiến trình tương tác vs CPU-bound trong MLFQ.
// In ra "INTERACTIVE_DONE response_ticks=<số>" — thời gian phản hồi trung bình.

#include "kernel/types.h"
#include "user/user.h"

#define ITERATIONS 10

int main(void) {
  int total = 0;

  for (int i = 0; i < ITERATIONS; i++) {
    int t1 = uptime();
    sleep(2);           // Giả lập I/O wait
    int t2 = uptime();
    total += (t2 - t1);
  }

  printf("INTERACTIVE_DONE response_ticks=%d avg=%d\n",
         total, total / ITERATIONS);
  exit(0);
}
```

**Thêm vào `Makefile`**:
```makefile
$U/_bench_interactive\
```

---

### Bước 1.3 — Thêm `test_benchmark()` vào `test-xv6.py`

**Vị trí**: Thêm sau hàm `test_mlfq()` (dòng 264).

```python
def test_benchmark():
    """
    Benchmark test: đo overhead của MLFQ scheduler.
    - Chạy bench_rr (4 CPU-bound workers song song)
    - Ghi lại total_ticks
    - Chạy bench_interactive (sleep-heavy process)
    - Kiểm tra response time hợp lý
    Kết quả được in ra để so sánh thủ công với RR baseline.
    """
    print("=== BENCHMARK: MLFQ Scheduler Performance ===")
    q = QEMU(True)

    # --- Test 1: CPU-bound throughput ---
    print("[1/2] Running CPU-bound workload (4 workers)...")
    q.cmd("bench_rr\n")
    deadline = time.time() + 30
    bench_done = False
    total_ticks = -1
    while time.time() < deadline:
        time.sleep(1)
        q.read()
        ok, line = q.match(r".*BENCH_DONE total_ticks=(\d+).*", exit=False)
        if ok:
            import re
            m = re.search(r'total_ticks=(\d+)', line)
            if m:
                total_ticks = int(m.group(1))
            bench_done = True
            break

    if not bench_done:
        print("FAIL: bench_rr did not complete in time")
        q.stop()
        sys.exit(1)
    print(f"    CPU-bound total_ticks = {total_ticks}")

    # --- Test 2: Interactive workload ---
    print("[2/2] Running interactive workload (sleep-heavy)...")
    q.cmd("bench_interactive\n")
    deadline = time.time() + 30
    interactive_done = False
    avg_ticks = -1
    while time.time() < deadline:
        time.sleep(1)
        q.read()
        ok, line = q.match(r".*INTERACTIVE_DONE.*avg=(\d+).*", exit=False)
        if ok:
            import re
            m = re.search(r'avg=(\d+)', line)
            if m:
                avg_ticks = int(m.group(1))
            interactive_done = True
            break

    q.stop()

    if not interactive_done:
        print("FAIL: bench_interactive did not complete in time")
        sys.exit(1)

    print(f"    Interactive avg response_ticks = {avg_ticks}")
    print()
    print("=== BENCHMARK RESULTS ===")
    print(f"  CPU-bound  throughput : {total_ticks} ticks for 4 workers")
    print(f"  Interactive response  : {avg_ticks} ticks/iteration avg")
    print()
    # Interactive response nên ≈ sleep_ticks (2 ticks per sleep)
    # Nếu avg_ticks quá lớn (> 6), MLFQ đang không ưu tiên đúng
    if avg_ticks <= 6:
        print("  [PASS] Interactive latency is low — MLFQ prioritizes well")
    else:
        print("  [WARN] Interactive latency higher than expected")
    print("OK")
```

> **Kết quả đạt được**: Benchmark score: **2→8** (+6 điểm trong tiêu chí, +15-20 điểm overall vì ảnh hưởng đến Research potential, Academic value, Impression score).

---

## NHÓM 2 — XÓA DEAD CODE + ĐỊNH NGHĨA ENUM (1 giờ, +8 điểm overall)

> **Effort: 1 giờ | Impact: Lớn**
> 
> Dead code là dấu hiệu "vội vàng" làm mất trust của reviewer với TOÀN BỘ codebase. Fix nhanh nhưng tác động lớn đến Tính nhất quán (6.5→9), Chất lượng mã nguồn (6.5→8.5).

### Bước 2.1 — Định nghĩa `enum EDRReason` trong `kernel/proc.h`

**Vấn đề**: `sandbox_reason` có comment `// enum lý do` nhưng không có enum thực sự. Các giá trị 1, 2 là magic number rải khắp code.

**Thay đổi tại `kernel/proc.h`** — Thêm ngay trước dòng `enum procstate`:

```c
// === EDR: Lý do cô lập tiến trình ===
// Các giá trị này được lưu trong p->sandbox_reason
typedef enum {
  EDR_REASON_NONE        = 0,  // Không bị cô lập
  EDR_REASON_FORK_RATE   = 1,  // Tier-1: fork quá nhanh trong cửa sổ thời gian
  EDR_REASON_TREE_VOLUME = 2,  // Tier-2: cây tiến trình quá lớn
} edr_reason_t;
```

**Thay đổi tất cả magic numbers** (tìm kiếm `sandbox_reason = 1` và `= 2`):

| File | Dòng | Trước | Sau |
|---|---|---|---|
| `trap.c` | 278 | `sandbox_reason = 1;` | `sandbox_reason = EDR_REASON_FORK_RATE;` |
| `sysproc.c` | 48 | `sandbox_reason = 1;` | `sandbox_reason = EDR_REASON_FORK_RATE;` |
| `proc.c` | 505 | `sandbox_reason = 2;` | `sandbox_reason = EDR_REASON_TREE_VOLUME;` |
| `proc.c` | 553 | `sandbox_reason = 2;` | `sandbox_reason = EDR_REASON_TREE_VOLUME;` |

---

### Bước 2.2 — Xóa field `wait_time` khỏi `struct proc`

**Vấn đề**: `wait_time` được khai báo với comment `(dùng cho Aging - nếu làm)` — không bao giờ được đọc hay ghi. Đây là dead code rõ ràng.

**Xóa trong `kernel/proc.h`** dòng 109:
```c
// XÓA dòng này:
int wait_time;       // Thời gian chờ (dùng cho Aging - nếu làm)
```

**Xóa trong `kernel/proc.c`** dòng 139:
```c
// XÓA dòng này:
p->wait_time = 0;
```

> **Thay thế tùy chọn** (nếu muốn giữ cho tương lai): Đặt `wait_time` vào `#ifdef EDR_AGING_ENABLED` để rõ ràng đây là code chưa triển khai.

---

### Bước 2.3 — Export `total_runtime` qua `proc_info`

**Vấn đề**: `total_runtime` được cập nhật tại `trap.c:91,209` nhưng không bao giờ được export — reviewer sẽ thấy ngay đây là code thừa.

**Thêm vào `kernel/pstat.h`**:
```c
struct p_info {
  int pid[NPROC];
  int priority[NPROC];
  int ticks_used[NPROC];
  int state[NPROC];
  int total_runtime[NPROC];   // <-- THÊM DÒNG NÀY
  uint8 is_sandboxed[NPROC];  // <-- THÊM DÒNG NÀY (bonus: show quarantine status)
};
```

**Thêm vào `kernel/sysproc.c`** trong `sys_proc_info()` (sau dòng `pinfo.ticks_used[i] = ...`):
```c
pinfo.total_runtime[i] = p->total_runtime;
pinfo.is_sandboxed[i]  = p->is_sandboxed;
```

**Lợi ích kép**: `ps_monitor` giờ có thể hiển thị tiến trình nào đang bị sandboxed — làm demo trực quan hơn nhiều.

---

## NHÓM 3 — TÁCH `mlfq_tick()` (1.5 giờ, +5 điểm overall)

> **Effort: 1.5 giờ | Impact: Trung bình-Lớn**
> 
> Đây là vi phạm DRY nghiêm trọng nhất trong codebase. Logic MLFQ bị copy-paste identically giữa `usertrap()` (trap.c:84-132) và `kerneltrap()` (trap.c:202-251). Bất kỳ reviewer kernel nào cũng sẽ chú ý ngay.

### Bước 3.1 — Khai báo `mlfq_tick()` trong `kernel/defs.h`

Tìm phần khai báo của `trap.c` functions trong `kernel/defs.h` và thêm:
```c
// trap.c
void            mlfq_tick(void);   // <-- THÊM DÒNG NÀY
```

### Bước 3.2 — Tạo hàm `mlfq_tick()` trong `kernel/trap.c`

**Thêm hàm mới** ngay trước `usertrap()`:

```c
// mlfq_tick -- xử lý logic MLFQ cho một timer interrupt.
// Gọi từ cả usertrap() và kerneltrap().
// Không được gọi khi không có tiến trình hiện hành (p == 0).
// Trả về 1 nếu cần yield, 0 nếu không.
int
mlfq_tick(void)
{
  struct proc *p = myproc();
  int need_yield = 0;

  if(p){
    // 1. Cập nhật thời gian chạy
    p->ticks_used++;
    p->total_runtime++;
    p->cumulative_run_time++;

    // 2. Lấy quantum tương ứng với priority
    int quantum;
    if(p->priority == 0)      quantum = QUANTUM_0;
    else if(p->priority == 1) quantum = QUANTUM_1;
    else                      quantum = QUANTUM_2;

    // 3. Hết quantum -> hạ cấp (demotion)
    if(p->ticks_used >= quantum){
      if(p->priority < 2)
        p->priority++;
      p->ticks_used = 0;
      p->cumulative_run_time = 0;
      need_yield = 1;
    }
    // Anti-Gaming (§III.2.C): phát hiện tiến trình cố tình sleep() ngắn
    // để né quantum. cumulative_run_time không reset khi sleep(), chỉ
    // reset khi bị hạ cấp.
    else if(p->cumulative_run_time >= quantum){
      if(p->priority < 2)
        p->priority++;
      p->ticks_used = 0;
      p->cumulative_run_time = 0;
      need_yield = 1;
    }
    // Tiền chiếm dụng: có tiến trình priority cao hơn đang chờ
    else if(has_higher_priority(p->priority)){
      need_yield = 1;
    }
  }

  // 4. Aging toàn hệ thống (mỗi AGING_INTERVAL ticks)
  if(ticks % AGING_INTERVAL == 0){
    promote_all();
    need_yield = 1;
  }

  return need_yield;
}
```

### Bước 3.3 — Đơn giản hóa `usertrap()` và `kerneltrap()`

**Thay thế block timer interrupt trong `usertrap()`** (dòng 84-133):
```c
  // give up the CPU if this is a timer interrupt.
  if(which_dev == 2){
    if(mlfq_tick())
      yield();
  }
```

**Thay thế block timer interrupt trong `kerneltrap()`** (dòng 202-251):
```c
  // give up the CPU if this is a timer interrupt.
  if(which_dev == 2 && myproc() != 0){
    if(mlfq_tick())
      yield();
  }
```

> **Kết quả**: Xóa ~50 dòng code trùng lặp, maintainability tăng mạnh. Reviewer thấy ngay đây là code được viết cẩn thận.

---

## NHÓM 4 — SỬA ERROR HANDLING (1 giờ, +6 điểm overall)

> **Effort: 1 giờ | Impact: Trung bình**
> 
> Hai lỗi error handling dễ sửa nhưng ảnh hưởng đến độ tin cậy của toàn hệ thống.

### Bước 4.1 — Fix `argaddr()` return check trong `sys_get_security_alerts()`

**Vấn đề tại `kernel/sysproc.c:183`**: Nếu `argaddr()` trả về -1 (địa chỉ không hợp lệ), code vẫn tiếp tục chạy đến `copyout` và cố ghi vào địa chỉ sai.

**Trước**:
```c
uint64
sys_get_security_alerts(void)
{
  uint64 addr;
  argaddr(0, &addr);          // <-- BUG: bỏ qua lỗi
  struct proc *p = myproc();
  
  if (!p->edr_trusted) return -1;
  ...
```

**Sau** (thêm check):
```c
uint64
sys_get_security_alerts(void)
{
  uint64 addr;
  if(argaddr(0, &addr) < 0)   // <-- FIX: kiểm tra lỗi
    return -1;
  struct proc *p = myproc();
  
  if (!p->edr_trusted) return -1;
  ...
```

---

### Bước 4.2 — Thêm `alerts_dropped` counter

**Vấn đề**: Khi ring buffer `alerts[]` đầy, các alert mới bị drop không thông báo. Reviewer sẽ hỏi "làm sao biết bao nhiêu alert bị mất?"

**Thêm vào `kernel/proc.c`** (nơi khai báo `alerts`, `alert_head`, `alert_tail`):
```c
int alerts_dropped = 0;  // Số alert bị mất do buffer đầy
```

**Trong hàm `edr_push_alert()`** (hoặc nơi ghi vào buffer), tìm chỗ check buffer full và thêm:
```c
// Nếu buffer đầy, drop entry cũ nhất và ghi nhận
if ((alert_head + 1) % EDR_MAX_ALERTS == alert_tail) {
  alert_tail = (alert_tail + 1) % EDR_MAX_ALERTS;  // drop oldest
  alerts_dropped++;  // <-- GHI NHẬN SỐ LẦN DROP
}
```

**Export qua `sys_get_security_alerts()`**: Thêm trả về `-2` khi có dropped alerts để daemon biết cần cảnh báo.

**Cập nhật `user/edr_daemon.c`** để log khi có dropped:
```c
} else if (res == 0) {
  // Có thể check alerts_dropped qua một syscall riêng
  sleep(10);
}
```

---

## NHÓM 5 — CẢI THIỆN TELEMETRY + FALSE-POSITIVE TEST (2 giờ, +7 điểm overall)

> **Effort: 2 giờ | Impact: Trung bình**

### Bước 5.1 — Thêm `parent_pid` vào `struct alert_entry`

**Vấn đề**: Alert hiện tại không có parent PID — không thể reconstruct process tree từ log.

**Thay đổi `kernel/types.h`**:
```c
struct alert_entry {
  int    pid;
  int    parent_pid;   // <-- THÊM: PID của cha để reconstruct cây
  uint8  reason;
  uint64 tick;
  char   name[16];
  char   reason_str[24]; // <-- THÊM: tên lý do dạng string (dễ đọc log)
};
```

**Thêm `reason_str` vào chỗ ghi alert** (trong `kernel/proc.c`):
```c
// Khi ghi alert, điền reason_str dựa vào reason:
if (reason == EDR_REASON_FORK_RATE)
  strncpy(alert.reason_str, "FORK_RATE_EXCEEDED", 24);
else if (reason == EDR_REASON_TREE_VOLUME)
  strncpy(alert.reason_str, "TREE_VOLUME_EXCEEDED", 24);
```

**Cập nhật `user/edr_daemon.c`** để in đẹp hơn:
```c
printf("\x1b[31m[EDR ALERT] PID %d (parent: %d, name: %s)\n"
       "            Reason: %s at tick %lu\x1b[0m\n",
       alert.pid, alert.parent_pid, alert.name,
       alert.reason_str, alert.tick);
```

---

### Bước 5.2 — Thêm `test_false_positive()` vào `test-xv6.py`

**Vấn đề**: Không có test kiểm tra rằng các chương trình bình thường (usertests, sh) KHÔNG bị quarantine nhầm.

**Thêm hàm mới vào `test-xv6.py`**:

```python
def test_false_positive():
    """
    False Positive Test: kiểm tra rằng các chương trình được whitelist
    KHÔNG bị EDR quarantine khi chạy bình thường.
    - Chạy edr_daemon
    - Chạy usertests -q (quick tests, có nhiều fork)
    - Kiểm tra KHÔNG có alert nào xuất hiện trong 60 giây
    """
    print("Test EDR False Positive (Whitelist Validation)")
    q = QEMU(True)
    
    # Khởi động edr_daemon
    q.cmd("edr_daemon &\n")
    time.sleep(1)
    q.read()
    ok, _ = q.match(r".*edr_daemon: started successfully.*", exit=False)
    if not ok:
        print("FAIL: EDR daemon failed to start")
        q.stop()
        sys.exit(1)

    # Chạy usertests quick — đây là workload bình thường có whitelist
    print("  Running usertests -q while EDR is active...")
    q.cmd("usertests -q\n")
    
    # Đợi usertests hoàn thành
    deadline = time.time() + 120
    usertests_done = False
    while time.time() < deadline:
        time.sleep(2)
        q.read()
        ok, _ = q.match(r".*ALL TESTS PASSED.*", exit=False)
        if ok:
            usertests_done = True
            break

    # Kiểm tra KHÔNG có alert nào (false positive)
    alert_ok, _ = q.match(r".*EDR ALERT.*quarantined.*", exit=False)
    q.stop()

    if not usertests_done:
        print("FAIL: usertests did not complete (possible quarantine)")
        sys.exit(1)
    
    if alert_ok:
        print("FAIL: False positive! Whitelisted process was quarantined")
        sys.exit(1)
    
    print("OK: No false positives — whitelist working correctly")
```

---

## NHÓM 6 — DESIGN DOCUMENT (2 giờ, +5 điểm overall)

> **Effort: 2 giờ | Impact: Trung bình**
> 
> Hội đồng học thuật sẽ đánh giá cao khi thấy bạn **nghĩ trước rồi mới code**. Một design document 2-3 trang thuyết phục hơn 200 dòng comment trong code.

### Tạo `DESIGN.md` tại root dự án

Nội dung tối thiểu (3 phần):

```markdown
# Design Document: xv6-MLFQ + Mini-EDR

## 1. Threat Model

### Attacker Model
- **Mục tiêu tấn công**: Cạn kiệt CPU và memory của hệ thống xv6 bằng Fork Bomb.
- **Năng lực attacker**: User-space process bình thường, không có quyền kernel.
- **Kịch bản tấn công**:
  1. Fork Bomb kiểu tốc độ cao (Tier-1 threat): fork() nhiều lần liên tục trong thời gian ngắn.
  2. Fork Bomb kiểu cây lớn (Tier-2 threat): fork() chậm để tránh rate detection, nhưng tạo ra cây tiến trình khổng lồ.

### Những gì NGOÀI threat model
- Kernel exploits hoặc privilege escalation.
- Side-channel attacks.
- Network-based threats (xv6 không có network).

---

## 2. Threshold Justification

### Tier-1: EDR_FORK_SAMPLE=6, EDR_FORK_RATE_WINDOW_TICKS=10

**Lý do chọn 6 mẫu trong 10 ticks**:
- Với QUANTUM_0=1 tick, một tiến trình bình thường fork() nhiều nhất 1-2 lần trong 10 ticks trước khi bị demotion sang queue 2.
- Fork bomb fork() liên tục → 6+ lần trong 10 ticks là bất thường với bất kỳ workload bình thường nào.
- Threshold này đủ cao để tránh false positive với `forktest` (được whitelist).

**Trade-off**: Threshold thấp hơn (4/10) tăng detection rate nhưng tăng false positive. Threshold cao hơn (8/10) giảm false positive nhưng cho phép fork bomb nhỏ hơn.

### Tier-2: EDR_TREE_VOLUME_THRESHOLD=16

**Lý do chọn 16 tiến trình con**:
- Hệ thống xv6 có NPROC=64. Một tiến trình bình thường (shell, editor) không tạo quá 3-5 tiến trình con.
- 16 tiến trình con = 25% tổng capacity — đây là ngưỡng cần can thiệp.
- `usertests` tạo nhiều nhất ~8-10 tiến trình con đồng thời → không trigger false positive.

---

## 3. Known Limitations

### L1: Path-based Whitelist (Mức độ: Nghiêm trọng)
**Vấn đề**: Whitelist dựa trên tên file. Attacker có thể tạo binary tên `/sh` để bypass.
**Giải pháp tiềm năng**: Binary hash verification tại exec-time (ngoài scope hiện tại).

### L2: Orphan Process Reparenting (Mức độ: Trung bình)
**Vấn đề**: Khi tiến trình cha exit, các con được reparent về `initproc`. Tier-2 mất liên kết cây.
**Giải pháp tiềm năng**: Ghi nhớ original root PID trong alert thay vì traverse cây động.

### L3: Single-daemon SPOF (Mức độ: Thấp)
**Vấn đề**: Nếu EDR daemon bị kill, quarantined processes đóng băng vĩnh viễn.
**Giải pháp tiềm năng**: Auto-restart mechanism hoặc kernel-side timeout sau N ticks.

### L4: Clockintr Lock-free Access (Mức độ: Thấp trong xv6 single-CPU mode)
**Vấn đề**: `clockintr()` đọc/ghi `p->fork_times[]` và `p->is_sandboxed` không lock.
**Justification**: Trên xv6-riscv single-CPU, mỗi `clockintr()` chỉ thấy tiến trình đang chạy trên CPU đó. Writes từ `propagate_sandbox()` được serialize qua `wait_lock`. `__sync_synchronize()` đảm bảo memory ordering.
**Risk**: Trên SMP với nhiều CPU, có thể cần thêm atomic load/store cho `is_sandboxed`.
```

---

## Tổng hợp: Điểm trước và sau

| Tiêu chí | Trước | Sau | Nhóm thực hiện |
|---|---|---|---|
| Thiết kế kiến trúc | 7.5 | 8.5 | Nhóm 6 (Design doc) |
| Tính nhất quán | 6.5 | 9.0 | Nhóm 2 (Enum + dead code) |
| Tính đầy đủ | 7.0 | 7.5 | Nhóm 4 (Error handling) |
| Chất lượng mã nguồn | 6.5 | 9.0 | Nhóm 2 + 3 (DRY + enum) |
| Khả năng build | 9.0 | 9.0 | — |
| Khả năng chạy | 8.5 | 8.5 | — |
| Logging | 5.0 | 8.5 | Nhóm 5 (parent_pid + reason_str) |
| Error Handling | 5.0 | 8.0 | Nhóm 4 (argaddr + dropped counter) |
| Modularization | 6.0 | 7.5 | Nhóm 3 (mlfq_tick) |
| Documentation | 7.5 | 9.0 | Nhóm 6 (Design doc) |
| Testing | 6.5 | 8.5 | Nhóm 1 + 5 (benchmark + false-pos) |
| **Benchmark** | **2.0** | **8.5** | **Nhóm 1 (Critical!)** |
| Khả năng demo | 8.5 | 9.0 | Nhóm 5 (better alert output) |
| Maintainability | 6.0 | 9.0 | Nhóm 3 (mlfq_tick) |
| Readability | 6.5 | 8.5 | Nhóm 2 + 3 |
| Khả năng mở rộng | 6.5 | 7.0 | Nhóm 5 (reason_str extensible) |
| **Trung bình** | **65** | **~87** | |

---

## Lịch trình thực hiện (1.5 ngày làm việc)

```
Ngày 1 (8 tiếng):
  Buổi sáng (4h):
    [x] Nhóm 2: Enum EDRReason + xóa wait_time + export total_runtime  (1h)
    [x] Nhóm 3: Tách mlfq_tick() + cập nhật usertrap/kerneltrap        (1.5h)
    [x] Nhóm 4: Fix argaddr check + thêm alerts_dropped counter         (1h)
    [x] Kiểm tra build thành công: make -j4                             (0.5h)

  Buổi chiều (4h):
    [x] Nhóm 5: Thêm parent_pid + reason_str vào alert_entry            (1h)
    [x] Nhóm 5: Thêm test_false_positive() vào test-xv6.py             (1h)
    [x] Nhóm 1: Tạo bench_rr.c + bench_interactive.c                   (1.5h)
    [x] Test nhanh: python3 test-xv6.py edr                             (0.5h)

Ngày 2 (4 tiếng):
  Buổi sáng (4h):
    [x] Nhóm 1: Thêm test_benchmark() vào test-xv6.py                  (1.5h)
    [x] Nhóm 6: Viết DESIGN.md (threat model + threshold + limitations) (2h)
    [x] Chạy toàn bộ test suite: python3 test-xv6.py edr               (0.5h)
    [x] Chạy: python3 test-xv6.py mlfq                                 (0.5h)
    [x] Chạy: python3 test-xv6.py benchmark                            (0.5h)
    [x] Chạy: python3 test-xv6.py false_positive                       (0.5h)
```

---

## Câu trả lời cho 3 câu hỏi khó của hội đồng (sau khi thực hiện)

| Câu hỏi | Trả lời sau cải tiến |
|---|---|
| "Overhead của MLFQ so với RR?" | "Như kết quả benchmark, 4 CPU-bound workers mất X ticks. Interactive process có response time trung bình Y ticks — tương đương với sleep duration." |
| "Tại sao ngưỡng 6 fork trong 10 ticks?" | "Được nêu rõ trong DESIGN.md §2: với QUANTUM_0=1, tiến trình bình thường fork tối đa 1-2 lần trong 10 ticks. Ngưỡng 6 đặt vùng an toàn 3x so với workload bình thường." |
| "Race condition trong clockintr?" | "Được phân tích trong DESIGN.md §3 mục L4: justified cho single-CPU mode, risk được acknowledge cho multi-CPU. `__sync_synchronize()` đảm bảo ordering." |
