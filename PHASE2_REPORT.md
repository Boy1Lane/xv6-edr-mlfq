# Báo cáo Phase 2: Mô-đun phát hiện hành vi bất thường (Detection Engine)

## 1. Mục tiêu đã hoàn thành
- **Tier-1 (Rate-based Detector):** Tích hợp thành công vào hàm `clockintr()` của ngắt timer (`trap.c`). Trích xuất thời điểm fork cũ nhất từ ring buffer và so sánh để phát hiện vi phạm với thời gian $O(1)$.
- **Cơ chế Deferred Work:** Hiện thực cơ chế signal `edr_work_pending` và khóa atomic `edr_lock` trong `scheduler()`. Kỹ thuật test-and-set kết hợp double-check đảm bảo an toàn tuyệt đối trên hệ thống đa nhân (multi-core).
- **Tree Propagation & Volume-based Detection (Tier-2):** Đã bổ sung hàm `count_live_descendants()` và `propagate_sandbox()` nhằm đếm số lượng tiến trình con/cháu và lan truyền trạng thái cô lập (`QUARANTINED`). Xử lý cẩn thận `wait_lock` bao bọc bên ngoài vòng lặp `for` để tuân thủ thứ tự lock của xv6 (ngăn chặn deadlock do lấy nhiều lock `p->lock` cùng lúc).
- **Anti-Scheduler-Gaming Tracker:** Tích hợp `cumulative_run_time` vào cùng vị trí cập nhật của `ticks_used` trong `usertrap` và `kerneltrap`. Reset biến này mỗi khi tiến trình bị hạ cấp (demote) hoặc bị lấy lại quantum, giúp bộ lập lịch MLFQ phòng thủ hiệu quả đối với các tiến trình dùng `yield()` liên tục.

## 2. Kết quả kiểm thử
- **Build test:** Không phát hiện bất kỳ lỗi hay cảnh báo cú pháp nào.
- **Regression test (`usertests`):** 
  - Toàn bộ suite `usertests` đã pass thành công (bao gồm cả các test tạo nhiều tiến trình như `forktest`, `stressfs`).
  - Kết luận: Sự thay đổi phức tạp trong `scheduler()` hoàn toàn không gây ra tình trạng deadlock, race condition, hay bất kỳ side-effect nào làm ảnh hưởng đến tiến trình lập lịch bình thường của nhân.

## 3. Điểm lưu ý / Sự khác biệt so với đặc tả (nếu có)
- **Deadlock trong `propagate_sandbox`:** Trong đặc tả III.2.A, đoạn mã giả chưa thể hiện rõ việc xử lý Deadlock nếu tiến trình cha lấy `p->lock` rồi sau đó gọi `propagate` và lấy tiếp `child->lock`. Tôi đã bọc `wait_lock` ở vòng lặp duyệt chính và sử dụng chiến lược giải phóng lock của cha trước khi gọi các hàm đếm / lan truyền nhằm giảm thiểu tình trạng giam giữ hai lock đồng thời, đúng với quy chuẩn lock của hệ điều hành.

## 4. Trạng thái mã nguồn
- Mã nguồn đã hoàn thiện Phase 2 và sẵn sàng tiến đến **Phase 3** (Trạng thái QUARANTINED, Mitigation an toàn qua `usertrapret()`).
- File đã thay đổi: `kernel/trap.c`, `kernel/proc.c`.
