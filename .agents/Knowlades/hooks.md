# Tài liệu Kiến thức: Hooks trong Antigravity IDE

## 1. Tổng quan (Overview)
**Hooks** trong Antigravity IDE là cơ chế cho phép nhà phát triển can thiệp, tự động hóa, kiểm soát bảo mật, ghi log hoặc mở rộng luồng thực thi (execution lifecycle) của Agent trong quá trình làm việc.

Hooks lắng nghe các sự kiện hệ thống (Events) và thực thi các chương trình/script tùy chỉnh để kiểm soát hành vi của các công cụ (Tools), luồng gọi mô hình (Model Invocations), hoặc luồng kết thúc tác vụ (Execution Loop).

---

## 2. Cấu trúc Cấu hình & Đường dẫn (Configuration)

Hooks được định nghĩa dưới dạng file **JSON**. Bạn có thể cấu hình Hooks ở 2 phạm vi:
- **Toàn cục (Global)**: Định nghĩa trong cấu hình cá nhân hoặc quy tắc chung (`~/.gemini/config/hooks.json`).
- **Dự án (Workspace/Project)**: Định nghĩa trong thư mục dự án (`.agents/hooks.json`).

### Cấu trúc tổng quan của File Cấu hình Hooks
```json
{
  "my-linter-hook": {
    "enabled": true,
    "PostToolUse": [
      {
        "matcher": "run_command",
        "hooks": [
          {
            "type": "command",
            "command": "./scripts/lint.sh",
            "timeout": 10
          }
        ]
      }
    ]
  },
  "safety-gate": {
    "enabled": false,
    "PreToolUse": [
      {
        "matcher": "run_command",
        "hooks": [
          {
            "command": "./scripts/safety-check.sh"
          }
        ]
      }
    ]
  },
  "reminder": {
    "PreInvocation": [
      {
        "type": "command",
        "command": "./scripts/reminder.sh"
      }
    ]
  }
}
```

### Các trường trong Định nghĩa Hook (Hook Definition Fields)
- `enabled` (boolean, không bắt buộc): Mặc định `true`. Đặt `false` để tạm thời vô hiệu hóa Hook mà không cần xóa cấu hình.
- Các sự kiện hỗ trợ: `PreToolUse`, `PostToolUse`, `PreInvocation`, `PostInvocation`, `Stop`.

---

## 3. Các Sự kiện Hỗ trợ (Supported Events) & Bộ khớp (Matcher)

| Event | Mô tả | Đối tượng Matcher |
| :--- | :--- | :--- |
| `PreToolUse` | Kích hoạt **trước khi** một công cụ (Tool) được thực thi. | Tên công cụ (ví dụ: `run_command`) |
| `PostToolUse` | Kích hoạt **sau khi** công cụ hoàn tất thực thi. | Tên công cụ |
| `PreInvocation` | Kích hoạt **trước khi** Antigravity gọi Model LLM. | N/A (Bỏ qua Matcher) |
| `PostInvocation` | Kích hoạt **sau khi** các lệnh gọi công cụ hoàn tất. | N/A (Bỏ qua Matcher) |
| `Stop` | Kích hoạt **khi vòng lặp thực thi (execution loop) kết thúc**. | N/A (Bỏ qua Matcher) |

### Bộ khớp Matcher (Dành cho `PreToolUse` & `PostToolUse`)
Trường `matcher` hỗ trợ biểu thức chính quy (Regex) để lọc các công cụ kích hoạt Hook:
- `""` hoặc `"*"`: Khớp với **tất cả** công cụ.
- `"run_command"`: Khớp chính xác công cụ `run_command`.
- `"run_command|view_file"`: Khớp một trong các công cụ chỉ định.
- `"browser_.*"`: Khớp với bất kỳ công cụ nào bắt đầu bằng `browser_`.

*Lưu ý:* Đối với `PreInvocation`, `PostInvocation`, và `Stop`, cấu hình danh sách handlers trực tiếp dưới key sự kiện và trường `matcher` không được sử dụng.

---

