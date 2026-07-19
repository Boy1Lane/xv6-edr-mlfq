# xv6 Mini-EDR & MLFQ Scheduler - Design Document

## 1. Threat Model & Architecture
### Threat Model
Hệ thống xv6 Mini-EDR được thiết kế để bảo vệ hệ điều hành khỏi các tiến trình độc hại (malicious processes) ở mức user-space. Các mối đe dọa chính bao gồm:
- **Fork Bomb (Từ chối dịch vụ - DoS):** Một tiến trình liên tục gọi `fork()` để làm cạn kiệt tài nguyên PID và bộ nhớ của hệ thống, khiến các tiến trình hợp lệ không thể chạy được.
- **CPU Starvation:** Các tiến trình độc hại hoặc tính toán nặng (CPU-bound) chiếm dụng toàn bộ thời gian CPU, làm cho các tiến trình tương tác (I/O-bound) không thể phản hồi.
- **Evasion & Gaming:** Các tiến trình cố gắng qua mặt bộ định thời bằng cách nhường CPU (yield) ngay trước khi hết quantum để giữ mức ưu tiên cao, hoặc cố tình che giấu hành vi rẽ nhánh (fork) thông qua mô hình phân cấp phức tạp (Process Tree).

### Architecture
- **In-kernel Telemetry:** Kernel thu thập dữ liệu về tần suất `fork` và cấu trúc cây tiến trình (`tree volume`). Nếu vi phạm các ngưỡng đã định sẵn (`EDR_FORK_LIMIT`, `EDR_TREE_LIMIT`), tiến trình sẽ bị đưa vào khu vực cách ly (Quarantine).
- **EDR Daemon (User-space):** Thay vì xử lý logic bảo mật phức tạp trong kernel, xv6 Mini-EDR xuất các cảnh báo an ninh (Security Alerts) ra không gian người dùng thông qua system call `sys_get_security_alerts`. `edr_daemon` (chạy với cờ `edr_trusted`) đóng vai trò nhận các cảnh báo này, log ra màn hình và tiêu diệt (kill) các tiến trình vi phạm.
- **MLFQ Scheduler:** Bộ định thời đa hàng đợi phản hồi (Multi-Level Feedback Queue) quản lý tài nguyên CPU. Các tiến trình bị Quarantine sẽ bị giam ở hàng đợi thấp nhất. MLFQ tích hợp tính năng Anti-Gaming (ngăn chặn gian lận bằng cách tính tổng `total_runtime`) và Priority Boost (nâng ưu tiên định kỳ để tránh đói CPU).

## 2. Data Structures
Các cấu trúc dữ liệu cốt lõi phục vụ bảo mật và giám sát:

- **`struct alert_entry` (kernel/types.h):**
  Lưu trữ thông tin chi tiết về tiến trình vi phạm, bao gồm: `pid`, `parent_pid`, `reason` (mã lỗi), `reason_str` (chuỗi giải thích lý do), `tick` (thời điểm vi phạm), và `name` (tên tiến trình).
- **`alerts[EDR_MAX_ALERTS]` (Ring Buffer):**
  Bộ đệm vòng nằm trong không gian kernel (proc.c) lưu trữ các cảnh báo EDR. Truy cập được bảo vệ bởi spinlock `alert_lock`. Biến `alerts_dropped` theo dõi số lượng cảnh báo bị loại bỏ do tràn bộ đệm.
- **`edr_reason_t` (kernel/proc.h):**
  Enum chuẩn hoá các lý do Quarantine: `EDR_REASON_NONE`, `EDR_REASON_FORK_RATE`, `EDR_REASON_TREE_VOLUME`.
- **`struct proc` extensions (kernel/proc.h):**
  Các trường bổ sung phục vụ Telemetry và định thời:
  - `priority`, `ticks_in_queue`, `total_runtime`: Quản lý MLFQ.
  - `quarantine_tick`, `fork_count`, `last_fork_tick`: Quản lý EDR.
- **`struct p_info` (kernel/pstat.h):**
  Export trạng thái nội bộ (`total_runtime`, `is_sandboxed`, `priority`) ra user-space phục vụ cho công cụ giám sát `ps_monitor`.

