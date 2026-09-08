# Bảng Kiểm Duyệt Chất Lượng Sư Phạm (Pedagogical Quality Checklist)

Bảng tiêu chí thẩm định chất lượng bài giảng công nghệ chiều sâu. Sử dụng bởi Headless State Gate và AI Agent trước khi bàn giao.

---

## 1. Cổng Tiêu Chí 1: Nguyên Lý Đầu Tiên (First Principles Gate)
- [ ] **Bối cảnh lịch sử**: Đã giải thích rõ bài toán bế tắc/nỗi đau trong quá khứ trước khi công nghệ này xuất hiện chưa?
- [ ] **Quy về vật lý**: Đã giải thích được công nghệ tác động thế nào đến CPU, RAM, I/O hoặc Network chưa?
- [ ] **Zero Dictionary Definition**: Không mở đầu bằng câu định nghĩa hàn lâm suông trích từ tài liệu kỹ thuật.

---

## 2. Cổng Tiêu Chí 2: Cơ Chế Vận Hành Ngầm (Mechanics Gate)
- [ ] **Sơ đồ trực quan**: Có ít nhất 1 sơ đồ Mermaid (flowchart hoặc sequenceDiagram) mô tả luồng vận hành ngầm.
- [ ] **Chi tiết cấp thấp**: Chỉ rõ ai đang thực thi (Thread, Event Loop, Process, OS Kernel) và dữ liệu biến đổi ở đâu.
- [ ] **Zero-Placeholder**: Toàn bộ mã nguồn minh họa là code chạy thật, không có `TODO`, không có hàm rỗng.

---

## 3. Cổng Tiêu Chí 3: Đánh Đổi & Phản Diện Kỹ Thuật (Trade-Off & Failure Gate)
- [ ] **Ma trận đánh đổi**: Có bảng so sánh rõ ràng cái được và cái mất trên các trục độ trễ, bộ nhớ, độ phức tạp.
- [ ] **Không gian phủ định (Negative Space)**: Nêu rõ tối thiểu 2 trường hợp TUYỆT ĐỐI CẤM DÙNG công nghệ này.
- [ ] **Kịch bản sập nguồn (Failure Modes)**: Phân tích chi tiết tối thiểu 2 kịch bản hệ thống bị gãy/rò rỉ khi dùng sai.

---

## 4. Cổng Tiêu Chí 4: Kích Hoạt Tư Duy Socratic (Pedagogy & Probe Gate)
- [ ] **Câu hỏi phản biện**: Có 1-2 câu hỏi thách đố hoặc 1 bài tập tình huống biên để người học tự suy ngẫm.
- [ ] **Chống tiếp nhận thụ động**: Bài giảng tạo cảm giác đối thoại và thử thách trí tuệ, không thuyết giảng một chiều.

---

## 5. Đánh Giá Đầu Ra (Verdict Format)
- **Tổng số vấn đề phát hiện (`total_issues_count`)**: Phải bằng `0` để vượt qua cổng kiểm duyệt.
- Nếu `> 0`: Mỗi lỗi phải đi kèm `phase`, `severity` (CRITICAL / MAJOR / MINOR), `issue_description` và `actionable_fix`.