## 4. Các Công cụ Hỗ trợ (Supported Tools)
Bạn có thể cấu hình Matcher cho các nhóm công cụ hệ thống sau:

### Thao tác File & Thư mục (File & Directory Operations)
- `view_file`: Xem nội dung file (`AbsolutePath`, `StartLine`, `EndLine`, `IsSkillFile`).
- `write_to_file`: Tạo file mới (`TargetFile`, `Overwrite`, `CodeContent`, `Description`, `ArtifactMetadata`).
- `replace_file_content`: Sửa đổi một đoạn văn bản liền mạch trong file (`TargetFile`, `TargetContent`, `ReplacementContent`, `StartLine`, `EndLine`).
- `multi_replace_file_content`: Sửa đổi nhiều đoạn không liền mạch trong cùng một file (`TargetFile`, `ReplacementChunks`).
- `list_dir`: Liệt kê nội dung thư mục (`DirectoryPath`).
- `find_by_name`: Tìm kiếm file/thư mục theo mẫu glob (`SearchDirectory`, `Pattern`, `Excludes`, `MaxDepth`).

### Tìm kiếm & Nghiên cứu (Search & Research)
- `grep_search`: Tìm kiếm chuỗi/regex trong mã nguồn (`SearchPath`, `Query`, `IsRegex`, `CaseInsensitive`, `Includes`).
- `search_web`: Tìm kiếm thông tin trên web (`query`, `domain`).
- `read_url_content`: Lấy nội dung văn bản từ URL công khai (`Url`).

### Hệ thống & Thực thi (System & Execution)
- `run_command`: Đề xuất thực thi lệnh Bash CLI (`CommandLine`, `Cwd`, `WaitMsBeforeAsync`, `RunPersistent`).
- `manage_task`: Quản lý các tác vụ chạy ngầm (`Action`: `'list'`, `'kill'`, `'status'`, `'send_input'`, `TaskId`).
- `schedule`: Đặt hẹn giờ 1 lần hoặc định kỳ Cron job (`DurationSeconds`, `CronExpression`, `Prompt`).
- `list_permissions`: Xem danh sách quyền truy cập hiện tại.
- `ask_permission`: Yêu cầu cấp bổ sung quyền truy cập (`Action`, `Target`, `Reason`).

### Phối hợp Agent & Tương tác (Agent Collaboration & Media)
- `invoke_subagent`: Khởi tạo sub-agent chuyên biệt.
- `define_subagent`: Định nghĩa sub-agent tùy chỉnh.
- `send_message`: Gửi tin nhắn tới các agent khác.
- `manage_subagents`: Liệt kê hoặc hủy các sub-agent đang chạy.
- `ask_question`: Đặt câu hỏi trắc nghiệm tương tác với người dùng.
- `generate_image`: Tạo hoặc chỉnh sửa hình ảnh từ mô tả text.

---

## 5. Cấu hình Hook Handler (Hook Handler Configuration)

Mỗi phần tử trong mảng `hooks` hỗ trợ các thuộc tính sau:
| Trường | Kiểu dữ liệu | Mô tả |
| :--- | :--- | :--- |
| `type` | string | Không bắt buộc. Hiện tại hỗ trợ `"command"`. Mặc định là `"command"`. |
| `command` | string | **Bắt buộc**. Lệnh shell sẽ được thực thi khi Hook kích hoạt. |
| `timeout` | integer | Không bắt buộc. Thời gian chờ tối đa (giây). Mặc định là `30` giây. |

---

## 6. Hợp đồng Đầu vào / Đầu ra (Input/Output Contract)

Hook nhận dữ liệu đầu vào qua **stdin** ở định dạng JSON và trả kết quả đầu ra qua **stdout** dưới dạng JSON (các trường sử dụng kiểu `camelCase`).

