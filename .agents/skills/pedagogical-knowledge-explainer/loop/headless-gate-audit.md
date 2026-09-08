# Quy Trình Chốt Chặn Headless Gate (Terminal Headless Audit Protocol)

Tài liệu hướng dẫn cách kích hoạt và xử lý chốt chặn kiểm duyệt cơ học ngầm ở điểm cuối trước khi bàn giao bài giảng cho người học.

---

## 1. Bản Chất Của Chốt Chặn Điểm Cuối (Terminal State Gate)

- **Vị trí**: Chỉ được kích hoạt **SAU KHI** Agent đã hoàn thành Pha 1 đến Pha 4 và có bản thảo bài giảng đầy đủ (`draft_lesson.md`).
- **Nguyên tắc**: Tuyệt đối không can thiệp vào mạch tư duy tự do ở các pha trước. Gate chỉ đóng vai trò thẩm định viên độc lập (Independent Auditor) kiểm tra tính toàn vẹn và chất lượng đầu ra.
- **Giảm tải Context**: Quá trình kiểm tra diễn ra trong sub-process headless qua lệnh `agy -p ...`. Phiên chính chỉ nhận về một JSON Envelope siêu nhẹ chứa danh sách lỗi (nếu có), không làm tràn context.

---

## 2. Lệnh Kích Hoạt Headless Gate Qua Script Đóng Gói Sẵn

Agent thực thi script sau qua `run_command` (không tự viết script ad-hoc):

```bash
python .agents/skills/pedagogical-knowledge-explainer/scripts/headless_gate_audit.py --draft "<path_to_draft_file>" --effort medium
```

### Các Tham Số Hỗ Trợ:
- `--draft`: (Bắt buộc) Đường dẫn tới file bản thảo bài giảng markdown cần kiểm duyệt.
- `--checklist`: (Tùy chọn) Đường dẫn tới checklist tiêu chí (mặc định nạp `loop/pedagogical-checklist.md`).
- `--effort`: (Tùy chọn) Mức độ suy luận cho `agy` (`low`, `medium`, `high`, mặc định `medium`).
- `--timeout`: (Tùy chọn) Thời gian timeout cho tiến trình headless (mặc định `5m`).

### Output Stdout JSON Chuẩn:
```json
{
  "status": "PASS",
  "total_issues_count": 0,
  "issues_detected": [],
  "evidence_verified": true,
  "summary_evaluation": "Hoàn thành thẩm định cơ học."
}
```

---

## 3. Thuật Toán Xử Lý Feedback Loop Tự Sửa Lỗi

Agent tiếp nhận kết quả từ Headless Gate và xử lý theo thuật toán sau:

```python
# Thuật toán Feedback Loop trong Skill Runtime
MAX_ATTEMPTS = 2

for attempt in range(1, MAX_ATTEMPTS + 1):
  # 1. Soạn bản thảo bài giảng (Tự do tư duy qua 4 pha)
  draft = compose_pedagogical_lesson()

  # 2. Chạy headless gate ngầm
  gate_result = execute_headless_gate(draft)

  # 3. Phân tích kết quả JSON
  if gate_result["total_issues_count"] == 0:
    # Không còn vấn đề tồn đọng -> Bàn giao ngay cho người học
    deliver_to_user(draft)
    break
  else:
    # Còn vấn đề -> Trích xuất danh sách và tự sửa
    issues = gate_result["issues_detected"]
    log_internal(f"Phát hiện {len(issues)} vấn đề ở lần thử {attempt}:")
    for item in issues:
      log_internal(
          f"- [{item['severity']}] {item['phase']}:"
          f" {item['issue_description']} -> Cách sửa: {item['actionable_fix']}"
      )

    # Đưa feedback vào để sửa trực tiếp bản thảo
    draft = refine_draft_with_fixes(draft, issues)
```
