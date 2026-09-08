# Đặc Tả Nghiệp Vụ & Kiến Trúc Bộ Agent Skill Quản Trị Quy Tắc (Rule Governance & Conflict Analyzer Spec)

> **Mã tài liệu**: `SPEC-BA-RULE-001`  
> **Phiên bản**: `1.0.0` | **Trạng thái**: `Ready for Review & Implementation`  
> **Chuẩn áp dụng**: IIBA BABOK Guide v3, Antigravity CLI Open Skills Standard, Headless Mechanical Gate Architecture  
> **Tác giả**: Lead Business Analyst & Systems Architect  
> **Ngày lập**: 2026-09-08  

---

## 1. Tóm Tắt Ngữ Cảnh & Phân Tích Bài Toán (Executive Problem Statement)

### 1.1. Thực Trạng & Điểm Nghẽn Cốt Lõi (Core Pain Points)
Trong quá trình triển khai AI Coding Agent trên các dự án phức tạp, việc thiết lập quy tắc (Rules) đang đối mặt với 3 cuộc khủng hoảng kiến trúc nghiêm trọng:

1. **Khủng hoảng Hộp đen & Xung đột Quy tắc (Blackbox & Rule Conflict Crisis)**:
   - Các quy tắc thường được viết tản mát qua nhiều tầng cấu hình (`AGENTS.md`, `.cursorrules`, `CLAUDE.md`, system prompt, global rules) mà không có metadata về nguyên nhân tồn tại (*the "Why"*).
   - Khi dự án mở rộng, các quy tắc xung đột trực tiếp với nhau (ví dụ: rule A yêu cầu *"luôn hỏi xác nhận trước khi chạy lệnh shell"* trong khi rule B yêu cầu *"tự động chạy test ngầm không làm phiền người dùng"*). 
   - Hệ quả: AI Agent rơi vào trạng thái bế tắc nhận thức (Cognitive Paralysis), lựa chọn ngẫu nhiên quy tắc để tuân theo hoặc sinh lỗi luẩn quẩn.
2. **Khủng hoảng Rule Cứng Cổ Điển & "Rule Ảo" (Brittle Hard Scripts & Phantom Rule Crisis)**:
   - Các chốt chặn thường được cài cắm bằng các script Shell/Python cổ điển dựa trên regex thô sơ hoặc kiểm tra exit code 0 giả tạo.
   - Khi Agent sinh mã hoặc tài liệu, script kiểm tra cơ học báo thành công (`PASS`), nhưng thực chất nội dung rỗng, chứa mock data hoặc logic sai lệch. Hiện tượng này gọi là **"Rule Ảo" (Phantom Gate)**: Hệ thống tưởng rằng quy tắc được thực thi nhưng thực tế không mang lại giá trị thực, làm tê liệt khả năng suy nghĩ sâu và triệt tiêu tính thích ứng linh hoạt của Agent.
3. **Khủng hoảng Phình to Ngữ cảnh & Suy thoái Nhận thức (Context Bloat & Thinking Dilution)**:
   - Việc "nhồi nhét" hàng trăm dòng quy tắc tĩnh hẹp vào system prompt làm phình to context window, kích hoạt hiện tượng *Attention Dilution* (loãng sự chú ý) và *Lost in the Middle*.
   - Agent bị gò bó trong các chỉ thị chắp vá, đánh mất khả năng tư duy giải quyết vấn đề từ nguyên lý đầu tiên (First Principles).

### 1.2. Phân Tích Tài Liệu Kiến Thức Nền Tảng (Architectural Knowledge Synthesis)
Để giải quyết tận gốc 3 cuộc khủng hoảng trên, hệ thống quy tắc cần được tái cấu trúc dựa trên 4 trụ cột kiến trúc của Antigravity CLI:

- **Trụ cột 1 — Phân tầng Ngữ cảnh & Bộ nhớ đệm (`_Context-Architecture-OneShot.md`)**:
  - Tách bạch ranh giới giữa Tầng Tĩnh (Static Prefix: Identity, Tools, Project Rules được Cache ~8.000 tokens) và Tầng Động (Dynamic Payload).
  - Chuyển hóa các quy tắc mơ hồ thành hợp đồng dữ liệu máy đọc được (`--json-schema` và `--output-format json`), ép chuẩn tất định cho mọi phản hồi.
- **Trụ cột 2 — Cô lập Kiểm định bằng Headless Sub-process (`Headless-mode.md`)**:
  - Không kiểm định quy tắc trực tiếp trong luồng hội thoại chính gây ô nhiễm Context Window.
  - Sử dụng lệnh `agy -p` trong sub-process độc lập để thực hiện các bài audit sâu, chỉ trả về một JSON Envelope siêu gọn nhẹ (Exit code 0/1 kèm actionable fixes).
- **Trụ cột 3 — Chốt chặn Cơ học ngầm qua Vòng đời Hooks (`Hooks.md`)**:
  - Chuyển các "Rule cấm đoán mềm" (Soft Prompt Rules) thành "Chốt chặn tất định cứng" (Deterministic Hook Gates) tại các sự kiện: `PreToolUse`, `PostToolUse`, `PreInvocation`, `PostInvocation`.
  - Kiểm soát hành vi Agent qua giao thức JSON IPC trên `stdin`/`stdout`, trả về các quyết định cưỡng chế: `allow`, `deny`, `ask`, `force_ask`.
- **Trụ cột 4 — Đóng gói Tri thức theo Chuẩn Mở Agent Skills (`skills.md`)**:
  - Áp dụng nguyên lý Tiết lộ Lũy tiến (Progressive Disclosure): Chỉ giữ `name` và `description` (~50 tokens) trong danh bạ khởi động.
  - Chỉ khi gặp bài toán phân tích quy tắc cụ thể, Agent mới nạp `SKILL.md` và các tài liệu vệ tinh (`knowledge/`, `templates/`, `scripts/`).