### Các trường Đầu vào Chung (Common Input Fields)
Tất cả các Hooks đều nhận được các trường thông tin ngữ cảnh hệ thống sau qua `stdin`:
- `conversationId` (string): UUID duy nhất đại diện cho phiên hội thoại hiện tại.
- `workspacePaths` (array of strings): Danh sách các đường dẫn tuyệt đối tới không gian làm việc (workspace).
- `transcriptPath` (string): Đường dẫn tuyệt đối tới file nhật ký hội thoại `transcript.jsonl`.
- `artifactDirectoryPath` (string): Đường dẫn tuyệt đối tới thư mục lưu trữ Artifacts và ảnh chụp màn hình.

---

### Chi tiết Hợp đồng từng Sự kiện (Event Specifications)

#### 1. `PreToolUse`
Chạy trước khi một công cụ được gọi. Cho phép duyệt, chặn hoặc yêu cầu xác nhận từ người dùng.

- **Đầu vào (stdin)**:
  - `toolCall` (object): Tên (`name`) và đối số (`args`) của công cụ sắp gọi.
  - `stepIdx` (integer): Chỉ số bước hiện tại trong trajectory (bắt đầu từ 0).
  - *(Các trường chung)*
- **Đầu ra (stdout)**:
  - `decision` (string, **bắt buộc**): Quản lý việc thực thi công cụ:
    - `"allow"`: Tự động cho phép công cụ thực thi.
    - `"deny"`: Chặn thực thi ngay lập tức.
    - `"ask"`: Hiển thị hộp thoại hỏi ý kiến người dùng (tôn trọng thiết lập Always Allow).
    - `"force_ask"`: Bắt buộc hỏi người dùng, bỏ qua các quyền đã lưu cache.
  - `reason` (string, tùy chọn): Giải thích lý do đưa ra quyết định.
  - `permissionOverrides` (array of strings, tùy chọn): Danh sách đè quyền truy cập tài nguyên (ví dụ `["command(npm test)"]`).

*Ví dụ Output PreToolUse:*
```json
{
  "decision": "ask",
  "reason": "Yêu cầu xác nhận từ người dùng trước khi chạy test suites.",
  "permissionOverrides": ["command(npm test)"]
}
```

#### 2. `PostToolUse`
Chạy sau khi công cụ thực thi xong.

- **Đầu vào (stdin)**:
  - `stepIdx` (integer): Chỉ số bước vừa hoàn tất.
  - `error` (string, tùy chọn): Thông báo lỗi nếu công cụ thất bại (rỗng nếu thành công).
  - *(Các trường chung)*
- **Đầu ra (stdout)**: Object JSON rỗng `{}`.

#### 3. `PreInvocation`
Chạy trước khi Antigravity gửi yêu cầu tới Model LLM.

- **Đầu vào (stdin)**:
  - `invocationNum` (integer): Số thứ tự lần gọi Model (0-indexed).
  - `initialNumSteps` (integer): Số bước hiện tại trong trajectory.
  - *(Các trường chung)*
- **Đầu ra (stdout)**:
  - `injectSteps` (array of objects, tùy chọn): Danh sách các bước muốn chèn vào hội thoại trước khi gọi Model (có thể chứa `toolCall`, `userMessage`, hoặc `ephemeralMessage`).

*Ví dụ Output PreInvocation:*
```json
{
  "injectSteps": [
    {
      "ephemeralMessage": "Lưu ý kiểm tra linter trước khi phản hồi."
    }
  ]
}
```

#### 4. `PostInvocation`
Chạy sau khi các công cụ trong lượt gọi hoàn tất.

- **Đầu vào (stdin)**: Giống `PreInvocation`.
- **Đầu ra (stdout)**:
  - `injectSteps` (array of objects, tùy chọn): Các bước cần chèn sau khi hoàn tất lượt gọi.
  - `terminationBehavior` (string, tùy chọn): Điều khiển luồng thực thi:
    - `"force_continue"`: Bắt buộc tiếp tục vòng lặp.
    - `"terminate"`: Bắt buộc dừng vòng lặp.
    - `""` (hoặc bỏ qua): Hành vi mặc định.

#### 5. `Stop`
Chạy khi vòng lặp thực thi dừng lại.

