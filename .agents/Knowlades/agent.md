# Tài liệu Kiến thức: Agent & Subagent trong Antigravity CLI

## 1. Tổng quan Kiến trúc (Overview & Execution Model)
Antigravity CLI áp dụng **Mô hình Thực thi Bất đồng bộ Đa luồng (Multi-threaded Asynchronous Execution Architecture)** nhằm tối đa hóa tốc độ và hiệu suất lập trình của nhà phát triển. 

Thay vì làm khóa (lock) phiên terminal trong khi chờ thực hiện các tác vụ tốn thời gian (như build ứng dụng, chạy kiểm thử suite, tìm kiếm trên codebase lớn hoặc chỉnh sửa nhiều file phức tạp), **Primary Agent** sẽ tự động ủy quyền (delegate) các tác vụ này cho các **Subagent** hoặc **Background Tasks** chạy song song.

Nhờ mô hình này, nhà phát triển có thể tiếp tục soạn thảo mã nguồn, gửi prompt mới hoặc kiểm tra các file khác trong khi nhiều luồng agent độc lập đang xác thực và xử lý ngầm.

---

## 2. Lệnh Quản lý Agent (`/agents` Command & Panel)

Bảng **Agent Manager Panel** được kích hoạt bằng lệnh `/agents`. Bảng điều khiển tương tác này phục vụ 2 mục đích chính:

1. **Khám phá & Chọn Agent Tùy chỉnh (Custom Agent Selection & Discovery)**:
   - Cho phép chọn giữa Agent mặc định (Default Agent) và các Custom Agents chuyên biệt theo quy trình làm việc.
   - Tự động phát hiện các định nghĩa Agent được tạo ở phạm vi Local (Workspace) và Global.

2. **Theo dõi & Điều khiển Subagent Ngầm (Subagent Monitoring & Control)**:
   - Theo dõi tiến độ, kiểm tra nhật ký suy nghĩ chi tiết hoặc hủy các Subagent đang chạy song song trong phiên làm việc.

```bash
/agents
```

### Cơ chế Fork khi Chuyển đổi Agent
- Nếu bạn chuyển đổi Custom Agent trong khi đang ở một **phiên hội thoại hoạt động (active session)**, CLI sẽ tự động **fork** phiên hiện tại (`[ Switch will fork the current conversation on exit ]`) để bảo toàn tính toàn vẹn của lịch sử hội thoại.
- Nếu thực hiện chuyển đổi ở **phiên mới (fresh session)**, sự thay đổi sẽ áp dụng trực tiếp (`[ Switch will create a new conversation on exit ]`).

---

## 3. Tạo & Định nghĩa Custom Agent (Custom Agent Definitions)

Antigravity CLI quét và nạp các Custom Agent có hướng dẫn hệ thống (system prompt) và phân quyền công cụ riêng biệt.

### Cấu trúc Thư mục Định nghĩa Agent
Các file định nghĩa Custom Agent **bắt buộc phải nằm trong thư mục con riêng mang tên agent đó**:

- **Phạm vi Dự án (Workspace-scoped)**:
  `{workspace}/.agents/agents/{agent_name}/agent.md`
- **Phạm vi Toàn cục (Global-scoped)**:
  `~/.gemini/config/agents/{agent_name}/agent.md`
- **Đóng gói trong Plugins**: Có thể phân phối đi kèm theo các Plugin.

### Ví dụ Tạo Custom Agent
Tạo một agent kiểm thử mã nguồn (`code-reviewer`):

```bash
mkdir -p ~/.gemini/config/agents/code-reviewer
cat << 'EOF' > ~/.gemini/config/agents/code-reviewer/agent.md
---
name: code-reviewer
description: Chuyên gia kiểm thử mã nguồn, tập trung vào edge cases và bảo mật.
---
Bạn là một chuyên gia code reviewer. Hãy phân tích các đoạn diff cẩn thận và kiểm tra các trường hợp biên.
EOF
```

Khi mở lại bảng `/agents`, CLI sẽ tự động khám phá và hiển thị `code-reviewer` trong danh sách **Available Agents**.

---

## 4. Theo dõi & Kiểm soát Subagent (Monitoring & Subagent Control)

Các tiến trình Subagent được ủy quyền sẽ xuất hiện trong bảng `/agents` dưới mục **Subagents**, được nhóm theo Prompt kích hoạt.

### 1. Trạng thái Lifecycle của Subagent
- `running`: Dang tích cực suy nghĩ hoặc thực thi công cụ (chỉ báo hình tròn xanh `●`).
- `done`: Đã hoàn thành xuất sắc tác vụ ngầm được giao.
- `error`: Gặp lỗi dừng tiến trình trong quá trình thực thi.
- `killed`: Đã bị người dùng hoặc tiến trình cha hủy thủ công.

### 2. Xem chi tiết suy nghĩ của Subagent (Subagent Detail View)
- Dùng phím `↑` / `↓` để chọn dòng Subagent mong muốn và nhấn `Enter`.
- Giao diện **Subagent Detail View** toàn màn hình sẽ mở ra, hiển thị toàn bộ luồng suy nghĩ nội bộ (internal thoughts), các lời gọi công cụ (tool calls) và đầu ra `stdout`.
- Nhấn `Esc` để quay lại danh sách chính.

