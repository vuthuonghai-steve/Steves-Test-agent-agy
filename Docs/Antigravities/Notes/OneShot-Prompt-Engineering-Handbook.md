# 📝 Sổ Tay Tra Cứu Nhanh: Vận Hành One-Shot Prompt (`agy -p`)

> **Liên kết tài liệu gốc**: [Tài liệu Kiến Trúc Chi Tiết Context Window One-Shot](../CLI/Context-Architecture-OneShot.md)

---

## ⚡ 1. Bản Đồ Nhanh: Khi Nào Dùng & Khi Nào Tránh One-Shot (`-p`)

### ✅ DÙNG One-Shot (`-p`) Khi:
1. **Kiểm tra chất lượng mã nguồn độc lập (CI/CD Gates)**: Đánh giá `git diff`, kiểm tra vi phạm bảo mật, audit dependencies.
2. **Bóc tách dữ liệu có cấu trúc (Entity / Schema Extraction)**: Chuyển đổi log lỗi, commit message thành JSON chuẩn qua `--json-schema`.
3. **Phân loại nhị phân (Binary Classification)**: Quyết định `PASS` / `FAIL`, `APPROVE` / `REJECT` không cần trao đổi qua lại.
4. **Cronjobs định kỳ**: Tự động hóa tóm tắt báo cáo nhật ký, tổng kết build hàng ngày.

### ❌ KHÔNG DÙNG One-Shot (`-p`) Khi:
1. **Tác vụ yêu cầu trao đổi nhiều bước (Multi-turn)**: Cần hỏi thêm thông tin, đối soát qua lại $\rightarrow$ *Giải pháp: Chuyển sang `--input-format stream-json` hoặc `--conversation <UUID>`*.
2. **Cần agent tự do thực thi lệnh shell trên server**: Không cấu hình quyền sẽ bị dính bẫy Soft-denial $\rightarrow$ *Giải pháp: Khai báo whitelist trong `settings.json`*.
3. **Chạy vòng lặp 100+ prompt liên tiếp**: Tốn thời gian khởi tạo process nhiều lần $\rightarrow$ *Giải pháp: Dùng Python Subprocess stream qua `stdin`*.

---

## 🛠️ 2. Công Thức "Bất Bại" Cho Script One-Shot Trong CI/CD

```bash
result=$(agy -p "$TASK_PROMPT" \
  --output-format json \
  --json-schema "$CONTRACT_SCHEMA" \
  --effort medium \
  --print-timeout 10m \
  --sandbox)
```

### Giải Thích Bộ Cờ Phòng Vệ Bắt Buộc:
* `--output-format json`: Ép dữ liệu ra dạng envelope JSON duy nhất trên `stdout`.
* `--json-schema "$CONTRACT_SCHEMA"`: Khóa chết cấu trúc đầu ra, loại bỏ 100% lời nói phiếm của AI.
* `--effort medium`: Cân bằng giữa tốc độ và độ sâu suy luận (Thinking Tokens).
* `--print-timeout 10m`: Đặt trần thời gian tối đa để runner không bị treo vĩnh viễn.
* `--sandbox`: Hạn chế quyền can thiệp sâu vào hệ điều hành.

---

## ⚠️ 3. Bẫy Nguy Hiểm Cần Ghi Nhớ (Top 3 Gotchas)

1. **Bẫy Mất Thư Mục Dự Án (CWD Drift)**:
   * Nếu script chạy từ thư mục `/tmp` hoặc thư mục ngoài, CLI sẽ **không nạp được `AGENTS.md`** của repo.
   * *Khắc phục*: Luôn `cd` về thư mục gốc dự án trước khi gọi `agy`.