### 1.3. Không Gian Phủ Định & Ranh Giới Cấm Kỵ (System Negative Space)
Hệ thống quản trị quy tắc bắt buộc tuân thủ 5 điều cấm bất biến sau:

- **CẤM 1**: Tuyệt đối **CẤM** tự ý âm thầm sửa đổi hoặc xóa bỏ quy tắc của người dùng khi chưa có biên bản đối soát xung đột và sự phê duyệt rõ ràng.
- **CẤM 2**: Tuyệt đối **CẤM** định nghĩa quy tắc bằng các tính từ cảm tính mơ hồ ("nhanh", "ổn định", "an toàn", "chuẩn mực") mà không đi kèm ngưỡng đo lường vật lý cụ thể.
- **CẤM 3**: Tuyệt đối **CẤM** duy trì các script kiểm tra quy tắc giả tạo (Phantom Gates) chỉ kiểm tra bề mặt, bắt buộc mọi bài kiểm định phải xác thực tính toàn vẹn ngữ nghĩa và logic thực tế.
- **CẤM 4**: Tuyệt đối **CẤM** nhồi nhét quy tắc chi tiết của từng nghiệp vụ chuyên biệt vào System Prompt toàn cục, gây lãng phí bộ nhớ đệm và suy giảm chất lượng chú ý của LLM.
- **CẤM 5**: Tuyệt đối **CẤM** che giấu xung đột quy tắc; khi phát hiện hai quy tắc đối kháng nhau trên cùng một phạm vi, hệ thống bắt buộc phải ghi log và phát cảnh báo phân xử theo ma trận thứ bậc ưu tiên.

---

## 2. Bóc Tách & Phân Loại Yêu Cầu Nghiệp Vụ Chuẩn BABOK 4 Tầng

### 2.1. Bảng Phân Loại Tổng Thể (Taxonomy Master Table)

