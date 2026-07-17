# Báo cáo Phase 1: Thu thập dữ liệu (Telemetry) & Hooking

## 1. Mục tiêu đã hoàn thành
- **Mở rộng `struct proc`:** Đã thêm các trường cần thiết theo đặc tả vào `kernel/proc.h` để lưu trữ dữ liệu an ninh (ring buffer `fork_times`, cờ `is_sandboxed`, thời điểm bị cô lập `quarantine_tick`, v.v.).
- **Khởi tạo trạng thái:** Đã điều chỉnh `allocproc()` và `freeproc()` trong `kernel/proc.c` để đảm bảo các trường của tiến trình được làm sạch hoàn toàn khi tạo mới hoặc giải phóng.
- **Hook `sys_fork()`:** Đã can thiệp vào `kernel/sysproc.c` để khi một tiến trình fork thành công, nó sẽ cập nhật mảng `fork_times` của chính nó với thời gian hiện tại (`ticks`). Trong quá trình này, lock `tickslock` và `p->lock` được sử dụng rất ngắn và an toàn, tránh deadlock.
- **Cấu hình tham số:** Bổ sung các hằng số liên quan đến EDR (`EDR_FORK_SAMPLE`, `EDR_TREE_VOLUME_THRESHOLD`, ...) vào `kernel/param.h` theo kết quả Phase 0.

## 2. Kết quả kiểm thử
- **Build test:** Không phát hiện bất kỳ lỗi hay cảnh báo cú pháp nào. Hệ điều hành chạy bình thường.
- **Regression test (`usertests`):** 
  - Đã thiết lập script chạy toàn bộ suite usertests trên xv6 qemu.
  - Kết quả: `ALL TESTS PASSED`
  - Kết luận: Việc thêm trường và sử dụng lock trong `sys_fork()` đã được thiết kế đúng chuẩn xv6, không phá vỡ logic sẵn có của kernel hay gây memory corruption.

## 3. Điểm lưu ý / Sự khác biệt so với đặc tả (nếu có)
- Thay vì lấy khóa của tiến trình con sau khi fork, hook được thực hiện gọn gàng bên trong `sys_fork()` chỉ bằng việc khoá tiến trình cha (`myproc()`) do mảng `fork_times` chỉ thuộc về tiến trình gọi fork. Điều này đáp ứng được yêu cầu về hiệu năng và hạn chế được lỗi "đảo thứ tự lock PID" mà không cần phải so sánh PID.
- Biến `ticks` được đọc một cách an toàn thông qua việc acquire `tickslock` trước khi acquire `p->lock` để tuân thủ phân cấp lock của xv6.

## 4. Trạng thái mã nguồn
- Mã nguồn đã sẵn sàng cho [Phase 2] Detection Engine (Tier-1, Tier-2 & Deferred Work).
- File đã thay đổi: `param.h`, `proc.h`, `proc.c`, `sysproc.c`.
