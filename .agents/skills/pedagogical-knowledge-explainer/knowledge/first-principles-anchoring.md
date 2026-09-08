# Kỹ Thuật Neo Đậu Nguyên Lý Đầu Tiên (First Principles Anchoring Guide)

Tài liệu hướng dẫn dành cho AI Agent khi kích hoạt Pha 1 của chu trình sư phạm.

---

## 1. Bản Chất Của "First Principles Thinking" Trong Giảng Dạy Công Nghệ

Hầu hết mọi người thất bại trong việc hiểu sâu một công nghệ vì họ tiếp cận theo **Suy luận loại suy (Reasoning by Analogy)**: "Công nghệ X giống như Y nhưng nhanh hơn". Cách học này khiến kiến thức nông cạn và dễ gãy khi gặp tình huống biên (Edge Cases).

Nguyên lý đầu tiên đòi hỏi bóc tách mọi công nghệ phức tạp về các sự thật nền tảng không thể chia nhỏ hơn:
1. **Dữ liệu được lưu ở đâu?** (Thanh ghi CPU, Bộ nhớ RAM, SSD/Disk, hay qua Mạng Network).
2. **Ai đang làm việc?** (Process, Thread, Event Loop, hay Kernel Interrupt).
3. **Chi phí vật lý là gì?** (Chu kỳ CPU, Băng thông I/O, Cache Miss, Context Switching).

---

## 2. Kỹ Thuật Truy Vấn Nguồn Gốc Lịch Sử (The Historical Pain-Point Probe)

Mọi thư viện, giao thức, kiến trúc hoặc công cụ phần mềm đều sinh ra để giải quyết một **nỗi đau lịch sử cụ thể**. Nếu không hiểu nỗi đau đó, người học sẽ coi công nghệ như một "gánh nặng cú pháp" thay vì một "giải pháp cứu cánh".

### Bảng Ánh Xạ Ví Dụ Kinh Điển

| Công Nghệ Hiện Đại | Nỗi Đau Lịch Sử Trước Khi Nó Ra Đời | Nguyên Lý Vật Lý Cốt Lõi |
| :--- | :--- | :--- |
| **Virtual DOM (React)** | Thao tác trực tiếp trên Real DOM của trình duyệt gây reflow/repaint liên tục, cực kỳ tốn chi phí CPU/GPU render. | Giữ một cây JavaScript object thuần túy trong RAM (rất rẻ), tính toán thuật toán Diff (O(n)), rồi chỉ batch update đúng các node thay đổi lên Real DOM 1 lần. |
| **Async/Await (I/O)** | Blocking I/O khiến Thread hệ điều hành bị treo (Sleeping), tiêu tốn 1MB stack memory mỗi thread; Callback Hell gây rối loạn luồng điều khiển. | Trả lại Thread cho Event Loop trong lúc chờ đợi I/O phần cứng (DMA/Socket); khi có dữ liệu thì OS Kernel gửi ngắt (Interrupt) để đánh thức callback tiếp tục. |
| **Docker / Containers** | "Chạy được trên máy tôi nhưng lỗi trên server" do xung đột thư viện động (`.so`, `.dll`), biến môi trường và kernel module. | Sử dụng Linux Namespaces (cô lập tầm nhìn: PID, Mount, Net) và Cgroups (giới hạn tài nguyên: CPU, RAM) để đóng gói không gian chạy độc lập trên cùng 1 OS Kernel. |
| **Agent Skill (Antigravity)**| Prompt bị nhồi nhét hàng ngàn dòng vào System context gây Context Fog, tốn tiền token và làm suy giảm khả năng suy luận của LLM. | Progressive Disclosure: Chỉ nạp Name + Description (~50 words) vào bộ nhớ thường trực; chỉ khi có lệnh khớp mới đọc toàn bộ file `SKILL.md` theo nhu cầu (On-Demand). |

---

## 3. Công Thức 3 Bước Triển Khai Pha 1

Khi mở đầu một bài giảng, Agent áp dụng công thức 3 bước sau:

```
[BƯỚC 1: ĐẶT BÀI TOÁN GỐC]
"Hãy tưởng tượng vào năm [Năm/Thời kỳ], khi bạn phải giải quyết bài toán [X] chỉ bằng công cụ nguyên thủy [Y]..."

[BƯỚC 2: MÔ TẢ NÚT THẮT BẾ TẮC]
"Hệ thống sẽ bị sập hoặc nghẽn cổ chai tại điểm [Z] vì giới hạn vật lý của [CPU/RAM/I/O]..."

[BƯỚC 3: SỰ XUẤT HIỆN TẤT YẾU CỦA CÔNG NGHỆ]
"Đó chính là lý do [Tên công nghệ] ra đời. Bản chất của nó không có phép thuật, mà chỉ đơn giản là cơ chế [Giải thích cơ chế cốt lõi trong 1 câu ngắn gọn]."
```

---

## 4. Những Lỗi Cấm Kỵ (Anti-Patterns Cần Tránh)
- ❌ **Định nghĩa hàn lâm ngay dòng đầu**: *"Kubernetes là một nền tảng mã nguồn mở tự động hóa việc triển khai, mở rộng và quản lý các ứng dụng container hóa..."* (Người học lập tức mất hứng thú).
- ❌ **Lạm dụng thuật ngữ không giải thích**: Dùng các từ như "idempotent", "polymorphism", "ephemeral", "amortized" mà không gắn với hành vi thực tế.