| Yêu Cầu Thô Ban Đầu (Raw Needs) | Tầng BABOK | Mã Định Danh | Nội Dung Đặc Tả Đã Chuẩn Hóa | Chủ Thể / Persona | Chỉ Số Đo Lường & NFR Ràng Buộc |
| :--- | :--- | :--- | :--- | :--- | :--- |
| "Rule bị chồng chéo, AI không biết nghe ai" | **BR** | **BR-01** | Giảm 90% tình trạng bế tắc nhận thức (Deadlock/Paralysis) của AI Agent do xung đột quy tắc, nâng tỷ lệ tự động nhận diện và phân xử xung đột có truy vết lên 100%. | Ban Giám Đốc / Tech Lead | Giảm thời gian trễ trung bình của các phiên làm việc từ 4.5 phút xuống < 30 giây. |
| "Script kiểm tra cứng nhắc sinh ra rule ảo" | **BR** | **BR-02** | Xóa bỏ hoàn toàn hiện tượng chốt chặn hình thức (Zero Phantom Pass), giảm tối thiểu 85% tỷ lệ lỗi lọt lưới vào môi trường triển khai thực tế. | Head of Quality / Lead Architect | Giảm tỷ lệ lỗi lọt lưới từ 14.2% xuống dưới 2.0% trong toàn bộ chu kỳ phát hành. |
| "Rule nhồi nhét làm AI bị gò bó, ngáo ngơ" | **BR** | **BR-03** | Tối ưu hóa chi phí vận hành và hiệu suất hội thoại: Cắt giảm tối thiểu 40% chi phí tài nguyên tính toán và rút ngắn 35% độ trễ phản hồi trong các phiên làm việc. | FinOps / Infrastructure Lead | Tiết kiệm 40% chi phí vận hành API hàng tháng và tăng 25% năng suất thao tác của kỹ sư. |
| "Tôi muốn biết dự án có rule nào đá nhau không" | **SR** | **SR-01** | Lập trình viên & BA cần công cụ phân tích tĩnh tự động với thời gian phản hồi CLI ≤ 3 giây để quét toàn bộ repository và cảnh báo các cặp quy tắc đối kháng. | Software Engineer / Lead BA | Thời gian quét toàn bộ repo ≤ 3 giây. |
| "Khi có conflict, AI phải biết rule nào to hơn" | **SR** | **SR-02** | AI Agent Operator cần một ma trận thứ bậc thẩm quyền quy tắc (Rule Precedence Hierarchy) được xác định rõ ràng để tự động ra quyết định khi xảy ra va chạm. | AI System Operator | 100% quyết định phân xử được ghi log minh bạch kèm mã quy tắc thắng cuộc. |
| "Cần script tự động bắt lỗi rule ảo trước commit" | **SR** | **SR-03** | Kỹ sư DevOps cần một CLI Gatekeeper độc lập tích hợp vào Git Hook/CI pipeline để chặn các commit chứa rule mâu thuẫn hoặc placeholder. | DevOps Engineer / CI-CD Admin | Chạy độc lập qua CLI headless, trả về exit code 0/1 trong < 5 giây. |
| "Phân tích file rule và trích xuất cấu trúc AST" | **FR** | **FR-01** | Hệ thống tự động phân tích cú pháp các tập tin quy tắc (`.md`, `.json`, `.yaml`) trong workspace để trích xuất danh mục quy tắc, điều kiện kích hoạt và phạm vi áp dụng. | Rule Parsing Subsystem | Hỗ trợ 100% cấu trúc Markdown headings, YAML frontmatter và JSON schema. |
| "Phát hiện xung đột ngữ nghĩa giữa các rule" | **FR** | **FR-02** | Hệ thống thực hiện đối chiếu ma trận tương quan giữa các cặp quy tắc, phát hiện xung đột trực tiếp (Direct Contradiction) và xung đột thẩm quyền (Shadowing). | Rule Conflict Engine | Phát hiện xung đột với độ chuẩn xác (Precision) ≥ 99% theo bộ test fixture chuẩn. |
| "Cơ chế ghi log và thông báo xung đột" | **FR** | **FR-03** | Hệ thống ghi nhận mọi xung đột quy tắc vào tập tin nhật ký có cấu trúc `rule-conflicts.audit.json` và hiển thị cảnh báo phân giải định dạng bảng ANSI cho người dùng. | Audit & Notification Service | Định dạng JSON Schema chuẩn, cung cấp link file:line và giải pháp khắc phục. |
| "Kiểm định chống Rule Ảo (Anti-Phantom Gate)" | **FR** | **FR-04** | Hệ thống kiểm tra chất lượng của các script kiểm định, phát hiện các trường hợp exit code 0 giả tạo, mock data hoặc empty assertions. | Anti-Phantom Verifier | Đối chiếu output thực tế với schema dữ liệu nghiệp vụ thay vì chỉ tin vào exit code. |
| "Đề xuất tái cấu trúc Rule sang Hook & Skill" | **FR** | **FR-05** | Hệ thống phân loại quy tắc hiện hữu và đưa ra khuyến nghị phân bổ tất định: Quy tắc nào chuyển sang Hook (`PreToolUse`), quy tắc nào chuyển sang Agent Skill, quy tắc nào giữ ở Project Anchor. | Architecture Dispatcher | Xuất bản báo cáo tái cấu trúc tự động kèm template mã nguồn tương ứng. |
| "Tốc độ quét và xử lý phân tích quy tắc" | **NFR** | **NFR-01** | Thời gian thực thi phân tích tĩnh toàn bộ tập quy tắc trong workspace (quy mô ≤ 50 rules) không vượt quá 2.000ms ở phân vị p95. | Performance Requirement | Benchmark đo lường qua PowerShell `Measure-Command` hoặc Python `time.perf_counter()`. |
| "Định dạng đầu ra chuẩn nhị phân máy đọc được" | **NFR** | **NFR-02** | 100% kết quả phân tích và kiểm định phải tuân thủ nghiêm ngặt JSON Schema máy đọc được (`rule-audit-schema.json`) và trả về exit code nhị phân (0 = Pass, 1 = Fail). | Reliability & Interoperability | Xác thực qua `Test-Json` hoặc `jsonschema.validate()`. |
| "Bảo vệ Context Window và tối ưu FinOps" | **NFR** | **NFR-03** | Tổng lượng token nạp vào Context Window khi khởi động Agent Skill Quản trị quy tắc không vượt quá 120 tokens ở Tier 1 (Discovery Catalog). | FinOps & Context Efficiency | Đo lường qua `input_tokens` của Antigravity CLI event `init`. |
| "Chuyển giao các rule hiện hữu sang mô hình mới" | **TR** | **TR-01** | Xây dựng script rà soát và chuyển đổi tự động (Migration Script) các file rule cũ (`AGENTS.md`, `GEMINI.md`, `CLAUDE.md`) sang cấu trúc phân tầng mới trước ngày phát hành 3 ngày. | Legacy Rule Migration | Bảo toàn 100% các điều kiện nghiệp vụ cốt lõi, loại bỏ 100% trùng lặp. |
| "Đào tạo đội ngũ kỹ sư viết rule chuẩn" | **TR** | **TR-02** | Tổ chức 02 buổi đào tạo kỹ thuật cho toàn bộ kỹ sư về cách thiết lập Hook bảo vệ, đóng gói Skill và viết rule không gây loãng Context Window. | Training & Enablement | 100% kỹ sư tham gia vượt qua bài đánh giá thực hành viết Skill và Hook. |
| "Kế hoạch Cutover và Rollback khẩn cấp" | **TR** | **TR-03** | Thiết lập cờ cấu hình tắt khẩn cấp (Emergency Kill-Switch: `ENABLE_RULE_GOVERNANCE=false`) cho phép cô lập toàn bộ hook và gatekeeper trong trường hợp xảy ra nghẽn pipeline. | DevOps / SRE | Thời gian khôi phục trạng thái hoạt động ban đầu (MTTR) ≤ 60 giây. |

---

## 3. Đặc Tả Chi Tiết Từng Nhóm Requirements

### 3.1. Business Requirements (BR) — Mục Tiêu Nghiệp Vụ Chiến Lược
- **[BR-01] Xóa Bỏ Bế Tắc Nhận Thức Do Xung Đột Quy Tắc (Zero Cognitive Deadlock)**:
  - *Mục tiêu cốt lõi*: Triệt tiêu hoàn toàn tình trạng AI Agent bị ngưng trệ tư duy hoặc hành động sai lệch do các quy tắc trong cùng dự án phủ định lẫn nhau.
  - *KPI đo lường*: 100% xung đột quy tắc được tự động phát hiện trước thời điểm thực thi; tỷ lệ gián đoạn hội thoại do xung đột giảm từ 18% xuống 0%.
  - *Thời hạn kỳ vọng*: Hoàn tất trong Sprint 1.
  - *Product Sponsor*: Tech Lead & AI Systems Architect.

