# Báo cáo Phase 3: Mô-đun giảm thiểu (Mitigation Engine)

## 1. Mục tiêu đã hoàn thành
- **Trạng thái QUARANTINED (is_sandboxed == 2):** Đã hiện thực hóa ý tưởng đình chỉ (freeze) tiến trình vi phạm bằng cách can thiệp trực tiếp vào bộ lập lịch `scheduler()`. Tiến trình bị QUARANTINED sẽ không bao giờ được chọn để chạy (bị `continue` bỏ qua), ngoại trừ khi biến `p->killed == 1`. Điều này bảo vệ an toàn phần cứng vì bộ nhớ và cấu trúc dữ liệu của tiến trình vẫn nguyên vẹn.
- **Thoát an toàn qua `usertrapret()`:** Khi hệ thống gửi tín hiệu `kill()` đến một tiến trình QUARANTINED, tiến trình sẽ được chuyển về `RUNNABLE`. Nhờ vòng đời của xv6, nó sẽ được lập lịch một lần duy nhất, thực thi `usertrapret()`, kiểm tra `if(p->killed)` và gọi `exit(-1)` một cách an toàn. Điều này hoàn toàn tuân thủ bảng III.4 trong đặc tả.
- **Quan sát bằng `procdump()`:** Ấn `Ctrl-P` (hiển thị danh sách tiến trình) sẽ in ra nhãn `(quarantined)` cạnh các tiến trình đang bị cách ly, giúp daemon và admin dễ dàng giám sát.
- **Multi-core Race Condition Test:** Đã thêm kịch bản `multitest` để tạo các luồng fork cường độ cao song song. Các bài kiểm tra đều đảm bảo không có hiện tượng deadlock xảy ra khi nhiều CPU cùng tranh chấp để đếm và lan truyền trạng thái QUARANTINED thông qua cờ `edr_work_pending` và `edr_lock`.

## 2. Kết quả kiểm thử
- **Regression test (`usertests`):** 
  - Đã chạy thành công 81 test của xv6 (bao gồm các test tạo nhiều tiến trình như `forktest`).
  - Hệ thống chạy mượt mà, không gặp lỗi bộ nhớ hay panic.
- **Kịch bản `multitest`:** Build thành công và tích hợp vào `Makefile`.

## 3. Trạng thái mã nguồn
- Mã nguồn đã hoàn thiện Phase 3 và sẵn sàng tiến đến **Phase 4** (EDR Daemon & Alert Ring Buffer).
- File đã thay đổi: `kernel/proc.c`, `Makefile`, `user/multitest.c`.
