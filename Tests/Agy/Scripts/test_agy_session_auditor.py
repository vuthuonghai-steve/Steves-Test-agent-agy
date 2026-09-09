#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Antigravity CLI (agy) Session Auditor & Quality Telemetry Runner
Đo lường cơ học 100% token usage (input, output, cache, thinking) và đánh giá độ sâu lập luận.
"""

import sys
import os
import json
import subprocess
import datetime
from pathlib import Path

# Cấu hình UTF-8 cho Windows Console
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

WORKSPACE_ROOT = Path(r".")
DEFAULT_SESSIONS_DIR = WORKSPACE_ROOT / "Tests" / "Agy" / "Logs" / "Sessions"

def audit_session(prompt: str, model: str = "", conversation_id: str = ""):
    print("=" * 80)
    print("  ANTIGRAVITY CLI SESSION AUDITOR & TOKEN TELEMETRY (PYTHON)")
    print("=" * 80)
    
    cmd = ["agy", "--add-dir", str(WORKSPACE_ROOT.resolve()), "-p", prompt, "--output-format", "json"]
    if model:
        cmd.extend(["--model", model])
    if conversation_id:
        cmd.extend(["--conversation", conversation_id])

    print(f"  Prompt: {prompt}")
    print("  Đang gọi CLI agy và thu thập số liệu...")

    start_time = datetime.datetime.now()
    proc = subprocess.Popen(
        cmd,
        cwd=str(WORKSPACE_ROOT),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
        errors="replace"
    )
    
    stdout, stderr = proc.communicate()
    wall_duration = round((datetime.datetime.now() - start_time).total_seconds(), 2)

    if proc.returncode != 0:
        print(f"[FAIL] Lệnh agy thất bại (Exit code: {proc.returncode})")
        if stderr:
            print(f"Error: {stderr}")
        return False

    try:
        data = json.loads(stdout)
    except json.JSONDecodeError:
        print(f"[FAIL] Không parse được JSON từ agy:\n{stdout}")
        return False

    conv_id = data.get("conversation_id", "unknown_session")
    usage = data.get("usage", {})
    in_tok = usage.get("input_tokens", 0)
    out_tok = usage.get("output_tokens", 0)
    thinking_tok = usage.get("thinking_tokens", 0)
    cache_tok = usage.get("cache_read_tokens", 0)
    total_tok = usage.get("total_tokens", in_tok + out_tok)
    engine_duration = data.get("duration_seconds", wall_duration)
    status = data.get("status", "UNKNOWN")
    response_text = data.get("response", "")

    # Đánh giá chỉ số chất lượng
    thinking_ratio = round((thinking_tok / max(1, out_tok)) * 100, 2)
    cache_efficiency = round((cache_tok / max(1, in_tok + cache_tok)) * 100, 2)
    
    if thinking_ratio >= 50:
        reasoning_depth = "Cao (Cognitive Depth / Lập luận sâu)"
    elif thinking_ratio >= 20:
        reasoning_depth = "Trung bình (Balanced)"
    else:
        reasoning_depth = "Nhanh / Trực tiếp (Fast Response)"

    print(f"\n[+] KẾT QUẢ PHIÊN LÀM VIỆC: {conv_id}")
    print(f"    - Trạng thái            : {status}")
    print(f"    - Thời gian phản hồi    : {engine_duration}s (Wall clock: {wall_duration}s)")
    print(f"    - Input Tokens          : {in_tok}")
    print(f"    - Prompt Cache Read     : {cache_tok} ({cache_efficiency}% tiết kiệm)")
    print(f"    - Output Tokens         : {out_tok}")
    print(f"    - Thinking Tokens       : {thinking_tok}")
    print(f"    - Tỷ lệ Tư Duy          : {thinking_ratio}% [{reasoning_depth}]")
    print(f"    - Tổng Tokens tiêu thụ  : {total_tok}")

    # Ghi dữ liệu vào thư mục Session tương ứng (ưu tiên thư mục có timestamp prefix do wide-event-hook tạo)
    matching_dirs = [d for d in DEFAULT_SESSIONS_DIR.iterdir() if d.is_dir() and d.name.endswith(conv_id)]
    if matching_dirs:
        session_dir = matching_dirs[0]
    else:
        timestamp_prefix = datetime.datetime.now().strftime("%Y-%m-%d_%H%M%S")
        session_dir = DEFAULT_SESSIONS_DIR / f"{timestamp_prefix}_{conv_id}"
        session_dir.mkdir(parents=True, exist_ok=True)

    try:
        with open(DEFAULT_SESSIONS_DIR / "LATEST_SESSION.txt", "w", encoding="utf-8") as f:
            f.write(session_dir.name)
    except Exception:
        pass

    summary_file = session_dir / "session_summary.json"
    summary_data = {
        "timestamp_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "session_id": conv_id,
        "prompt": prompt,
        "status": status,
        "duration_seconds": engine_duration,
        "tokens": {
            "input_tokens": in_tok,
            "cache_read_tokens": cache_tok,
            "output_tokens": out_tok,
            "thinking_tokens": thinking_tok,
            "total_tokens": total_tok
        },
        "quality_metrics": {
            "thinking_ratio_pct": thinking_ratio,
            "cache_efficiency_pct": cache_efficiency,
            "reasoning_depth": reasoning_depth,
            "response_chars": len(response_text)
        },
        "response_snippet": response_text[:500] + ("..." if len(response_text) > 500 else "")
    }

    with open(summary_file, "w", encoding="utf-8") as f:
        json.dump(summary_data, f, indent=2, ensure_ascii=False)

    report_file = session_dir / "session_report.md"
    report_content = f"""# Báo Cáo Đo Lường Telemetry & Đánh Giá Chất Lượng: {conv_id}

- **Thời gian:** {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
- **Trạng thái:** `{status}`
- **Yêu cầu (Prompt):** {prompt}

---

## 1. Đo Lường Token Tiêu Thụ
| Chỉ số | Giá trị | Ý nghĩa |
| :--- | :--- | :--- |
| **Input Tokens** | `{in_tok}` | Tổng tokens bối cảnh và prompt gửi lên |
| **Cache Read Tokens** | `{cache_tok}` | Tokens đọc từ Prompt Cache (tiết kiệm chi phí) |
| **Output Tokens** | `{out_tok}` | Tổng tokens phản hồi sinh ra |
| **Thinking Tokens** | `{thinking_tok}` | Lượng token suy nghĩ nội tâm |
| **Tổng Tokens** | `{total_tok}` | Tổng chi phí transaction |

---

## 2. Bảng Đánh Giá Chất Lượng & Chi Phí
- **Độ sâu lập luận (Cognitive Depth):** **{reasoning_depth}** ({thinking_ratio}% output dành cho tư duy).
- **Hiệu quả Caching:** **{cache_efficiency}%** dữ liệu được đọc lại không tốn thêm chi phí.
- **Thời gian phản hồi:** **{engine_duration}s**.

---

## 3. Nội Dung Phản Hồi
```markdown
{response_text}
```
"""
    with open(report_file, "w", encoding="utf-8") as f:
        f.write(report_content)

    print("\n" + "=" * 80)
    print("  HOÀN TẤT GHI NHẬN TELEMETRY!")
    print(f"  -> File JSON: {summary_file}")
    print(f"  -> File Báo cáo Markdown: {report_file}")
    print("=" * 80)
    return True

if __name__ == "__main__":
    prompt_arg = " ".join(sys.argv[1:]) if len(sys.argv) > 1 else "Tóm tắt phương châm hoạt động của AGENTS.md trong 2 câu."
    audit_session(prompt_arg)