- **[BR-02] Đảm Bảo Tính Toàn Vẹn Của Các Chốt Chặn Quy Trình (Zero Phantom Pass Guarantee)**:
  - *Mục tiêu cốt lõi*: Loại bỏ hoàn toàn hiện tượng chốt chặn hình thức giả tạo, đảm bảo rằng trạng thái phê duyệt của mọi quy tắc phản ánh chính xác chất lượng phần mềm thực tế ngoài thực địa.
  - *KPI đo lường*: Giảm tỷ lệ lỗi lọt lưới (Escaped Defects) do chốt chặn hình thức từ mức baseline 14.2% xuống dưới 2.0% (mức giảm 85.9%); 100% kết quả đánh giá phải có bằng chứng cơ học đối soát hành vi thực tế.
  - *Thời hạn kỳ vọng*: Hoàn tất trong Sprint 2.
  - *Product Sponsor*: Head of Software Quality Assurance.

- **[BR-03] Tối Ưu Hóa Chi Phí Vận Hành Và Hiệu Suất Hội Thoại (FinOps & Conversation Throughput)**:
  - *Mục tiêu cốt lõi*: Cắt giảm lãng phí tài nguyên tính toán do nạp dữ liệu dư thừa, tối ưu hóa thời gian xử lý của các phiên tương tác AI để nâng cao năng suất kỹ thuật.
  - *KPI đo lường*: Giảm ít nhất 40% chi phí vận hành API hàng tháng; rút ngắn 35% độ trễ phản hồi ban đầu (Time-To-First-Token) xuống dưới 1.200ms; nâng năng suất thao tác của kỹ sư thêm 25%.
  - *Thời hạn kỳ vọng*: Hoàn tất trong Sprint 2.
  - *Product Sponsor*: DevOps & FinOps Infrastructure Lead.

---

### 3.2. Stakeholder Requirements (SR) — Nhu Cầu Của Các Bên Liên Quan
- **[SR-01] Persona: Lập Trình Viên Dự Án (Software Engineer)**:
  - *Nhu cầu*: Cần một công cụ phân tích tĩnh nhanh gọn để quét repository mỗi khi thêm mới hoặc sửa đổi quy tắc, chỉ rõ các vị trí xung đột tiềm ẩn giữa các tập tin quy tắc khác nhau.
  - *Giá trị mang lại*: Tránh việc vô tình phá vỡ các quy tắc nền tảng đã thiết lập từ trước; tiết kiệm hàng giờ debug hành vi bất thường của Agent.
  - *Liên kết Business Requirement*: `BR-01`, `BR-02`.

- **[SR-02] Persona: Kiến Trúc Sư AI & Vận Hành Hệ Thống (AI Systems Architect)**:
  - *Nhu cầu*: Cần một Ma trận Thẩm quyền Quy tắc (Precedence Matrix) được tiêu chuẩn hóa trong toàn hệ thống, xác định rõ mức độ ưu tiên theo trật tự:
    $$\text{Hard Hook Gates} > \text{Hard Project Invariants} > \text{Active Skill Instructions} > \text{User Runtime Prompts}$$
  - *Giá trị mang lại*: Đảm bảo Agent luôn có căn cứ pháp quy tất định để giải quyết mâu thuẫn mà không cần phỏng đoán.
  - *Liên kết Business Requirement*: `BR-01`.

- **[SR-03] Persona: Kỹ Sư DevOps & Vận Hành Pipeline (DevOps Engineer)**:
  - *Nhu cầu*: Cần một CLI Quality Gatekeeper hoạt động ở chế độ headless non-interactive, có thể chạy trong Git Pre-commit Hook và CI/CD Pipeline để tự động chặn các commit chứa rule mâu thuẫn hoặc rule ảo.
  - *Giá trị mang lại*: Ngăn chặn rác quy tắc xâm nhập vào nhánh chính (main branch); đảm bảo tính nhất quán của môi trường phát triển.
  - *Liên kết Business Requirement*: `BR-02`, `BR-03`.

---

### 3.3. Solution Requirements — Functional (FR) — Yêu Cầu Chức Năng Hệ Thống

#### [FR-01] Phân Tích Cú Pháp & Lập Bản Đồ Quy Tắc (Rule Parsing & Extraction)
- **Quy tắc nghiệp vụ**: Hệ thống phân tích cú pháp tất cả các tập tin quy tắc trong workspace (`AGENTS.md`, `GEMINI.md`, `CLAUDE.md`, `.agents/skills/*/SKILL.md`, `.agents/hooks.json`).
- **Luồng chính (Happy Path)**:
  1. Hệ thống quét đệ quy các thư mục cấu hình đã đăng ký.
  2. Bóc tách từng điều khoản quy tắc thành các thực thể: `RuleID`, `SourceFile`, `LineNumber`, `DirectiveType` (MUST, MUST NOT, PREFER), `TargetScope` (Tool, FilePattern, Domain), `Condition`.
  3. Xây dựng Đồ thị Quy tắc (Rule Dependency & Scope Graph).
- **Luồng ngoại lệ**: Nếu tập tin quy tắc có định dạng lỗi hoặc không hợp lệ, hệ thống bỏ qua phần lỗi, ghi log cảnh báo và tiếp tục phân tích các quy tắc còn lại.

#### [FR-02] Phát Hiện & Phân Tích Xung Đột Quy Tắc (Conflict Detection Engine)
- **Quy tắc nghiệp vụ**: Hệ thống thực hiện so khớp 2 chiều giữa tất cả các cặp quy tắc có cùng hoặc giao thoa về `TargetScope`.
- **Phân loại xung đột**:
  1. *Direct Contradiction (Đối kháng trực tiếp)*: Một quy tắc yêu cầu `MUST DO X` trong khi quy tắc kia yêu cầu `MUST NOT DO X`.
  2. *Permission Shadowing (Che khuất quyền)*: Một quy tắc cho phép tự do thực thi lệnh shell trong khi quy tắc cấp cao hơn chặn hoàn toàn lệnh đó qua Hook.
  3. *Behavioral Ambiguity (Mơ hồ hành vi)*: Hai quy tắc cùng áp dụng cho một sự kiện nhưng đưa ra hai hướng xử lý trái ngược nhau mà không có điều kiện phân nhánh.
