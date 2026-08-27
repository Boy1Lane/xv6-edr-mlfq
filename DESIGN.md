# xv6 Mini-EDR & MLFQ Scheduler - Design Document

## 1. Threat Model & Architecture
### Threat Model
Hệ thống xv6 Mini-EDR được thiết kế để bảo vệ hệ điều hành khỏi các tiến trình độc hại (malicious processes) ở mức user-space. Các mối đe dọa chính bao gồm:
- **Fork Bomb (Từ chối dịch vụ - DoS):** Một tiến trình liên tục gọi `fork()` để làm cạn kiệt tài nguyên PID và bộ nhớ của hệ thống, khiến các tiến trình hợp lệ không thể chạy được.
- **CPU Starvation:** Các tiến trình độc hại hoặc tính toán nặng (CPU-bound) chiếm dụng toàn bộ thời gian CPU, làm cho các tiến trình tương tác (I/O-bound) không thể phản hồi.
- **Evasion & Gaming:** Các tiến trình cố gắng qua mặt bộ định thời bằng cách nhường CPU (yield) ngay trước khi hết quantum để giữ mức ưu tiên cao, hoặc cố tình che giấu hành vi rẽ nhánh (fork) thông qua mô hình phân cấp phức tạp (Process Tree).

### Architecture
- **In-kernel Telemetry:** Kernel thu thập dữ liệu về tần suất `fork` (`EDR_FORK_SAMPLE` 6 forks trong `EDR_FORK_RATE_WINDOW_TICKS` 10 ticks) và cấu trúc cây tiến trình (`tree volume` vượt ngưỡng `EDR_TREE_VOLUME_THRESHOLD` 16 theo `kernel/param.h:22-24`). Nếu vi phạm các ngưỡng đã định sẵn, tiến trình sẽ bị đưa vào khu vực cách ly (Quarantine).
- **EDR Daemon (User-space):** Thay vì xử lý logic bảo mật phức tạp trong kernel, xv6 Mini-EDR xuất các cảnh báo an ninh (Security Alerts) ra không gian người dùng thông qua system call `sys_get_security_alerts`. `edr_daemon` (chạy với cờ `edr_trusted`) đóng vai trò nhận các cảnh báo này, log ra màn hình và tiêu diệt (kill) các tiến trình vi phạm.
- **MLFQ Scheduler:** Bộ định thời đa hàng đợi phản hồi (Multi-Level Feedback Queue) quản lý tài nguyên CPU. Các tiến trình bị Quarantine sẽ bị giam ở hàng đợi thấp nhất. MLFQ tích hợp tính năng Anti-Gaming (ngăn chặn gian lận bằng cách tính tổng thời gian chạy tích lũy `cumulative_run_time` trong mức ưu tiên hiện tại) và Priority Boost (nâng ưu tiên định kỳ sau mỗi `AGING_INTERVAL` ticks để tránh đói CPU).

## 2. Data Structures
Các cấu trúc dữ liệu cốt lõi phục vụ bảo mật và giám sát:

- **`struct alert_entry` (kernel/types.h):**
  Lưu trữ thông tin chi tiết về tiến trình vi phạm, bao gồm: `pid`, `parent_pid`, `reason` (mã lỗi), `reason_str` (chuỗi giải thích lý do), `tick` (thời điểm vi phạm), và `name` (tên tiến trình).
- **`alerts[EDR_MAX_ALERTS]` (Ring Buffer):**
  Bộ đệm vòng nằm trong không gian kernel (proc.c) lưu trữ các cảnh báo EDR. Truy cập được bảo vệ bởi spinlock `alert_lock`. Biến `alerts_dropped` theo dõi số lượng cảnh báo bị loại bỏ do tràn bộ đệm.
- **`edr_reason_t` (kernel/proc.h):**
  Enum chuẩn hoá các lý do Quarantine: `EDR_REASON_NONE = 0`, `EDR_REASON_FORK_RATE = 1`, `EDR_REASON_TREE_VOLUME = 2`, `EDR_REASON_GLOBAL_PRESSURE = 3`.
- **`struct proc` extensions (kernel/proc.h):**
  Các trường bổ sung phục vụ Telemetry và định thời:
  - `priority`, `ticks_used`, `cumulative_run_time`, `total_runtime`: Quản lý MLFQ. Dual demotion xảy ra khi `ticks_used >= quantum` hoặc `cumulative_run_time >= quantum` (Anti-Gaming trong `kernel/trap.c:97`). Hệ thống áp dụng Aging định kỳ sau mỗi `AGING_INTERVAL` (100 ticks theo `kernel/param.h:19`).
  - `quarantine_tick`, `fork_times`, `fork_times_idx`, `is_sandboxed`, `sandbox_reason`, `need_propagation`, `edr_trusted`, `is_whitelisted`: Quản lý EDR.
- **`struct p_info` (kernel/pstat.h):**
  Export trạng thái nội bộ (`total_runtime`, `is_sandboxed`, `priority`) ra user-space phục vụ cho công cụ giám sát `ps_monitor`.