2. **Bẫy Soft-Denial (Exit code 0 ảo) & Cơ Chế Truy Vết Đứt Gẫy**:
   * **Triệu chứng**: Agent cần chạy lệnh terminal/tool nhưng chưa được cấp quyền trong `settings.json`. Trong headless mode, CLI không có TUI để hỏi người dùng nên sẽ **tự động từ chối ngầm (Soft-Denied)** nhưng tiến trình **vẫn thoát với Exit code 0**! Kết quả là script báo thành công nhưng thực tế tác vụ bị bỏ dở nửa chừng.
   * **Vấn đề thực tế**: Hệ thống có hàng trăm lệnh khác nhau (git, npm, python, docker, test runner...), không thể lường trước để whitelist thủ công từng lệnh đơn lẻ.
   * **Giải Pháp 1 — Cơ Chế Tự Động Bắt Điểm Đứt Gẫy (Diagnostic Failure Gate)**:
     Trong JSON envelope trả về, CLI luôn ghi lại các hành động bị chặn trong mảng `.denied_actions`. Script CI/CD bắt buộc phải kiểm tra mảng này và báo lỗi lập tức:
     ```bash
     # Bắt trọn vẹn điểm đứt gẫy và in cảnh báo đỏ
     DENIED_OPS=$(echo "$RESPONSE" | jq -r '.denied_actions[]? | "\(.action): \(.display_name)"')
     if [[ -n "$DENIED_OPS" ]]; then
       echo "🚨 [ĐỨT GÃY NGHIỆP VỤ] Phát hiện hành động bị Soft-Denied:" >&2
       echo "$DENIED_OPS" | while read -r op; do echo "   ❌ Bị chặn: $op" >&2; done
       echo "💡 Nguyên nhân: Tool cần quyền nhưng chưa được whitelist trong settings.json." >&2
       exit 3 # Fail pipeline ngay lập tức, không để pass ngầm!
     fi
     ```
   * **Giải Pháp 2 — Tách Kênh Stderr Để Đọc Chi Tiết Command Bị Chặn**:
     CLI luôn ghi lý do từ chối chi tiết vào `stderr`. Hãy hứng `stderr` ra file riêng để hiển thị chính xác command nào bị fail:
     ```bash
     # Hứng stdout vào biến JSON, chuyển stderr vào file log chẩn đoán
     RESPONSE=$(agy -p "$TASK" --output-format json 2> /tmp/agy_diag.log)
     if [[ -s /tmp/agy_diag.log ]]; then
       grep -E "(denied|permission|notice)" /tmp/agy_diag.log >&2 || true
     fi
     ```
   * **Giải Pháp 3 — Chiến Lược Cấu Hình Linh Hoạt (Thay Vì Whitelist Từng Lệnh Lẻ Tẻ)**:
     * **Cách A (Cụm Toolchain Regex)**: Whitelist theo tiền tố công cụ phát triển của dự án trong `~/.gemini/antigravity-cli/settings.json`:
       ```json
       "permissions": {
         "allow": [
           "command((git|npm|npx|pnpm|yarn|python|pytest|node|cargo|go).*)",
           "read_file(*)",
           "write_file(src/|tests/|dist/)"
         ]
       }
       ```
     * **Cách B (Môi Trường CI/CD Container Cô Lập)**: Nếu pipeline chạy trong Docker Container dùng một lần rồi hủy (ephemeral runner), hãy sử dụng cờ:
       `--dangerously-skip-permissions` (kết hợp `--sandbox`) để tự động duyệt toàn bộ command mà không sợ rò rỉ rủi ro ra máy chủ host.

3. **Bẫy Làm Bẩn `stdout`**:
   * Tuyệt đối không dùng toán tử `2>&1` khi bắt biến JSON (ví dụ `res=$(agy -p "..." 2>&1)`), vì log chẩn đoán và thông báo soft-denied từ `stderr` sẽ bị trộn lẫn vào chuỗi JSON làm hỏng hoàn toàn parser `jq`.
   * *Khắc phục*: Giữ nguyên `stdout` sạch cho JSON, chuyển hướng `stderr` ra file log: `2> stderr.log`.