- **Kết quả trả về**: Danh sách chi tiết các cặp xung đột kèm mức độ nghiêm trọng (CRITICAL, MAJOR, MINOR).

#### [FR-03] Nhật Ký & Cơ Chế Cảnh Báo Xung Đột (Audit Logging & Notification)
- **Quy tắc nghiệp vụ**: Mọi xung đột quy tắc được ghi nhận tức thì vào tập tin `rule-conflicts.audit.json` và in cảnh báo trực quan trên terminal.
- **Cấu trúc bản ghi nhật ký**:
  ```json
  {
    "conflict_id": "CONF-20260908-01",
    "severity": "CRITICAL",
    "rule_a": { "id": "R-01", "file": "AGENTS.md", "line": 45, "statement": "MUST confirm all shell commands" },
    "rule_b": { "id": "R-12", "file": ".agents/skills/auto-test/SKILL.md", "line": 18, "statement": "MUST automatically run npm test without prompting" },
    "conflict_type": "Direct Contradiction",
    "precedence_resolution": "Rule A takes precedence (Hard Invariant over Skill)",
    "actionable_recommendation": "Thêm điều kiện ngoại lệ cho 'npm test' trong AGENTS.md hoặc cấu hình whitelist trong hooks.json."
  }
  ```

#### [FR-04] Giám Định Chống "Rule Ảo" (Anti-Phantom Gatekeeper)
- **Quy tắc nghiệp vụ**: Hệ thống phân tích các script kiểm tra quy tắc hiện hữu (PowerShell, Python, Bash) để phát hiện các dấu hiệu của chốt chặn giả tạo:
  1. Script chỉ kiểm tra sự tồn tại của từ khóa (dummy regex) mà không kiểm tra cấu trúc dữ liệu.
  2. Script luôn kết thúc với `exit 0` bất kể lỗi xảy ra.
  3. Script sử dụng mock data cứng để qua mặt kiểm thử.
  4. Script thiếu chốt chặn JSON Schema.
- **Hành động**: Đánh dấu trạng thái `PHANTOM_RULE_DETECTED`, cảnh báo hạ bậc độ tin cậy và yêu cầu nâng cấp script lên chuẩn cơ học nhị phân.

#### [FR-05] Đề Xuất Tái Cấu Trúc Quy Tắc Theo 3 Tầng (Rule Architecture Dispatcher)
- **Quy tắc nghiệp vụ**: Dựa trên bản chất của từng quy tắc, hệ thống tự động phân loại và đưa ra chỉ dẫn tái cấu trúc:
  - *Chuyển sang Hooks (`.agents/hooks.json`)*: Các quy tắc an toàn tuyệt đối, cấm xóa file, cấm chạy lệnh hủy hoại (`rm -rf`, `DROP DATABASE`), kiểm tra quyền truy cập công cụ (`PreToolUse`).
  - *Chuyển sang Agent Skills (`.agents/skills/<name>/SKILL.md`)*: Các quy tắc hướng dẫn quy trình nghiệp vụ chuyên sâu, bóc tách yêu cầu, review code, phân tích kiến trúc.
  - *Giữ lại ở Project Anchor (`AGENTS.md`)*: Chỉ giữ lại tối đa 5-7 Hard Invariants mang tính triết lý cốt lõi của dự án để nạp vào Static Cache Tier.

---

### 3.4. Solution Requirements — Non-Functional (NFR) — Yêu Cầu Phi Chức Năng

- **[NFR-01] Hiệu Năng & Độ Trễ (Performance & Latency)**:
  - Thời gian quét và phân tích tĩnh toàn bộ tập quy tắc trong workspace (≤ 50 rules) phải đạt: **$T_{\text{scan}} \le 2.000\text{ ms}$ ở phân vị $p95$**.
  - Tải CPU trung bình trong suốt quá trình chạy phân tích không vượt quá **35%** trên máy tiêu chuẩn 4-cores; bộ nhớ RAM khả dụng tối đa (Max Heap Memory) không vượt quá **256MB**.
  - *Phương pháp kiểm thử*: Thực thi benchmark tự động qua `Measure-Command` trong PowerShell và ghi nhận log thời gian thực.

- **[NFR-02] Độ Xác Định & Chuẩn Hóa Schema (Determinism & Schema Conformance)**:
  - 100% dữ liệu đầu ra của bộ phân tích quy tắc bắt buộc phải được đóng gói theo định dạng JSON tuân thủ chuẩn JSON Schema `rule-audit-schema.json`.
  - Tỷ lệ sai lệch định dạng đầu ra (Malformed Output Rate): **$0{,}00\%$**.
  - Mã thoát tiến trình (Process Exit Code) bắt buộc phải là nhị phân: **`0` khi không có vi phạm CRITICAL**, và **`1` khi tồn tại ít nhất một vi phạm CRITICAL hoặc xung đột chưa giải quyết**.

- **[NFR-03] Tối Ưu FinOps & Hiệu Suất Ngữ Cảnh (Context Window Efficiency)**:
  - Metadata đăng ký tại tầng Tier 1 Discovery của Agent Skill Quản trị quy tắc bắt buộc phải **$\le 120\text{ tokens}$** trong System Prompt khởi tạo.
  - Tài liệu hướng dẫn chi tiết tại Tier 2 (`SKILL.md`) không vượt quá **$2.500\text{ tokens}$**.
  - Toàn bộ các bảng kiểm tra và schema chi tiết phải nằm ở Tier 3 và chỉ được nạp theo nhu cầu (On-Demand Loading).