## 3. Justifications (Lựa chọn Thiết Kế)
- **Hash-based Binary Trust Model (P2):**
  Kernel không cấp đặc quyền dựa trên tên file hay thứ tự PID mà xác thực danh tính binary thông qua hàm băm SHA-256 (`hash_inode()` trong `kernel/exec.c:39-63,233`). Cờ `edr_trusted = 1` chỉ được cấp cho tiến trình khi hash của binary khớp với `WL_IDX_EDR_DAEMON`. Khi `fork()`, tiến trình con không kế thừa đặc quyền (`np->edr_trusted = 0` trong `kernel/proc.c:334`), trong khi `is_whitelisted` được kế thừa để các bộ test (`usertests`, `forktest`) hoạt động bình thường. Toàn bộ bảng whitelist được ký bảo mật tại thời điểm build (`scripts/gen-whitelist.sh:45-51`) với chữ ký `wl_signature` và được kiểm tra toàn vẹn lúc boot (`whitelist_verify()`).
- **Locking & Deadlock Avoidance:**
  Sử dụng `alert_lock` độc lập để bảo vệ Ring Buffer. Hàm `edr_push_alert` có thể được gọi ngay cả khi đang giữ `wait_lock` mà không gây ra vi phạm phân cấp khóa (Lock Hierarchy) hay tình trạng Deadlock.
- **Ring Buffer for Telemetry:**
  Sử dụng Ring Buffer giúp Kernel duy trì hiệu năng cao khi đẩy alerts và chống lại tình trạng đầy bộ nhớ do Flood Alerts.
- **DRY Refactoring (mlfq_tick):**
  Toàn bộ logic tính toán hết hạn Quantum và System Aging được đóng gói trong hàm `mlfq_tick()`, tái sử dụng chung cho `kerneltrap` và `usertrap`, đảm bảo độ ổn định và khả năng bảo trì.

## 4. Experimental Results

### 4.1 Benchmark: MLFQ vs Round Robin

Measured automatically by the CI benchmark job (5 runs per cell, median ± stdev,
`-smp 3`, see `benchmark_results.csv` artifact sinh bởi `scripts/test-xv6.py:551-620` (BENCH_RUNS=5)):

| Metric | MLFQ Scheduler | Round-Robin Baseline |
| :--- | :---: | :---: |
| **CPU-bound Throughput (4 workers, median)** | 17 ticks | 17 ticks |
| **Interactive Response w/ background load (median)** | **2 ticks** | 8 ticks |

**Interpretation**: MLFQ matches RR on raw CPU-bound throughput while making an
interactive task under contention **~4x more responsive** (5 runs, median `-smp 3`,
kết quả chi tiết xem `README.md:80-86` và artifact `benchmark_results.csv` sinh bởi `scripts/test-xv6.py`).

### 4.2 Security Detection Test Results

| Test Case | Expected | Actual | Pass? |
|---|---|---|---|
| Fork bomb (multitest, 8 forks/10ticks) | Alert + Quarantine | Alert raised in <15 ticks | ✅ |
| Legitimate I/O workload (stressfs) | No alert | No alert triggered | ✅ |
| Whitelisted process (usertests) | No quarantine | Ran to completion | ✅ |

### 4.3 Known Limitations

**L1 — Path-based Whitelist — ✅ MITIGATED (SHA-256 binary identity)**
> Whitelist/trust giờ gắn với **hash SHA-256 của nội dung binary**, được sinh từ chính
> build artifacts (`scripts/gen-whitelist.sh` → `kernel/whitelist.h`) và xác minh tại
> exec-time (`kernel/exec.c`). Đổi tên binary không còn mang lại đặc quyền; sửa đổi
> binary làm mất đặc quyền ngay lập tức. Fail-closed: binary không hash được thì
> mặc định không whitelisted.

**L2 — Single-CPU Concurrency Assumption — ✅ MITIGATED (SMP-safe atomics & locking)**
> P2 đã chuẩn hóa mọi fast-path: `mlfq_tick()` snapshot `ticks` qua `tickslock` và
> mọi cập nhật `p->priority`/`ticks_used` đều giữ `p->lock`; `has_higher_priority()`
> quét proc table với `p->lock` cho từng entry; `clockintr()` dùng atomic load
> cho `ticks`/`edr_last_window` và chỉ CPU 0 cập nhật EMA (CAS) và sweeps.
> Hệ thống hiện mặc định `-smp 3` và đã được stress-test với `usertests` + EDR.

**L3 — EDR Daemon as Single Point of Failure — ✅ MITIGATED (kernel-side timeout)**
> Tiến trình bị QUARANTINED quá `EDR_QUARANTINE_TIMEOUT_TICKS` (120 ticks) mà daemon
> không xử lý sẽ bị force-release bởi `edr_quarantine_timeout_sweep()` trong kernel,
> tránh treo tài nguyên vĩnh viễn. Ngoài ra đã có `sys_unquarantine(pid)` (chỉ daemon
> gọi được) để release hành chính toàn bộ cây tiến trình.

**L4 — Threshold Empiricism — ✅ MITIGATED (adaptive threshold)**
> Cửa sổ phát hiện fork-rate được nới động theo **EMA của hoạt động fork toàn hệ thống**
> (`edr_fork_window()`): hệ thống bận legitimately → cửa sổ dài hơn → ít false-positive;
> hệ thống rảnh → cửa sổ cứng 10 ticks như thiết kế ban đầu.

## 5. Future Work

1. **Per-CPU Run Queues & NUMA Awareness**: Migrate from a single global proc table scan to per-CPU run queues with load balancing, reducing contention on `tickslock`/`edr_global_lock` at scale.
2. **Hardware-Rooted Attestation**: Replace the build-time HMAC whitelist with a TPM-backed key and measured boot, so the whitelist signature chain is anchored in hardware rather than a repo secret.
3. **External SIEM Streaming**: Forward the persistent `/edr.log` in real time to an external collector (e.g., syslog/ELK) for fleet-wide correlation.
