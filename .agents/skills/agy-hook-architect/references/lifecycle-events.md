# 📖 Tra Cứu Chuyên Sâu: Antigravity Lifecycle Events & I/O Contracts

Tài liệu này cung cấp đặc tả kỹ thuật chi tiết nhất về cơ chế Lifecycle Hooks trong Antigravity CLI và IDE, đảm bảo 100% việc triển khai không bao giờ vi phạm schema.

---

## 1. Bản Đồ 5 Sự Kiện Vòng Đời (Lifecycle Events)

| Tên Sự Kiện | Thời Điểm Kích Hoạt | Phạm Vi Matcher | Cấu Trúc Khai Báo Trong `hooks.json` | STDOUT Bắt Buộc |
| :--- | :--- | :--- | :--- | :--- |
| **`PreToolUse`** | Trước khi bất kỳ tool nào được gọi | Regex theo tên tool (`*`, `run_command`, v.v.) | Grouped: `{ "matcher": "...", "hooks": [...] }` | `{"decision": "allow"\|"deny"\|"ask"}` |
| **`PostToolUse`** | Ngay sau khi tool thực thi xong | Regex theo tên tool | Grouped: `{ "matcher": "...", "hooks": [...] }` | `{}` (Object rỗng) |
| **`PreInvocation`**| Trước khi agent gửi prompt tới model LLM | Không áp dụng (Bị bỏ qua) | Flat: `[ { "type": "command", "command": "..." } ]` | `{"injectSteps": [...]}` |
| **`PostInvocation`**| Sau khi model LLM sinh phản hồi | Không áp dụng | Flat: `[ { "type": "command", "command": "..." } ]` | `{"injectSteps": [...], "terminationBehavior": "..."}` |
| **`Stop`** | Khi vòng lặp agent kết thúc | Không áp dụng | Flat: `[ { "type": "command", "command": "..." } ]` | `{"decision": "allow"\|"continue"}` |

---

## 2. Đặc Tả Dữ Liệu Vào (STDIN) & Dữ Liệu Ra (STDOUT)

### A. Common Metadata (Luôn có trong STDIN mọi event)
```json
{
  "conversationId": "8455c218-1653-423b-bdf7-227f771be3bc",
  "workspacePaths": ["C:/Users/ADMIN/Documents/workspace/Steves"],
  "transcriptPath": "C:/Users/ADMIN/.gemini/antigravity-cli/brain/.../transcript.jsonl",
  "artifactDirectoryPath": "C:/Users/ADMIN/.gemini/antigravity-cli/brain/...",
  "modelName": "gemini-3.8-flash-medium"
}
```

### B. PreToolUse
* **STDIN**: Nhận thêm `toolCall` (`{ "name": "...", "args": {...} }`) và `stepIdx`.
* **STDOUT Bắt Buộc**:
  ```json
  {
    "decision": "allow",
    "reason": "Giải thích lý do cho phép hoặc chặn",
    "permissionOverrides": ["command(...)"]
  }
  ```
  * `decision`: `"allow"`, `"deny"`, `"ask"`, `"force_ask"`.

### C. PostToolUse
* **STDIN**: Nhận thêm `toolCall`, `stepIdx`, và `error` (nếu có lỗi).
* **STDOUT Bắt Buộc**: `{}`

### D. Stop Gate
* **STDIN**: Nhận thêm `executionNum`, `terminationReason`, `fullyIdle` (boolean: true nếu không còn tiến trình nền nào).
* **STDOUT Bắt Buộc**:
  ```json
  {
    "decision": "allow"
  }
  ```
  *(Nếu muốn buộc agent làm tiếp, đặt `"decision": "continue", "reason": "Chưa đạt yêu cầu X"`)*.

---

## 3. Danh Sách Standard Tools (Dùng Cho Matcher)

- File tools: `view_file`, `write_to_file`, `replace_file_content`, `multi_replace_file_content`, `list_dir`, `find_by_name`.
- Execution tools: `run_command`, `manage_task`, `schedule`.
- Search tools: `grep_search`, `search_web`, `read_url_content`.
- Subagent tools: `invoke_subagent`, `define_subagent`, `manage_subagents`, `send_message`.

---

## 4. Ba Cạm Bẫy Sống Còn Cần Tránh (Gotchas)

1. **Working Directory của Hook**:
   Antigravity tự động đặt CWD của tiến trình hook là thư mục **chứa `hooks.json`** (tức `.agents/`). Do đó đường dẫn command phải là `node scripts/my-hook.js` thay vì `.agents/scripts/my-hook.js`.
2. **Khóa Chết Bằng STDOUT Bẩn**:
   Mọi ký tự lạ in ra STDOUT (như `console.log("debug")`) sẽ làm hỏng parser JSON của Antigravity, khiến tool bị block. Chỉ được xuất JSON hợp lệ ra STDOUT! Mọi log debug phải ghi vào STDERR (`console.error`) hoặc ghi ra file sink.
3. **Môi Trường Git Worktree với `agy`**:
   Vì thư mục worktree chứa file `.git` (dạng con trỏ text), `agy` sẽ không tự động nhận diện root nếu không có cờ `--add-dir "<path-worktree>"`. Luôn truyền cờ này trong automation script!
