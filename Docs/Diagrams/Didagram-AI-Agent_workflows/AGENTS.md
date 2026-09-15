# 🧭 AGENTS.md — AI Agent Workflows & Layer Architecture

## 🎯 Mục Tiêu Cốt Lõi (North Star)
Quản trị, phân tích thiết kế và chuẩn hóa toàn bộ tài liệu kiến trúc trực quan (Visual Architecture Specs) cho hệ thống AI Agent: từ bức tranh tổng quan (High-Level System Context) đến chi tiết phân lớp (Deep Layer Workflows).

## ⚙️ Chức Năng Của Thư Mục
- **Mô hình hóa Kiến trúc Đa tầng**: Phân định ranh giới rõ ràng giữa các Layer: Cognitive (Nhận thức), Orchestration (Điều phối), Execution/Skill (Thực thi) và Governance/Guardrails (Kiểm soát).
- **Bộ ba Đồng bộ Bắt buộc (Trio Artifacts)**: Mỗi kiến trúc chuẩn phải duy trì đồng bộ bộ ba tài liệu:
  - `*.drawio`: Sơ đồ trực quan chuẩn hóa (Flows, Components, Boundaries).
  - `*.md`: Đặc tả kỹ thuật chi tiết, logic quyết định, Data Contract và Failure Modes.
  - `*.audit.json`: Nhật ký kiểm định chất lượng, rà soát xung đột và versioning.
- **Điều hướng Luồng Tương tác**: Chuẩn hóa chuỗi phản xạ (Pre-action Thinking, Dispatcher, Tool Execution, Fallback Paths) giữa User, Orchestrator và Subagents.

## 🚀 Mục Tiêu Hướng Tới Cần Đạt Được
1. **Bao phủ Toàn diện (Layer Coverage)**: Thiết lập danh mục tài liệu kiến trúc hoàn chỉnh cho cả tổng quan hệ thống lẫn từng layer chuyên biệt.
2. **Khớp nối Thực tế (Zero Semantic Void)**: Sơ đồ trực quan phải phản ánh trung thực 100% codebase, API contracts và runtime hooks; cấm vẽ luồng giả định.
3. **Thiết kế Phòng thủ (Defensive by Design)**: Mọi workflow bắt buộc thể hiện rõ cơ chế xử lý lỗi, Fallback Mode và bán kính ảnh hưởng (Blast Radius).
4. **Cơ chế Bàn giao Nhị phân (Binary Gate)**: Nghiệm thu hoàn tất chỉ khi có sự đồng bộ tuyệt đối giữa sơ đồ đồ họa (`.drawio`) và tài liệu đặc tả (`.md`).
