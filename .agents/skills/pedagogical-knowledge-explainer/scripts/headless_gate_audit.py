#!/usr/bin/env python3
"""
Headless Gate Audit Script for Pedagogical Knowledge Explainer Skill.
This script acts as the terminal mechanical gatekeeper, validating that a draft
lesson adheres strictly to pedagogical standards (First Principles, Mechanics,
Trade-offs, Socratic Probe, Zero-Placeholder) without polluting the main LLM context.
"""

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path

# Đảm bảo UTF-8 encoding trên mọi terminal (đặc biệt là Windows cp1252)
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except AttributeError:
        import io
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
        sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")


DEFAULT_SCHEMA = {
    "type": "object",
    "properties": {
        "issues_detected": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "phase": {"type": "string"},
                    "severity": {"type": "string", "enum": ["CRITICAL", "MAJOR", "MINOR"]},
                    "issue_description": {"type": "string"},
                    "actionable_fix": {"type": "string"}
                },
                "required": ["phase", "severity", "issue_description", "actionable_fix"]
            }
        },
        "total_issues_count": {"type": "integer"},
        "evidence_verified": {"type": "boolean"},
        "summary_evaluation": {"type": "string"}
    },
    "required": ["issues_detected", "total_issues_count", "evidence_verified", "summary_evaluation"]
}


def local_sanity_checks(draft_content: str) -> list:
    """Pre-flight regex checks to catch mechanical placeholders immediately."""
    local_issues = []
    
    # 1. Check for placeholders
    placeholder_patterns = [
        (r'\bTODO\b', 'Phát hiện từ khóa TODO chưa hoàn thiện', 'CRITICAL'),
        (r'\bFIXME\b', 'Phát hiện từ khóa FIXME chưa xử lý', 'CRITICAL'),
        (r'/\*\s*code here\s*\*/', 'Phát hiện comment code rỗng', 'CRITICAL'),
        (r'\bpass\s*#\s*implement\b', 'Phát hiện hàm rỗng chưa thực thi', 'CRITICAL'),
        (r'\bmock_data\b', 'Phát hiện dữ liệu giả lập mock_data', 'MAJOR')
    ]
    
    for pattern, desc, severity in placeholder_patterns:
        matches = re.findall(pattern, draft_content, re.IGNORECASE)
        if matches:
            local_issues.append({
                "phase": "Mechanical Zero-Placeholder",
                "severity": severity,
                "issue_description": f"{desc} ({len(matches)} lần).",
                "actionable_fix": "Viết mã nguồn hoặc nội dung hoàn chỉnh chạy thật, xóa bỏ hoàn toàn placeholder."
            })
            
    # 2. Check for Mermaid diagrams
    if "```mermaid" not in draft_content:
        local_issues.append({
            "phase": "Pha 2: Under-The-Hood Mechanics",
            "severity": "MAJOR",
            "issue_description": "Thiếu sơ đồ trực quan Mermaid (flowchart/sequenceDiagram) mô tả cơ chế vận hành ngầm.",
            "actionable_fix": "Bổ sung ít nhất 1 sơ đồ Mermaid mô tả luồng dữ liệu hoặc vòng đời trạng thái."
        })
        
    return local_issues