### 3. Hủy Subagent đang chạy
- Chọn hàng Subagent đang ở trạng thái `running`.
- Nhấn phím `k` để hủy ngay lập tức (`CancelSubagent`) Subagent đó cùng tất cả các luồng con của nó.

### 4. Duyệt quyền bảo mật trực tiếp (Inline Tool Approvals)
Khi Subagent cố gắng thực thi một thao tác bảo vệ (ghi file hoặc chạy lệnh shell), bạn có thể:
- Nhấn `a` để phê duyệt (Approve).
- Nhấn `d` để từ chối (Deny) ngay từ giao diện danh sách.

---

## 5. Phím tắt Phím nóng & Trải nghiệm Lập trình (Keyboard Ergonomics)

Antigravity CLI cung cấp các lối tắt bàn phím tốc độ cao để duyệt quyền hoặc di chuyển giữa các luồng làm việc mà không làm gián đoạn luồng suy nghĩ của lập trình viên:

### Điều hướng "Teleport" (`Alt+J`)
Khi có Subagent cần chờ duyệt quyền, thanh trạng thái sẽ nhấp nháy thông báo.
- Nhấn **`Alt+J`** tại ô nhập prompt chính để "dịch chuyển" (teleport) tức thì vào giao diện **Detail View** của Subagent đang chờ duyệt.
- Xác nhận hoặc từ chối thao tác, sau đó nhấn **`Esc`** để "teleport" quay lại luồng hội thoại chính.

### Phê duyệt Nhanh "Fast-Path" (`Ctrl+K`)
- Quan sát thông báo nổi ngay trên ô nhập prompt (ví dụ: `Subagent 12 asks to run "npm test"`).
- Nhấn **`Ctrl+K`** để duyệt nhanh ngay lập tức mà không cần mở bảng overlay hay di chuyển con trỏ.

### Bảng Phím tắt trong Panel `/agents`

| Phím | Hành động | Mô tả hành vi |
| :--- | :--- | :--- |
| `↑` / `↓` | Điều hướng | Di chuyển con trỏ giữa các danh mục, Subagent và Agent có sẵn. |
| `Enter` | Chọn / Bật mở | Thu gọn/mở rộng nhóm, mở Subagent Detail View, hoặc chọn Custom Agent. |
| `k` | Hủy Subagent | Hủy khẩn cấp tiến trình Subagent đang chạy (`running`). |
| `a` / `d` | Phê duyệt / Từ chối | Phê duyệt (`Approve`) hoặc Từ chối (`Deny`) yêu cầu cấp quyền ngay tại dòng Subagent. |
| `Esc` | Quay lại | Thoát bảng điều khiển, áp dụng Agent đã chọn và trở lại ô nhập prompt. |

---

## 6. Phân biệt Subagents và Background Tasks (`/tasks`)

| Tính chất | Subagents (`/agents`) | Background Tasks (`/tasks`) |
| :--- | :--- | :--- |
| **Bản chất** | Chuỗi xử lý AI độc lập có khả năng tự suy nghĩ, gọi công cụ nhiều bước. | Tiến trình lệnh đơn shell CLI, câu lệnh kiểm thử, hoặc lệnh ngầm `/btw`. |
| **Theo dõi** | Xem luồng suy nghĩ chi tiết, tool call log qua `Subagent Detail View`. | Ghi nhật ký đầu ra `stdout`/`stderr` trực tiếp của tiến trình. |
| **Lệnh quản lý** | `/agents` | `/tasks` |

---

## 7. Các lỗi phổ biến (Common Mistakes)

1. **Nhầm lẫn khi chuyển Custom Agent trong phiên đang chạy**:
   - *Nguyên nhân*: Kỳ vọng đổi Agent sẽ ghi đè lịch sử hiện tại.
   - *Khắc phục*: Việc đổi Agent giữa phiên sẽ tự động **fork** ra một hội thoại mới để bảo toàn tính toàn vẹn của lịch sử cũ.
2. **Đặt sai vị trí file `agent.md`**:
   - *Nguyên nhân*: Đặt file trực tiếp vào `.agents/agent.md` hoặc `~/.gemini/config/agents/agent.md`.
   - *Khắc phục*: CLI yêu cầu mỗi Agent phải nằm trong một thư mục con riêng biệt theo tên: `~/.gemini/config/agents/{agent_name}/agent.md` hoặc `.agents/agents/{agent_name}/agent.md`.
3. **Dùng phím `k` cho Subagent đã hoàn thành**:
   - *Nguyên nhân*: Phím `k` (`CancelSubagent`) chỉ áp dụng cho tiến trình đang chạy (`running`).
   - *Khắc phục*: Nhấn `Enter` để xem nhật ký của các Subagent đã xong (`done`) hoặc đã lỗi (`error`).

---
*Tài liệu tổng hợp từ nguồn chính thức của Google Antigravity CLI Docs: [Subagents & Background Tasks](https://antigravity.google/docs/cli/subagents) | [Agents Command](https://antigravity.google/docs/cli/commands/agents)*
