# Nghệ Thuật Đặt Câu Hỏi Socratic (Socratic Questioning Patterns)

Tài liệu hướng dẫn dành cho AI Agent khi kích hoạt Pha 4 của chu trình sư phạm.

---

## 1. Bản Chất Của Phương Pháp Socratic Trong Huấn Luyện AI

Socratic Method không phải là việc hỏi han xã giao ("Bạn đã hiểu chưa?"), mà là **kỹ thuật gài bẫy tư duy tích cực**. Bằng cách đặt ra những câu hỏi phản biện sắc bén nhắm vào những điểm mù nhận thức (Cognitive Blindspots), người học buộc phải tự mình xâu chuỗi các mảnh ghép logic để đưa ra câu trả lời.

Khi tự mình giải được câu đố, não bộ người học sẽ hình thành các liên kết thần kinh sâu (Deep Synaptic Anchoring), giúp họ nhớ và áp dụng kiến thức lâu dài hơn nhiều so với việc chỉ nghe giảng một chiều.

---

## 2. Các Mẫu Câu Hỏi Socratic Phổ Biến

### Mẫu 1: Câu Hỏi Tình Huống Biên & Tải Đột Biến (Stress & Edge-Case Probe)
- *"Nếu bảng dữ liệu này tăng từ 10.000 dòng lên 100.000.000 dòng, câu truy vấn bạn vừa viết sẽ gặp nút thắt vật lý nào trước tiên?"*
- *"Chuyện gì xảy ra nếu 1.000 người dùng cùng nhấn nút này trong đúng 1 phần nghìn giây?"*

### Mẫu 2: Câu Hỏi Truy Vấn Ngược & Lựa Chọn Đánh Đổi (Reverse Trade-off Probe)
- *"Tại sao tác giả của kiến trúc này lại chấp nhận hy sinh [Độ nhất quán dữ liệu] để đổi lấy [Tính sẵn sàng cao]? Trong trường hợp nào thì sự đánh đổi này trở thành một sai lầm chết người?"*
- *"Nếu bạn là Tech Lead của một ngân hàng, bạn có dám sử dụng giải pháp này cho luồng chuyển tiền không? Tại sao?"*

### Mẫu 3: Câu Hỏi Tìm Lỗi Ngụy Biện (Cognitive Fallacy Exposer)
- *"Nhiều người nói: 'Cứ dùng NoSQL là hệ thống sẽ tự động nhanh hơn SQL'. Theo bạn, phát biểu này sai ở những điểm cốt tử nào khi xét về thuật toán chỉ mục B-Tree vs LSM-Tree?"*

---

## 3. Quy Trình 3 Bước Triển Khai Pha 4 Trong Bài Giảng

1. **Tóm tắt 1 dòng chốt hạ**: Đúc kết linh hồn của bài học trong 1 câu ngắn gọn.
2. **Giao thử thách tư duy (The Challenge)**: Đặt ra đúng **1 câu hỏi Socratic sâu sắc** hoặc **1 bài tập tình huống biên cụ thể**.
3. **Mời người học phản biện**: Khuyến khích người học đưa ra giả thuyết và cam kết cùng người học phân tích tiếp nếu họ trả lời.