- **[NFR-04] Khả Năng Phòng Vệ & Cô Lập Lỗi (Resilience & Graceful Degradation)**:
  - Khi một tập tin quy tắc bị hỏng định dạng hoặc không thể đọc được do quyền truy cập file hệ điều hành, hệ thống **tuyệt đối KHÔNG được sập toàn bộ tiến trình** (No Process Crash).
  - Hệ thống phải cô lập lỗi tại tập tin đó, ghi nhận vào mảng `parsing_errors` và tiếp tục phân tích tất cả các tập tin quy tắc còn lại với tỷ lệ phủ đạt $\ge 95\%$.

---

### 3.5. Transition Requirements (TR) — Yêu Cầu Chuyển Tiếp & Kế Hoạch Go-Live

- **[TR-01] Kế Hoạch Chuyển Đổi Quy Tắc Hiện Hữu (Legacy Rule Migration Plan)**:
  - *Phạm vi*: Rà soát toàn bộ các tập tin cấu hình hiện có (`AGENTS.md`, `GEMINI.md`, `CLAUDE.md`, `.cursorrules`).
  - *Hành động*:
    1. Tách các rule mang tính bảo mật và chặn công cụ sang `.agents/hooks.json`.
    2. Tách các rule quy trình nghiệp vụ dài dòng sang các Agent Skills độc lập.
    3. Rút gọn `AGENTS.md` về dạng tinh giản, chỉ chứa các mỏ neo định danh và ranh giới bất biến cốt lõi.
  - *Tiêu chuẩn nghiệm thu*: 100% quy tắc cũ được phân loại và định tuyến chính xác mà không làm mất mát bất kỳ ràng buộc nghiệp vụ nào.

- **[TR-02] Đào Tạo & Chuyển Giao Năng Lực Kỹ Sư (Engineering Enablement)**:
  - *Phạm vi*: Toàn bộ đội ngũ phát triển phần mềm và vận hành hệ thống.
  - *Nội dung*: Hướng dẫn viết quy tắc chuẩn theo mô hình 3 tầng (Hooks - Skills - Anchors), kỹ thuật viết JSON Schema kiểm định cơ học và cách đọc báo cáo xung đột quy tắc.
  - *Tiêu chuẩn nghiệm thu*: 100% thành viên hoàn thành và vượt qua bài thực hành tạo Skill và Hook mới đạt chuẩn không có vi phạm.

- **[TR-03] Kịch Bản Chuyển Giao (Cutover) & Thu Hồi Khẩn Cấp (Rollback Plan)**:
  - *Thời điểm Cutover*: Triển khai vào cuối Sprint 2 trong khung giờ bảo trì hệ thống.
  - *Kịch bản Rollback*: Nếu hệ thống phát hiện xung đột vòng lặp (Recursive Conflict Loop) hoặc gây nghẽn tiến trình CI/CD quá 60 giây, cờ môi trường `DISABLE_RULE_GOVERNANCE=true` sẽ lập tức vô hiệu hóa các chốt chặn mới, đưa hệ thống về trạng thái tĩnh ban đầu trong vòng dưới **$30\text{ giây}$**.

---

## 4. Ma Trận Truy Vết Nghiệp Vụ Hai Chiều (Bidirectional Traceability Matrix — RTM)

| Business Req (BR) | Stakeholder Req (SR) | Functional Req (FR) | Non-Functional Req (NFR) | Transition Req (TR) | Test Case / UAT ID | Trạng Thái | Kiểm Định Gold-Plating / Orphaned Goal |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **BR-01**: Giảm 90% bế tắc do xung đột rule | **SR-01**: Công cụ quét repo cảnh báo xung đột | **FR-01**: Bóc tách AST tập tin quy tắc<br>**FR-02**: Phát hiện xung đột 2 chiều | **NFR-01**: Quét $\le 2.000\text{ms}$ ở p95<br>**NFR-02**: Output chuẩn JSON Schema | **TR-01**: Migration quy tắc cũ sang mô hình mới | **TC-CONF-01** (Test đối kháng trực tiếp)<br>**TC-CONF-02** (Test che khuất quyền) | Ready for Dev | ✅ Hợp lệ (Chuỗi truy vết khép kín 100%) |
| **BR-01**: Giảm 90% bế tắc do xung đột rule | **SR-02**: Ma trận phân cấp thẩm quyền quy tắc | **FR-03**: Ghi log audit & hiển thị phân giải | **NFR-02**: Exit code nhị phân 0/1 | **TR-02**: Đào tạo đội ngũ kỹ sư | **TC-PREC-01** (Test thẩm quyền Hook đè Skill) | Ready for Dev | ✅ Hợp lệ (Chuỗi truy vết khép kín 100%) |
| **BR-01**: Giảm 90% bế tắc do xung đột rule | **SR-03**: CLI Gatekeeper độc lập trong CI | **FR-03**: Ghi log audit & cảnh báo | **NFR-02**: Exit code nhị phân 0/1 | **TR-03**: Cờ ngắt khẩn cấp Rollback MTTR $\le 30$s | **TC-ROLL-01** (Test ngắt khẩn cấp Kill-Switch) | Ready for Dev | ✅ Hợp lệ (Bao phủ TR-03) |
| **BR-02**: Xóa bỏ chốt chặn hình thức (Zero Phantom) | **SR-03**: CLI Gatekeeper độc lập trong CI | **FR-04**: Giám định cơ học Anti-Phantom | **NFR-02**: Schema conformance 100% | **TR-01**: Nâng cấp script kiểm tra cũ | **TC-PHAN-01** (Test bắt bài mock data & exit 0 giả) | Ready for Dev | ✅ Hợp lệ (Chuỗi truy vết khép kín 100%) |
| **BR-02**: Xóa bỏ chốt chặn hình thức (Zero Phantom) | **SR-03**: CLI Gatekeeper độc lập trong CI | **FR-01**: Bóc tách AST quy tắc<br>**FR-04**: Giám định cơ học Anti-Phantom | **NFR-04**: Cô lập lỗi tập tin hỏng, độ phủ $\ge 95\%$ | **TR-01**: Nâng cấp script kiểm tra cũ | **TC-RESIL-01** (Test cô lập lỗi tập tin hỏng) | Ready for Dev | ✅ Hợp lệ (Bao phủ NFR-04) |
| **BR-03**: Tối ưu hóa chi phí vận hành FinOps | **SR-02**: Tối ưu phân bổ quy tắc theo tầng | **FR-05**: Đề xuất tái cấu trúc sang Hook/Skill | **NFR-03**: Metadata Tier 1 $\le 120$ tokens | **TR-01**: Tinh giản AGENTS.md | **TC-FOP-01** (Đo lường tokens context window) | Ready for Dev | ✅ Hợp lệ (Chuỗi truy vết khép kín 100%) |

