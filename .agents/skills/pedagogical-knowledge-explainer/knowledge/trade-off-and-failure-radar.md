# Kỹ Thuật Lập Ma Trận Đánh Đổi & Soi Lỗi Sập (Trade-Off & Failure Radar)

Tài liệu hướng dẫn dành cho AI Agent khi kích hoạt Pha 3 của chu trình sư phạm.

---

## 1. Nguyên Lý: "Không Có Giải Pháp Hoàn Hảo — Mọi Thứ Đều Là Đánh Đổi"

Một bài giảng công nghệ chỉ đạt chuẩn chuyên gia khi nó lột trần được **mặt tối (Dark Side)** của công nghệ đó. Nếu người học chỉ nghe thấy những lời tán dương (nhanh, xịn, scalable, hiện đại), họ sẽ áp dụng bừa bãi và dẫn đến thảm họa trong môi trường Production.

### Ma Trận Đánh Đổi 6 Trục (The 6-Axis Trade-Off Matrix)

Mọi quyết định kỹ thuật đều phải trả giá trên ít nhất một trong 6 trục sau:

1. **Hiệu Năng & Độ Trễ (Latency & Throughput)**: Nhanh hơn ở luồng đọc thì sẽ chậm hơn ở luồng ghi (ví dụ: đánh Index trong Database).
2. **Bộ Nhớ & Tài Nguyên (Memory & Disk Footprint)**: Giảm CPU bằng cách Cache dữ liệu trong RAM thì sẽ làm phình to bộ nhớ và rủi ro OOM (Out of Memory).
3. **Độ Phức Tạp Nhận Thức (Cognitive Complexity)**: Tách nhỏ microservices làm tăng tính độc lập nhưng biến việc debug và tracing thành cơn ác mộng.
4. **Tính Nhất Quán vs Tính Sẵn Sàng (Consistency vs Availability - CAP Theorem)**: Chấp nhận dữ liệu eventual consistent để đổi lấy hệ thống luôn phản hồi nhanh.
5. **Độ An Toàn & Ràng Buộc (Safety vs Flexibility)**: Ép kiểu tĩnh (Static Typing/Rust) ngăn ngừa runtime crash nhưng làm tăng thời gian biên dịch và cú pháp khắt khe.
6. **Chi Phí Vận Hành (Operational Cost & Maintenance)**: Sử dụng các dịch vụ Cloud Serverless tiện lợi lúc đầu nhưng chi phí bùng nổ khi quy mô tăng đột biến.

---

## 2. Kỹ Thuật Mổ Xẻ Kịch Bản Sập (Catastrophic Failure Modes)

Bài giảng bắt buộc phải chỉ ra tối thiểu **2 kịch bản sập nguồn nghiêm trọng nhất**:

### Mẫu Trình Bày Kịch Bản Sập (Failure Blueprint)

```markdown
### Kịch Bản Sập 1: [Tên kịch bản ngắn gọn, ví dụ: Connection Pool Exhaustion]
- **Điều kiện kích hoạt**: Khi tải tăng đột biến vượt ngưỡng X, hoặc API bên thứ ba phản hồi chậm > 5 giây.
- **Cơ chế gãy ngầm**: Các thread giữ kết nối chờ đợi, không trả về pool; hàng đợi (queue) bị tràn; bộ nhớ tăng vọt làm kích hoạt Linux OOM Killer.
- **Hành vi quan sát được**: Ứng dụng đột ngột biến mất (crash exit 137), toàn bộ người dùng nhận lỗi HTTP 502/504.
- **Biện pháp phòng vệ (Remedy)**: Thiết lập Timeout nghiêm ngặt, cơ chế Circuit Breaker, và Exponential Backoff with Jitter.
```

---

## 3. Không Gian Phủ Định (Negative Space — Anti-Patterns)

Mỗi công nghệ phải có một danh sách rõ ràng: **"Khi nào TUYỆT ĐỐI CẤM sử dụng công nghệ này?"**.

Ví dụ:
- **Redis**: CẤM dùng làm cơ sở dữ liệu lưu trữ chính cho giao dịch tài chính nếu không cấu hình AOF fsync=always (chấp nhận hy sinh tốc độ).
- **Microservices**: CẤM áp dụng cho startup 2 người đang tìm kiếm Product-Market Fit vì chi phí giao tiếp hạ tầng sẽ giết chết tốc độ phát triển sản phẩm.
- **Headless Mode trong Agent**: CẤM đặt ở bước đầu của tư duy vì sẽ làm AI bị đông cứng nhận thức, chỉ dùng làm chốt chặn kiểm duyệt ở điểm cuối.
