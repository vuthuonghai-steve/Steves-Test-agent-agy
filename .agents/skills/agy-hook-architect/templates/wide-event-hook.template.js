/**
 * wide-event-hook.template.js
 * Template xử lý Antigravity Lifecycle Hook theo mẫu Wide Event (Canonical Log Line).
 * Tuân thủ:
 * - Antigravity Hook I/O Contract: Đọc stdin JSON (protojson camelCase), xuất stdout JSON theo event.
 * - logging-best-practices: Đo DurationMs, thu thập High Cardinality & High Dimensionality, multi-sink.
 */

const fs = require('fs');
const path = require('path');
const { performance } = require('perf_hooks');

const startTime = performance.now();
const hookType = process.argv[2] || "PreToolUse";

// Template Wide Event / Canonical Log Line
const wideEvent = {
  TimestampUtc: new Date().toISOString(),
  Operation: "AgentLifecycleHook",
  HookType: hookType,
  SessionId: "unknown",
  ToolName: "none",
  ToolArgsSummary: {},
  StepIdx: -1,
  ModelName: "unknown",
  DurationMs: 0,
  Status: "Unknown",
  Environment: {
    Platform: process.platform,
    NodeVersion: process.version,
    Pid: process.pid,
    Cwd: process.cwd()
  }
};

let rawInput = "";
try {
  rawInput = fs.readFileSync(0, "utf-8");
  if (rawInput && rawInput.trim()) {
    const payload = JSON.parse(rawInput);
    wideEvent.SessionId = payload.conversationId || "unknown";
    wideEvent.StepIdx = typeof payload.stepIdx === "number" ? payload.stepIdx : -1;
    wideEvent.ModelName = payload.modelName || "unknown";
    wideEvent.WorkspacePaths = payload.workspacePaths || [];
    
    if (payload.toolCall) {
      wideEvent.ToolName = payload.toolCall.name || "unknown";
      wideEvent.ToolArgsSummary = payload.toolCall.args || {};
    }
    if (payload.error) {
      wideEvent.Error = payload.error;
    }
  }
  wideEvent.Status = "Success";
} catch (err) {
  wideEvent.Status = "Error";
  wideEvent.ErrorMessage = err.message;
} finally {
  wideEvent.DurationMs = Math.round((performance.now() - startTime) * 100) / 100;

  // Multi-sink: Ghi ra file NDJSON để phân tích
  try {
    const logDir = path.resolve(process.cwd(), "Tests/Agy/Logs");
    if (!fs.existsSync(logDir)) {
      fs.mkdirSync(logDir, { recursive: true });
    }
    const logFile = path.join(logDir, "wide_events.ndjson");
    fs.appendFileSync(logFile, JSON.stringify(wideEvent) + "\n", "utf-8");
  } catch (e) {
    // Fail-safe sink: không làm gián đoạn luồng agent
  }

  // Antigravity Hook Contract ra stdout
  if (hookType === "PostToolUse") {
    process.stdout.write(JSON.stringify({}) + "\n");
  } else if (hookType === "Stop") {
    // Trả về {"decision": "allow"} hoặc {"decision": "continue", "reason": "..."}
    process.stdout.write(JSON.stringify({ decision: "allow" }) + "\n");
  } else if (hookType === "PreInvocation" || hookType === "PostInvocation") {
    // Trả về injectSteps
    process.stdout.write(JSON.stringify({ injectSteps: [] }) + "\n");
  } else {
    // Mặc định PreToolUse
    process.stdout.write(JSON.stringify({
      decision: "allow",
      reason: "Wide event telemetry captured successfully"
    }) + "\n");
  }
}