- **Đầu vào (stdin)**:
  - `executionNum` (integer): Số thứ tự đợt thực thi.
  - `terminationReason` (string): Lý do dừng (ví dụ `"model_stop"`, `"max_steps_exceeded"`, `"error"`).
  - `error` (string, tùy chọn): Thông báo lỗi hệ thống nếu có.
  - `fullyIdle` (boolean, **bắt buộc**): `true` nếu Agent hoàn tất hoàn toàn và không còn tác vụ ngầm nào đang chạy. `false` nếu vẫn còn background tasks.
  - *(Các trường chung)*
- **Đầu ra (stdout)**:
  - `decision` (string, **bắt buộc**): Đặt `"continue"` để ngăn Agent dừng và tiếp tục quay lại vòng lặp thực thi. Các giá trị khác sẽ chấp nhận dừng.
  - `reason` (string, tùy chọn): Thông điệp chèn vào hội thoại hệ thống nếu `decision` là `"continue"`.

---

## 7. Cấu hình Hooks Bảo vệ Subagent trong Workspace (`.agents/hooks.json`)

Do Antigravity IDE quản lý Hooks ở cấp độ dự án/hệ thống qua file JSON, file cấu hình `.agents/hooks.json` đảm nhiệm việc kích hoạt các Shell Script bảo vệ cho tác vụ Subagent:

```json
{
  "subagent-forge-protection": {
    "enabled": true,
    "PreToolUse": [
      {
        "matcher": "write_to_file|replace_file_content|multi_replace_file_content",
        "hooks": [
          {
            "type": "command",
            "command": "./.agents/scripts/hooks/check-staging-zone.sh",
            "timeout": 10
          }
        ]
      },
      {
        "matcher": "invoke_subagent",
        "hooks": [
          {
            "type": "command",
            "command": "./.agents/scripts/hooks/check-subagent-recursion.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

---

## 8. Chi tiết Cài đặt các Shell Script Handlers

Các file Shell Script được đặt tại `.agents/scripts/hooks/` và nhận dữ liệu JSON từ `stdin` để trả về quyết định `decision` (`allow` hoặc `deny`).

### 1. Script kiểm tra vùng Staging khi Ghi file (`check-staging-zone.sh`)
📄 Path: `.agents/scripts/hooks/check-staging-zone.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

# Nhận JSON payload từ stdin
INPUT=$(cat)

# Trích xuất TargetFile từ đối số công cụ
TARGET_FILE=$(echo "$INPUT" | jq -r '.toolCall.args.TargetFile // empty')

if [ -n "$TARGET_FILE" ]; then
  # Nếu file mục tiêu nằm trong .agents/agents/ nhưng KHÔNG nằm trong _staging/
  if [[ "$TARGET_FILE" =~ \.agents/agents/ ]] && [[ ! "$TARGET_FILE" =~ \.agents/agents/_staging/ ]]; then
    echo '{"decision": "deny", "reason": "BLOCKED: Subagent-forge may only write to .agents/agents/_staging/ directory. Approve deployment explicitly via deploy <name> command."}'
    exit 0
  fi
fi

echo '{"decision": "allow"}'
```

### 2. Script Chặn Gọi Đệ quy Subagent (`check-subagent-recursion.sh`)
📄 Path: `.agents/scripts/hooks/check-subagent-recursion.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

# Nhận JSON payload từ stdin
INPUT=$(cat)

# Trích xuất Subagent TypeName từ đối số công cụ
SUBAGENT_TYPE=$(echo "$INPUT" | jq -r '.toolCall.args.Subagents[0].TypeName // .toolCall.args.TypeName // empty')

if [ "$SUBAGENT_TYPE" = "subagent-forge" ]; then
  echo '{"decision": "deny", "reason": "BLOCKED: Recursive subagent-forge invocation forbidden (max depth = 1)."}'
  exit 0
fi

echo '{"decision": "allow"}'
```

---
*Tài liệu được tổng hợp từ nguồn chính thức của Google Antigravity Docs: [Antigravity IDE Hooks](https://antigravity.google/docs/ide/hooks)*