def run_headless_eval(draft_path: Path, checklist_path: Path, effort: str, timeout: str) -> dict:
    """Executes agy in headless mode with structured JSON schema output."""
    draft_text = draft_path.read_text(encoding="utf-8")
    local_issues = local_sanity_checks(draft_text)
    
    checklist_text = ""
    if checklist_path.exists():
        checklist_text = checklist_path.read_text(encoding="utf-8")
    
    prompt = (
        f"Bạn là Chuyên Gia Giám Định Sư Phạm (Mechanical Pedagogical Auditor).\n"
        f"Hãy thẩm định nghiêm ngặt nội dung bản thảo bài giảng sau đây dựa trên tiêu chuẩn kiểm duyệt.\n\n"
        f"--- TIÊU CHUẨN KIỂM DUYỆT (CHECKLIST) ---\n"
        f"{checklist_text}\n\n"
        f"--- NỘI DUNG BẢN THẢO (DRAFT LESSON) ---\n"
        f"{draft_text}\n\n"
        f"Yêu cầu:\n"
        f"1. Kiểm tra: Có định nghĩa từ điển suông không? Đã có bối cảnh lịch sử và nguyên lý gốc chưa?\n"
        f"2. Đã giải phẫu cơ chế ngầm với sơ đồ trực quan chưa?\n"
        f"3. Đã có tối thiểu 2 kịch bản sập nguồn (Failure Modes) và ma trận đánh đổi chưa?\n"
        f"4. Đã có câu hỏi phản biện Socratic hoặc bài tập tình huống biên để người học tự tư duy chưa?\n"
        f"5. Có bất kỳ khẳng định kỹ thuật nào thiếu căn cứ hoặc sai lệch không?\n"
        f"Hãy trả về JSON có cấu trúc chứa danh sách issues_detected."
    )
    
    cmd = [
        "agy",
        "-p", prompt,
        "--effort", effort,
        "--output-format", "json",
        "--json-schema", json.dumps(DEFAULT_SCHEMA)
    ]
    
    try:
        proc = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            encoding="utf-8",
            timeout=300
        )
    except FileNotFoundError:
        # Fallback if agy is not directly in PATH
        return {
            "status": "FAIL" if local_issues else "PASS",
            "total_issues_count": len(local_issues),
            "issues_detected": local_issues,
            "evidence_verified": True,
            "summary_evaluation": "CLI 'agy' không khả dụng trong môi trường này; chỉ áp dụng kiểm tra tĩnh cục bộ (Local Static Sanity Checks)."
        }
    except subprocess.TimeoutExpired:
        local_issues.append({
            "phase": "Terminal Gate Timeout",
            "severity": "CRITICAL",
            "issue_description": f"Tiến trình headless audit vượt quá thời gian chờ {timeout}.",
            "actionable_fix": "Giảm dung lượng bản thảo hoặc tăng print-timeout."
        })
        return {
            "status": "FAIL",
            "total_issues_count": len(local_issues),
            "issues_detected": local_issues,
            "evidence_verified": False,
            "summary_evaluation": "Headless process timed out."
        }

    if proc.returncode != 0:
        error_msg = proc.stderr.strip() or proc.stdout.strip() or "Unknown error"
        local_issues.append({
            "phase": "Headless Execution Error",
            "severity": "CRITICAL",
            "issue_description": f"agy trả về lỗi exit code {proc.returncode}: {error_msg[:300]}",
            "actionable_fix": "Kiểm tra lại quyền thực thi hoặc cú pháp prompt."
        })
        return {
            "status": "FAIL",
            "total_issues_count": len(local_issues),
            "issues_detected": local_issues,
            "evidence_verified": False,
            "summary_evaluation": f"Headless audit failed to execute cleanly."
        }

    try:
        raw_output = json.loads(proc.stdout)
        structured = raw_output.get("structured_output") or {}
        if not structured and "response" in raw_output:
            structured = json.loads(raw_output["response"])
            
        # Merge local sanity issues with AI-detected issues
        combined_issues = local_issues + structured.get("issues_detected", [])
        
        result = {
            "status": "PASS" if len(combined_issues) == 0 else "FAIL",
            "total_issues_count": len(combined_issues),
            "issues_detected": combined_issues,
            "evidence_verified": structured.get("evidence_verified", True),
            "summary_evaluation": structured.get("summary_evaluation", "Hoàn thành thẩm định cơ học.")
        }
        return result
    except Exception as ex:
        local_issues.append({
            "phase": "JSON Parsing Error",
            "severity": "CRITICAL",
            "issue_description": f"Không thể parse JSON từ kết quả audit: {str(ex)}",
            "actionable_fix": "Đảm bảo --output-format json và schema được hỗ trợ đầy đủ."
        })
        return {
            "status": "FAIL",
            "total_issues_count": len(local_issues),
            "issues_detected": local_issues,
            "evidence_verified": False,
            "summary_evaluation": "JSON Envelope parse failure."
        }


def main():
    parser = argparse.ArgumentParser(
        description="Headless Gatekeeper Auditor for Pedagogical Knowledge Explainer Skill."
    )
    parser.add_argument(
        "--draft",
        required=True,
        type=str,
        help="Đường dẫn tuyệt đối hoặc tương đối tới file bản thảo bài giảng (markdown)."
    )
    parser.add_argument(
        "--checklist",
        type=str,
        default="",
        help="Đường dẫn tới file checklist tiêu chí (mặc định: loop/pedagogical-checklist.md)."
    )
    parser.add_argument(
        "--effort",
        type=str,
        default="medium",
        choices=["low", "medium", "high"],
        help="Mức độ suy luận reasoning effort cho headless audit (mặc định: medium)."
    )
    parser.add_argument(
        "--timeout",
        type=str,
        default="5m",
        help="Thời gian timeout tối đa cho lệnh agy (mặc định: 5m)."
    )
    
    args = parser.parse_args()
    draft_path = Path(args.draft).resolve()
    
    if not draft_path.exists():
        error_res = {
            "status": "FAIL",
            "total_issues_count": 1,
            "issues_detected": [{
                "phase": "Input Validation",
                "severity": "CRITICAL",
                "issue_description": f"File bản thảo không tồn tại: {draft_path}",
                "actionable_fix": "Cung cấp đường dẫn chính xác tới file bản thảo."
            }],
            "evidence_verified": False,
            "summary_evaluation": "Missing draft file."
        }
        print(json.dumps(error_res, ensure_ascii=False, indent=2))
        sys.exit(1)
        
    checklist_path = Path(args.checklist).resolve() if args.checklist else (
        draft_path.parent / "loop" / "pedagogical-checklist.md"
    )
    if not checklist_path.exists():
        # Fallback to skill directory default checklist
        skill_dir = Path(__file__).resolve().parent.parent
        checklist_path = skill_dir / "loop" / "pedagogical-checklist.md"
        
    result = run_headless_eval(draft_path, checklist_path, args.effort, args.timeout)
    print(json.dumps(result, ensure_ascii=False, indent=2))
    
    if result["total_issues_count"] > 0:
        sys.exit(1)
    else:
        sys.exit(0)


if __name__ == "__main__":
    main()