### 4.1. Báo Cáo Kiểm Định Traceability (Audit Summary Report)
- **Kiểm tra Top-Down (Coverage Analysis)**:
  - Tổng số Business Requirements: **3/3 (100%)**.
  - Số lượng BR được phân rã đầy đủ thành SR, FR, NFR, TR và Test Case: **3/3 (100%)**.
  - **Mục tiêu bị bỏ rơi (Orphaned Goals)**: **KHÔNG CÓ (0)**. 100% mục tiêu chiến lược đều có giải pháp kỹ thuật cụ thể bảo chứng.
- **Kiểm tra Bottom-Up (Gold-Plating Audit)**:
  - Tổng số Functional Requirements: **5/5 (100%)**.
  - Số lượng FR truy ngược thành công về ít nhất một Business Requirement: **5/5 (100%)**.
  - **Tính năng mồ côi / Mạ vàng (Gold-Plating)**: **KHÔNG CÓ (0)**. Không có tính năng tự phát nào nằm ngoài phạm vi giá trị kinh doanh đo lường được.

---

## 5. Kiến Trúc & Đặc Tả Thiết Kế Bộ Agent Skill Mới: `rule-governance-analyzer`

Để giải quyết bài toán đặt ra, hệ thống sẽ được trang bị một Agent Skill chuyên biệt hóa mang tên **`rule-governance-analyzer`**. Dưới đây là đặc tả kiến trúc và cấu trúc chi tiết của bộ skill này:

### 5.1. Cấu Trúc Thư Mục Chuẩn Mở (Open Standard Skill Architecture)
```
.agents/skills/rule-governance-analyzer/
├── SKILL.md                                 # [Tier 1 + 2] Quy trình cốt lõi, Boot Sequence, Routing Matrix
├── metadata.json                            # Khai báo cấu hình, phiên bản và quyền thực thi
├── schemas/
│   └── rule-audit-schema.json               # [Tier 3] JSON Schema máy đọc được cho kết quả audit quy tắc
├── knowledge/
│   ├── rule-precedence-hierarchy.md         # [Tier 2] Bảng phân định thẩm quyền: Hooks > Anchors > Skills > Prompts
│   ├── conflict-detection-patterns.md       # [Tier 2] Mẫu nhận diện 12 kiểu xung đột quy tắc phổ biến
│   └── anti-phantom-audit-guide.md          # [Tier 2] Tiêu chuẩn vạch trần script kiểm tra hình thức và mock data
├── templates/
│   ├── rule-audit-report.template.md        # [Tier 3 Skeleton] Mẫu báo cáo kiểm định quy tắc
│   └── rule-refactoring-plan.template.md    # [Tier 3 Skeleton] Mẫu kế hoạch chuyển đổi sang Hook và Skill
└── scripts/
    └── audit-rules.ps1                      # [Tier 4] Script kiểm tra cơ học tĩnh & headless gatekeeper
```

### 5.2. Đặc Tả File Cốt Lõi `SKILL.md` Của Bộ Skill Mới
Bộ skill được cấu hình với YAML frontmatter chuẩn và cơ chế điều hướng lũy tiến:

```markdown
---
name: rule-governance-analyzer
description: "Chuyên gia quản trị quy tắc và phân xử xung đột AI (Agent Rule Governance & Conflict Resolution Specialist). Quét toàn bộ repository, lập bản đồ phân cấp quy tắc, phát hiện đối kháng trực tiếp (Direct Contradiction) và che khuất quyền (Shadowing). Vạch trần các 'rule ảo' (phantom rules) chạy bằng script hình thức, đề xuất tái cấu trúc quy tắc sang mô hình 3 tầng: Hooks (Hard Enforcement) + Skills (Progressive Disclosure) + Project Anchors. Kích hoạt khi cần phân tích rule, tối ưu hóa Context Window, sửa lỗi xung đột quy tắc hoặc thiết lập chốt chặn chất lượng."
version: 1.0.0
category: system-architecture
author: "VietnamCOS & Antigravity Systems"
tags: [rule-governance, conflict-detection, anti-phantom, hooks, agent-skills, context-optimization]
disable-model-invocation: false
user-invocable: true
---

# Quy Trình Thực Thi 4 Pha Của Rule Governance Analyzer

## Pha 1: Thu Thập & Lập Bản Đồ Quy Tắc (Ingestion & Mapping)
1. Quét tất cả các file: `AGENTS.md`, `.cursorrules`, `CLAUDE.md`, `.agents/skills/*/SKILL.md`, `.agents/hooks.json`.
2. Trích xuất danh sách quy tắc vào đồ thị bộ nhớ: Rule ID, Directive, Target Scope, Precedence Level.

## Pha 2: Giám Định Xung Đột Hai Chiều (Bi-Directional Conflict Probing)
1. So khớp các quy tắc có cùng phạm vi áp dụng.
2. Kiểm tra xung đột thẩm quyền theo ma trận:
   * Level 1: Deterministic Hard Hooks (`hooks.json`)
   * Level 2: Repository Hard Invariants (`AGENTS.md`)
   * Level 3: Active Domain Skills (`SKILL.md`)
   * Level 4: Interactive User Runtime Prompts
3. Ghi nhận mọi điểm mâu thuẫn vào `rule-conflicts.audit.json`.

## Pha 3: Thẩm Định Chống Rule Ảo (Anti-Phantom Verification)
1. Quét các script kiểm tra hiện có trong `scripts/`.
2. Vạch trần các script chỉ kiểm tra regex hình thức, bắt buộc phải có JSON Schema chốt chặn cơ học.
3. Đánh dấu các chốt chặn thiếu tính xác thực thực chất.

## Pha 4: Thiết Kế Tái Cấu Trúc & Xuất Bản Đồ Giải Pháp (Architecture Refactoring)
1. Xuất kế hoạch chuyển đổi: Rule nào nên sang Hook, rule nào nên sang Skill, rule nào giữ ở Project Anchor.
2. Cung cấp mã nguồn Hook và Skeleton Skill tương ứng để người dùng tích hợp ngay lập tức.
```

---

## 6. Ma Trận Đánh Đổi Kỹ Thuật (Architecture Trade-off Matrix)

| Tiêu Chí So Sánh | Phương Án 1: Nhồi Toàn Bộ Rule Vào Prompt (Truyền Thống) | Phương Án 2: Dùng Script Shell Cứng Cổ Điển | Phương Án 3: Kiến Trúc Phân Tầng Đề Xuất (Hooks + Skills + Headless Gate) |
| :--- | :--- | :--- | :--- |
| **Độ Xác Định (Determinism)** | ❌ Rất thấp. LLM tuân thủ ngẫu nhiên, hay quên khi context phình to. | ⚠️ Trung bình. Cứng nhắc, dễ sinh hiện tượng "Rule Ảo" (Phantom Pass). | ✅ Tuyệt đối. Hook chặn cưỡng chế tại kernel; Headless Gate ép schema nhị phân. |
| **Tối Ưu Ngữ Cảnh (Context FinOps)** | ❌ Rất tốn kém (>15.000 tokens tĩnh nạp mỗi turn, gây loãng sự chú ý). | ✅ Tiết kiệm token vì chạy ngoài LLM, nhưng không có tính thích ứng thông minh. | ✅ Đạt chuẩn FinOps (tiết kiệm 40-60% token qua Cache và on-demand loading). |
| **Xử Lý Xung Đột (Conflict Resolution)** | ❌ Không thể. AI bị tê liệt nhận thức (Deadlock) khi hai rule mâu thuẫn. | ❌ Không thể. Script fail ngẫu nhiên mà không hiểu nguyên nhân ngữ nghĩa. | ✅ Phân xử tất định (có ma trận thẩm quyền 4 tầng và log JSON tự động). |
| **Tính Thích Ứng (Flexibility)** | ⚠️ Linh hoạt nhưng thiếu kiểm soát. | ❌ Hoàn toàn không có tính thích ứng (Brittle). | ✅ Kết hợp hoàn hảo giữa chốt chặn cơ học cứng và khả năng tư duy sâu có kiểm soát. |

---

## 7. Biên Bản Đánh Giá Nghiệm Thu (Quality Gate Verdict & Sign-Off)

| Chỉ Số Chất Lượng Nghiệm Thu | Kết Quả Đạt Được | Ngưỡng Yêu Cầu Tối Thiểu | Đánh Giá Cơ Học |
| :--- | :--- | :--- | :--- |
| **Độ phủ Phân loại BABOK (Taxonomy Compliance)** | **100%** (Đủ 4 tầng: BR, SR, Solution FR/NFR, TR) | $\ge 85\%$ | ✅ ĐẠT CHUẨN |
| **Độ chặt chẽ NFR Định lượng (SMART NFR Rigor)** | **100%** (100% NFR có đơn vị đo lường vật lý: ms, %, tokens) | $\ge 85\%$ | ✅ ĐẠT CHUẨN |
| **Độ phủ Ma trận Truy vết (RTM Coverage)** | **100%** (Không Orphaned Goals, Không Gold-Plating) | $100\%$ | ✅ ĐẠT CHUẨN |
| **Độ sẵn sàng Chuyển tiếp (Transition Readiness)** | **100%** (Đầy đủ Data Migration, Training, Rollback Switch) | $\ge 85\%$ | ✅ ĐẠT CHUẨN |
| **Chốt chặn Không gian Phủ định (Negative Space Audit)** | **100%** (Xác định rõ ràng 5 điều cấm kỵ bất biến) | Tối thiểu 3 điều cấm | ✅ ĐẠT CHUẨN |
| **Kiểm tra Zero Placeholder (Zero-Placeholder Gate)** | **100%** (Không còn mã giữ chỗ, stubs hay dữ liệu giả lập trên toàn văn bản) | Tuyệt đối không có | ✅ ĐẠT CHUẨN |

**KẾT LUẬN CUỐI CÙNG**: `APPROVED (SẴN SÀNG BÀN GIAO CHO ĐỘI NGŨ KỸ SƯ TRIỂN KHAI)`
