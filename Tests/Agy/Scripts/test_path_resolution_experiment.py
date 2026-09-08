#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Experiment Script: Antigravity Path Resolution & Ingestion Benchmark
Evaluates relative vs absolute path behavior across Workspace Root & Subdirectories in headless mode.
Location: Tests/Agy/Scripts/test_path_resolution_experiment.py
"""

import datetime
import json
import os
import subprocess
import sys
from pathlib import Path

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

WORKSPACE_ROOT = Path(r".")
SUBDIR = WORKSPACE_ROOT / "Tests" / "Agy"
LOGS_BASE_DIR = WORKSPACE_ROOT / "Tests" / "Agy" / "Logs"

def run_cmd(cmd_list, cwd=WORKSPACE_ROOT, timeout=120):
    start_time = datetime.datetime.now()
    proc = subprocess.Popen(
        cmd_list,
        cwd=str(cwd),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
        errors="replace"
    )
    try:
        stdout, stderr = proc.communicate(timeout=timeout)
        duration = round((datetime.datetime.now() - start_time).total_seconds(), 2)
        return proc.returncode, stdout, stderr, duration
    except subprocess.TimeoutExpired:
        proc.kill()
        return -1, "", "Command timed out", timeout

def main():
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    experiment_dir = LOGS_BASE_DIR / f"PathExperiment_{timestamp}"
    experiment_dir.mkdir(parents=True, exist_ok=True)
    report_file = experiment_dir / "Path_Resolution_Experiment_Report.json"

    print("=" * 80)
    print("  ANTIGRAVITY CLI PATH RESOLUTION & ANCHOR EXPERIMENT")
    print("=" * 80)
    print(f"  Workspace Root : {WORKSPACE_ROOT}")
    print(f"  Subdirectory   : {SUBDIR}")
    print(f"  Logs Output    : {experiment_dir}\n")

    results = {
        "timestamp": datetime.datetime.now().isoformat(),
        "workspace_root": str(WORKSPACE_ROOT),
        "test_cases": []
    }

    # CASE 1: CWD at Workspace Root -> stream-json init event examination
    print("[1/3] Kiểm tra Case 1: Khởi chạy agy tại Workspace Root...")
    cmd1 = ["agy", "-p", "Trả lời chính xác từ: ROOT_OK", "--output-format", "stream-json"]
    code1, out1, err1, dur1 = run_cmd(cmd1, cwd=WORKSPACE_ROOT)
    
    init_root = {}
    for line in out1.splitlines():
        if line.strip().startswith("{") and line.strip().endswith("}"):
            try:
                evt = json.loads(line)
                if evt.get("event") == "init":
                    init_root = evt.get("init", {})
                    break
            except Exception:
                pass
    
    case1_data = {
        "case_id": "CASE_1_ROOT_CWD",
        "launch_cwd": str(WORKSPACE_ROOT),
        "exit_code": code1,
        "duration_seconds": dur1,
        "engine_reported_cwd": init_root.get("cwd", "UNKNOWN"),
        "is_matching_workspace_root": init_root.get("cwd", "").replace("/", "\\").lower() == str(WORKSPACE_ROOT).lower()
    }
    results["test_cases"].append(case1_data)
    print(f"      Engine reported CWD: {init_root.get('cwd')}")
    print(f"      Khớp Workspace Root: {case1_data['is_matching_workspace_root']}\n")

    # CASE 2: CWD at Subdirectory -> stream-json init event & walk-up check
    print("[2/3] Kiểm tra Case 2: Khởi chạy agy tại Thư mục con (Tests/Agy)...")
    cmd2 = ["agy", "-p", "Trả lời chính xác từ: SUBDIR_OK", "--output-format", "stream-json"]
    code2, out2, err2, dur2 = run_cmd(cmd2, cwd=SUBDIR)

    init_sub = {}
    for line in out2.splitlines():
        if line.strip().startswith("{") and line.strip().endswith("}"):
            try:
                evt = json.loads(line)
                if evt.get("event") == "init":
                    init_sub = evt.get("init", {})
                    break
            except Exception:
                pass

    case2_data = {
        "case_id": "CASE_2_SUBDIR_CWD",
        "launch_cwd": str(SUBDIR),
        "exit_code": code2,
        "duration_seconds": dur2,
        "engine_reported_cwd": init_sub.get("cwd", "UNKNOWN"),
        "is_cwd_isolated": init_sub.get("cwd", "").replace("/", "\\").lower() == str(SUBDIR).lower()
    }
    results["test_cases"].append(case2_data)
    print(f"      Engine reported CWD: {init_sub.get('cwd')}")
    print(f"      CWD định vị tại thư mục con: {case2_data['is_cwd_isolated']}\n")

    # CASE 3: Prompt referencing relative path from Root without absolute path
    print("[3/3] Kiểm tra Case 3: Prompt yêu cầu đọc tên skill trong .agents/skills/rule-governance-analyzer/SKILL.md bằng đường dẫn tương đối...")
    prompt3 = "Dựa vào file .agents/skills/rule-governance-analyzer/SKILL.md, hãy cho biết trường name trong frontmatter là gì? Chỉ trả lời duy nhất tên đó."
    cmd3 = ["agy", "-p", prompt3, "--output-format", "json", "--dangerously-skip-permissions"]
    code3, out3, err3, dur3 = run_cmd(cmd3, cwd=WORKSPACE_ROOT, timeout=180)

    model_resp = ""
    status3 = "FAILED"
    try:
        data3 = json.loads(out3)
        status3 = data3.get("status", "UNKNOWN")
        model_resp = data3.get("response", "").strip()
    except Exception as e:
        model_resp = f"Parse Error: {e} | Raw: {out3}"

    is_success = "rule-governance-analyzer" in model_resp.lower()
    case3_data = {
        "case_id": "CASE_3_RELATIVE_PATH_UNDERSTANDING",
        "prompt": prompt3,
        "exit_code": code3,
        "status": status3,
        "duration_seconds": dur3,
        "model_response": model_resp,
        "is_successful": is_success
    }
    results["test_cases"].append(case3_data)
    print(f"      Status: {status3} | Duration: {dur3}s")
    print(f"      Model Response: {model_resp}")
    print(f"      Nhận diện chính xác Skill từ Relative Path: {is_success}\n")

    # Save to JSON
    with open(report_file, "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)

    print("=" * 80)
    print(f"  THỰC NGHIỆM HOÀN TẤT. Báo cáo JSON: {report_file}")
    print("=" * 80)

if __name__ == "__main__":
    main()