## 3. Justifications (Lựa chọn Thiết Kế)
- **Zero-Trust for Processes:**
  Kernel mặc định coi mọi tiến trình là không đáng tin cậy. `edr_daemon` là tiến trình duy nhất được cấp cờ `edr_trusted` trong quá trình phân bổ PID đầu tiên. Điều này ngăn chặn tiến trình độc hại đọc trộm cảnh báo EDR.
- **Locking & Deadlock Avoidance:**
  Sử dụng `alert_lock` độc lập để bảo vệ Ring Buffer. Hàm `edr_push_alert` có thể được gọi ngay cả khi đang giữ `wait_lock` mà không gây ra vi phạm phân cấp khóa (Lock Hierarchy) hay tình trạng Deadlock.
- **Ring Buffer for Telemetry:**
  Sử dụng Ring Buffer giúp Kernel duy trì hiệu năng cao khi đẩy alerts và chống lại tình trạng đầy bộ nhớ do Flood Alerts.
- **DRY Refactoring (mlfq_tick):**
  Toàn bộ logic tính toán hết hạn Quantum và System Aging được đóng gói trong hàm `mlfq_tick()`, tái sử dụng chung cho `kerneltrap` và `usertrap`, đảm bảo độ ổn định và khả năng bảo trì.

## 4. Experimental Results

### 4.1 Benchmark: MLFQ vs Round Robin

| Metric | MLFQ | Round Robin | Observation |
|---|---|---|---|
| CPU-bound throughput (4 workers) | ~52 ticks | ~48 ticks | ~8% overhead |
| Interactive response (sleep(2)×10) | ~2 ticks/iter | ~4 ticks/iter | 2× improvement |

**Interpretation**: MLFQ incurs a small overhead (~8%) for CPU-bound workloads due to 
priority-queue bookkeeping, but significantly improves interactive responsiveness (2×).
This is the expected trade-off for a multi-level scheduler.

### 4.2 Security Detection Test Results

| Test Case | Expected | Actual | Pass? |
|---|---|---|---|
| Fork bomb (multitest, 8 forks/10ticks) | Alert + Quarantine | Alert raised in <15 ticks | ✅ |
| Legitimate I/O workload (stressfs) | No alert | No alert triggered | ✅ |
| Whitelisted process (usertests) | No quarantine | Ran to completion | ✅ |

### 4.3 Known Limitations

**L1 — Path-based Whitelist (High Risk)**
> Current whitelist matches by filename, not binary hash. An attacker can rename `/multitest`
> to `/sh` to bypass detection. Mitigation: binary signature verification at exec-time (out of scope).

**L2 — Single-CPU Concurrency Assumption (Medium Risk)**  
> `clockintr()` accesses PCB fields without p->lock. Safe for xv6's default single-CPU QEMU
> configuration (`-smp 1`). On multi-core, atomic operations would be needed for `is_sandboxed`.

**L3 — EDR Daemon as Single Point of Failure (Low Risk)**
> If `edr_daemon` is killed, quarantined processes remain suspended indefinitely.
> Mitigation: kernel-side quarantine timeout (not implemented).

**L4 — Threshold Empiricism**
> The 6-fork-per-10-tick threshold was derived from analysis of xv6's workload patterns,
> not from formal statistical modeling. May require tuning for different workload profiles.

## 5. Future Work

1. **Binary Integrity Verification**: Replace path-based whitelist with SHA-256 hash matching at exec-time to prevent whitelist bypass via rename.
2. **Adaptive Threshold**: Dynamically adjust fork-rate threshold based on observed system load, reducing false positives under high-activity workloads.
3. **Multi-CPU Safety**: Audit all lock-free PCB accesses in `clockintr()` and replace with `__sync_fetch_and_or()` / `__sync_fetch_and_and()` primitives.
4. **Unquarantine API**: Add `sys_unquarantine(pid)` syscall callable only by `edr_trusted` processes, enabling administrative release.
5. **Persistent Alert Log**: Write alerts to a file system log for post-mortem forensic analysis.
