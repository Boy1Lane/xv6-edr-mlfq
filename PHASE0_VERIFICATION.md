# Báo cáo Phase 0: Xác minh môi trường

## 1. Đọc và hiểu `proposal.md`
- Đã đọc toàn bộ proposal và nắm vững các yêu cầu: cấu trúc `struct proc`, logic phát hiện (Tier-1, Tier-2), Deferred work với signal (`edr_work_pending`) và test-and-set lock (`edr_lock`), cùng với thay đổi tại `QUARANTINED`.

## 2. Xác minh bộ lập lịch MLFQ
- Đã kiểm tra và xác nhận sự tồn tại của MLFQ trong codebase. 
- Tại `kernel/param.h` có định nghĩa `MLFQ_LEVELS 3`, `QUANTUM_0`, `QUANTUM_1`, `QUANTUM_2`, và `AGING_INTERVAL`.
- Tại `kernel/proc.c` có vòng lặp duyệt qua các hàng đợi của MLFQ. Đủ điều kiện để tích hợp Anti-Scheduler-Gaming Tracker.

## 3. Cấu trúc hệ thống tệp và EDR Daemon Path
- Hệ thống hỗ trợ thư mục con (đã tìm thấy `user/mkdir.c`).
- Tuy nhiên, theo Makefile gốc, tất cả các chương trình user đều được `mkfs` đóng gói trực tiếp vào thư mục gốc (`/`). 
- **Quyết định:** Sẽ sử dụng `EDR_DAEMON_PATH = "/edr_daemon"` (vị trí gốc). Nếu trong quá trình tạo daemon cần đặt vào `/bin/`, sẽ cập nhật lại.

## 4. Xác nhận giá trị thực tế NPROC, NCPU
- Tại `kernel/param.h`:
  - `NPROC = 64`
  - `NCPU = 8`
- **Tính toán ngưỡng:**
  - `EDR_TREE_VOLUME_THRESHOLD = floor(NPROC / 4) = 16`.
  - Thiết kế mảng lưu 6 fork events (`EDR_FORK_SAMPLE = 6`), trong khoảng `EDR_FORK_RATE_WINDOW_TICKS = 10` (có thể điều chỉnh nếu thực tế tick qemu quá nhanh/chậm).

## 5. Chạy build và usertests
- Đang tiến hành build codebase nguyên bản trên WSL để đảm bảo biên dịch thành công (`make clean; make`).
- Sau khi xác nhận build thành công và chạy thử `usertests`, sẽ chính thức bắt đầu Phase 1.
