#!/usr/bin/env node
/**
 * Unified Antigravity Lifecycle Hook Runner
 * ==============================================================================
 * Bản hợp nhất tinh gọn 100%:
 * - Telemetry & Wide Event Logging (Canonical Log Line V2.1)
 * - Security Guardrail (Chặn lệnh phá hoại dữ liệu)
 * - Ephemeral State Management trong os.tmpdir() (Không ô nhiễm Git repo)
 * - Zero external dependencies (Chỉ dùng built-in Node.js core modules)
 * - Tốc độ thực thi cực hạn (< 15ms per invocation)
 * ==============================================================================
 */

const fs = require('fs');
const path = require('path');
const os = require('os');
const crypto = require('crypto');
const { performance } = require('perf_hooks');

const startTime = performance.now();
const hookType = process.argv[2] || 'PreToolUse';

// ==============================================================================
// 1. TOP-LEVEL FAIL-SAFE SHIELD (Bảo vệ tuyệt đối chống crash)
// ==============================================================================
process.on('uncaughtException', (err) => {
  try {
    process.stderr.write(`[HOOK-FATAL-ERROR] ${err.stack || err.message}\n`);
    if (hookType === 'PostToolUse') {
      process.stdout.write('{}\n');
    } else if (hookType === 'PreInvocation' || hookType === 'PostInvocation') {
      process.stdout.write('{"injectSteps":[]}\n');
    } else if (hookType === 'Stop') {
      process.stdout.write('{"decision":"allow"}\n');
    } else {
      process.stdout.write('{"decision":"allow","reason":"Emergency fail-safe bypass"}\n');
    }
  } catch (_) {}
  process.exit(0);
});

// ==============================================================================
// 2. I/O & PATH RESOLUTION UTILITIES
// ==============================================================================
function readStdinJson() {
  try {
    const raw = fs.readFileSync(0, 'utf-8');
    if (!raw || !raw.trim()) return {};
    return JSON.parse(raw);
  } catch (_) {
    return {};
  }
}

function writeStdoutJson(obj) {
  process.stdout.write(JSON.stringify(obj) + '\n');
}

// Neo đường dẫn bất biến từ vị trí file script (.agents/scripts)
const AGENTS_DIR = path.resolve(__dirname, '..');
const DEFAULT_WORKSPACE_ROOT = path.resolve(AGENTS_DIR, '..');
const STATE_DIR = path.join(os.tmpdir(), 'antigravity-hooks-state');

function ensureDirSync(dirPath) {
  if (!fs.existsSync(dirPath)) {
    try {
      fs.mkdirSync(dirPath, { recursive: true });
    } catch (_) {}
  }
  return dirPath;
}

ensureDirSync(STATE_DIR);

function formatSessionTimestamp(date = new Date()) {
  const pad = (n) => String(n).padStart(2, '0');
  const yyyy = date.getFullYear();
  const MM = pad(date.getMonth() + 1);
  const dd = pad(date.getDate());
  const HH = pad(date.getHours());
  const mm = pad(date.getMinutes());
  const ss = pad(date.getSeconds());
  return `${yyyy}-${MM}-${dd}_${HH}${mm}${ss}`;
}

// ==============================================================================
// 3. SECURITY GUARDRAIL (Chốt chặn lệnh nguy hiểm)
// ==============================================================================
const DANGEROUS_PATTERNS = [
  /\brm\s+-(?:r[fF]|f[rR])\s+[\/\\]/i,
  /\bdel\s+\/[fF]\s+\/[sS]\s+[cC]:\\/i,
  /\bformat\s+[a-zA-Z]:/i,
  /\bdiskpart\b/i,
  /\bDROP\s+(?:DATABASE|SCHEMA)\b/i,
  /\bTRUNCATE\s+TABLE\b/i
];

function verifyCommandSafety(commandLine) {
  if (!commandLine || typeof commandLine !== 'string') return { isSafe: true };
  for (const pattern of DANGEROUS_PATTERNS) {
    if (pattern.test(commandLine)) {
      return {
        isSafe: false,
        reason: `Lệnh chứa mẫu cấm nguy cơ cao: ${pattern.toString()}`
      };
    }
  }
  return { isSafe: true };
}

// ==============================================================================
// 4. ATOMIC EPHEMERAL STATE STORE (Trong os.tmpdir())
// ==============================================================================
function writeJsonSafe(filePath, data) {
  try {
    fs.writeFileSync(filePath, JSON.stringify(data), 'utf-8');
  } catch (_) {}
}

function readJsonSafe(filePath, fallback = null) {
  try {
    if (fs.existsSync(filePath)) {
      const content = fs.readFileSync(filePath, 'utf-8');
      if (content && content.trim()) return JSON.parse(content);
    }
  } catch (_) {}
  return fallback;
}

function setTimer(key, timeMs = Date.now()) {
  const file = path.join(STATE_DIR, `timer_${encodeURIComponent(key)}.json`);
  writeJsonSafe(file, { timeMs, created: Date.now() });
}

function popTimer(key) {
  const file = path.join(STATE_DIR, `timer_${encodeURIComponent(key)}.json`);
  const data = readJsonSafe(file);
  if (data && typeof data.timeMs === 'number') {
    try {
      if (fs.existsSync(file)) fs.unlinkSync(file);
    } catch (_) {}
    return Math.max(0, Date.now() - data.timeMs);
  }
  return null;
}

// Phân giải phiên làm việc (Session & Hierarchy)
function resolveHierarchy(convId, toolName, toolArgs) {
  const convMapFile = path.join(STATE_DIR, `conv_${convId}.json`);
  let convData = readJsonSafe(convMapFile);

  if (!convData) {
    // Kiểm tra xem có pending subagent nào vừa được gọi không
    const queueFile = path.join(STATE_DIR, 'pending_subagents_queue.json');
    const queue = readJsonSafe(queueFile, []);
    let match = null;

    if (queue.length > 0) {
      match = queue.shift();
      writeJsonSafe(queueFile, queue);
    }

    if (match) {
      convData = {
        sessionId: match.parentSessionId,
        parentId: match.parentSessionId,
        isSubagent: true,
        role: match.role,
        typeName: match.typeName,
        created: Date.now()
      };
    } else {
      const sessionId = `${formatSessionTimestamp()}_${convId.slice(0, 8)}`;
      convData = {
        sessionId: sessionId,
        parentId: null,
        isSubagent: false,
        role: 'Main Agent',
        typeName: 'main',
        created: Date.now()
      };
    }
    writeJsonSafe(convMapFile, convData);
  }

  // Nếu agent gọi invoke_subagent, đưa vào hàng đợi pending
  if (toolName === 'invoke_subagent' && toolArgs && Array.isArray(toolArgs.Subagents)) {
    const queueFile = path.join(STATE_DIR, 'pending_subagents_queue.json');
    const queue = readJsonSafe(queueFile, []);
    for (const sub of toolArgs.Subagents) {
      queue.push({
        parentSessionId: convData.sessionId,
        role: sub.Role || sub.TypeName || 'Subagent',
        typeName: sub.TypeName || 'subagent',
        timestamp: Date.now()
      });
    }
    writeJsonSafe(queueFile, queue);
  }

  return convData;
}

// ==============================================================================
// 5. TOOL CLASSIFICATION & RESOURCE EXTRACTION
// ==============================================================================
function categorizeTool(toolName) {
  if (!toolName || toolName === 'none') return 'None';
  const fileTools = ['view_file', 'write_to_file', 'replace_file_content', 'multi_replace_file_content', 'list_dir', 'find_by_name'];
  const searchTools = ['grep_search', 'search_web', 'read_url_content'];
  const terminalTools = ['run_command', 'manage_task'];
  const colabTools = ['invoke_subagent', 'define_subagent', 'send_message', 'manage_subagents'];
  const systemTools = ['schedule', 'ask_question', 'ask_permission', 'list_permissions', 'generate_image'];

  if (fileTools.includes(toolName)) return 'FileIO';
  if (searchTools.includes(toolName)) return 'Search';
  if (terminalTools.includes(toolName)) return 'Terminal';
  if (colabTools.includes(toolName)) return 'AgentCollaboration';
  if (systemTools.includes(toolName)) return 'System';
  if (toolName.startsWith('mcp_')) return 'MCP';
  return 'Other';
}

function extractTargetResource(toolName, toolArgs) {
  if (!toolArgs) return null;
  if (toolArgs.AbsolutePath) return toolArgs.AbsolutePath;
  if (toolArgs.TargetFile) return toolArgs.TargetFile;
  if (toolArgs.DirectoryPath) return toolArgs.DirectoryPath;
  if (toolArgs.SearchPath) return toolArgs.SearchPath;
  if (toolArgs.CommandLine) return toolArgs.CommandLine;
  if (toolArgs.Url) return toolArgs.Url;
  if (toolArgs.Recipient) return `agent://${toolArgs.Recipient}`;
  return null;
}

function extractToolExecution(transcriptPath, stepIdx, error = null) {
  if (error) {
    return {
      IsSuccess: false,
      OutputLengthChars: error.length || 0,
      OutputSnippet: error.slice(0, 300)
    };
  }
  if (!transcriptPath || stepIdx < 0) return null;

  try {
    const stepOutputFile = path.resolve(path.dirname(transcriptPath), '../steps', String(stepIdx), 'output.txt');
    if (fs.existsSync(stepOutputFile)) {
      const stat = fs.statSync(stepOutputFile);
      const bytesToRead = Math.min(stat.size, 2048);
      const buffer = Buffer.alloc(bytesToRead);
      const fd = fs.openSync(stepOutputFile, 'r');
      fs.readSync(fd, buffer, 0, bytesToRead, 0);
      fs.closeSync(fd);
      const snippet = buffer.toString('utf-8');
      return {
        IsSuccess: true,
        OutputLengthChars: stat.size,
        OutputSnippet: snippet.slice(0, 300)
      };
    }
  } catch (_) {}
  return null;
}

// ==============================================================================
// 6. LOGGING & SINK (Ghi NDJSON vào Tests/Agy/Logs/Sessions/)
// ==============================================================================
function resolveStoragePaths(workspaceRoot, sessionId, isSubagent, role) {
  const sessionsDir = path.resolve(workspaceRoot, 'Tests/Agy/Logs/Sessions');
  const sessionDir = path.join(sessionsDir, sessionId);
  ensureDirSync(sessionDir);

  let fileName = 'main_events.ndjson';
  if (isSubagent) {
    const cleanRole = (role || 'subagent').toLowerCase().replace(/[^a-z0-9_-]/g, '_');
    fileName = `subagent_${cleanRole}.ndjson`;
  }
  return {
    sessionDir,
    logFilePath: path.join(sessionDir, fileName)
  };
}

function writeSessionLog(workspaceRoot, wideEvent) {
  try {
    const { sessionDir, logFilePath } = resolveStoragePaths(
      workspaceRoot,
      wideEvent.SessionId,
      wideEvent.Agent.IsSubagent,
      wideEvent.Agent.Role
    );
    fs.appendFileSync(logFilePath, JSON.stringify(wideEvent) + '\n', 'utf-8');
    return sessionDir;
  } catch (_) {
    return null;
  }
}

// Tạo Session Report & Summary Markdown khi Stop
function generateSessionReport(sessionDir, sessionId) {
  try {
    if (!fs.existsSync(sessionDir)) return;
    const files = fs.readdirSync(sessionDir).filter((f) => f.endsWith('.ndjson'));
    const allEvents = [];

    for (const file of files) {
      try {
        const lines = fs.readFileSync(path.join(sessionDir, file), 'utf-8').split('\n');
        for (const line of lines) {
          if (line.trim()) {
            const evt = JSON.parse(line);
            evt._sourceFile = file;
            allEvents.push(evt);
          }
        }
      } catch (_) {}
    }

    if (allEvents.length === 0) return;

    const toolCalls = allEvents.filter((e) => e.HookType === 'PostToolUse' && e.ToolName && e.ToolName !== 'none');
    const toolStats = {};
    for (const tc of toolCalls) {
      const name = tc.ToolName;
      if (!toolStats[name]) toolStats[name] = { count: 0, totalDur: 0, errors: 0 };
      toolStats[name].count++;
      const dur = tc.ActualDurationMs || 0;
      toolStats[name].totalDur += dur;
      if (tc.Error) toolStats[name].errors++;
    }

    const summary = {
      SessionId: sessionId,
      GeneratedAtUtc: new Date().toISOString(),
      TotalEvents: allEvents.length,
      TotalToolCalls: toolCalls.length,
      ToolStatistics: toolStats
    };

    fs.writeFileSync(path.join(sessionDir, 'session_summary.json'), JSON.stringify(summary, null, 2), 'utf-8');

    let md = `# 📊 Báo Cáo Phiên Làm Việc (Session Report): \`${sessionId}\`\n\n`;
    md += `- **Thời điểm tạo**: ${summary.GeneratedAtUtc}\n`;
    md += `- **Tổng số sự kiện vòng đời**: ${summary.TotalEvents}\n`;
    md += `- **Tổng số lượt gọi công cụ**: ${summary.TotalToolCalls}\n\n`;
    md += `## 🛠️ Thống Kê Công Cụ Thực Thi\n\n`;
    md += `| Tên Công Cụ | Số Lượt Gọi | Tổng Thời Gian (ms) | Trung Bình (ms) | Số Lỗi |\n`;
    md += `| :--- | :---: | :---: | :---: | :---: |\n`;

    for (const [tool, stat] of Object.entries(toolStats)) {
      const avg = stat.count > 0 ? (stat.totalDur / stat.count).toFixed(1) : '0.0';
      md += `| \`${tool}\` | ${stat.count} | ${stat.totalDur.toFixed(0)} | ${avg} | ${stat.errors} |\n`;
    }

    fs.writeFileSync(path.join(sessionDir, 'session_report.md'), md, 'utf-8');
  } catch (_) {}
}

// ==============================================================================
// 7. CHU TRÌNH ĐIỀU PHỐI CHÍNH (MAIN DISPATCH LOOP)
// ==============================================================================
try {
  const payload = readStdinJson();
  const convId = payload.conversationId || 'unknown';
  const toolCall = payload.toolCall || null;
  const toolName = toolCall ? (toolCall.name || 'none') : 'none';
  const toolArgs = toolCall ? (toolCall.args || {}) : {};

  // Mỏ neo Workspace Root chuẩn xác
  const workspaceRoot = (payload.workspacePaths && payload.workspacePaths[0])
    ? path.resolve(payload.workspacePaths[0])
    : DEFAULT_WORKSPACE_ROOT;

  // 1. Chốt chặn an toàn (Security Guard) ngay tại PreToolUse
  if (hookType === 'PreToolUse' && toolName === 'run_command') {
    const cmdLine = toolArgs.CommandLine || '';
    const safety = verifyCommandSafety(cmdLine);
    if (!safety.isSafe) {
      writeStdoutJson({
        decision: 'deny',
        reason: `[SECURITY-GUARD] ${safety.reason}`
      });
      process.exit(0);
    }
  }

  // 2. Phân giải phân cấp phiên
  const hierarchy = resolveHierarchy(convId, toolName, toolArgs);
  const traceId = crypto.randomBytes(16).toString('hex');
  const spanId = crypto.randomBytes(8).toString('hex');

  // 3. Xây dựng bản ghi Wide Event
  const wideEvent = {
    TimestampUtc: new Date().toISOString(),
    TraceId: traceId,
    SpanId: spanId,
    Operation: 'AgentLifecycleHook',
    HookType: hookType,
    SessionId: hierarchy.sessionId,
    ConversationId: convId,
    IsSubagent: hierarchy.isSubagent,
    ParentSessionId: hierarchy.parentId,
    ToolName: toolName,
    TargetResource: extractTargetResource(toolName, toolArgs),
    ToolArgsSummary: toolArgs,
    ActualDurationMs: null,
    ModelName: payload.modelName || 'unknown',
    Agent: {
      IsSubagent: hierarchy.isSubagent,
      Role: hierarchy.role || 'Main Agent',
      ParentSessionId: hierarchy.parentId,
      Model: payload.modelName || 'unknown'
    },
    Tool: null,
    Timing: {
      ToolDurationMs: null,
      ModelDurationMs: null,
      HookOverheadMs: 0
    },
    StepIdx: typeof payload.stepIdx === 'number' ? payload.stepIdx : -1,
    InvocationNum: typeof payload.invocationNum === 'number' ? payload.invocationNum : -1,
    TerminationReason: payload.terminationReason || null,
    Status: payload.error ? 'Error' : 'Success',
    Error: payload.error || null,
    Environment: {
      Platform: process.platform,
      NodeVersion: process.version,
      Pid: process.pid,
      Cwd: process.cwd()
    }
  };

  if (toolCall) {
    const target = extractTargetResource(toolName, toolArgs);
    const category = categorizeTool(toolName);
    wideEvent.Tool = {
      Name: toolName,
      Category: category,
      TargetResource: target,
      ArgsSummary: toolArgs,
      Execution: null
    };
  }

  // 4. Xử lý Stopwatch & Timing theo loại sự kiện
  if (hookType === 'PreToolUse') {
    setTimer(`${convId}_tool_${wideEvent.StepIdx}`, Date.now());
  } else if (hookType === 'PostToolUse') {
    const dur = popTimer(`${convId}_tool_${wideEvent.StepIdx}`);
    wideEvent.ActualDurationMs = dur;
    wideEvent.Timing.ToolDurationMs = dur;
    wideEvent.ToolExecution = extractToolExecution(payload.transcriptPath, wideEvent.StepIdx, payload.error);
  } else if (hookType === 'PreInvocation') {
    setTimer(`${convId}_inv_${wideEvent.InvocationNum}`, Date.now());
  } else if (hookType === 'PostInvocation') {
    const dur = popTimer(`${convId}_inv_${wideEvent.InvocationNum}`);
    wideEvent.ActualDurationMs = dur;
    wideEvent.Timing.ModelDurationMs = dur;
  }

  wideEvent.Timing.HookOverheadMs = Number((performance.now() - startTime).toFixed(2));

  // 5. Ghi log NDJSON
  const sessionDir = writeSessionLog(workspaceRoot, wideEvent);

  // 6. Xử lý sự kiện Stop: Xuất báo cáo tổng kết
  if (hookType === 'Stop' && sessionDir) {
    generateSessionReport(sessionDir, hierarchy.sessionId);
  }

  // 7. Xuất STDOUT tuân thủ nghiêm ngặt chuẩn hợp đồng CLI
  if (hookType === 'PostToolUse') {
    writeStdoutJson({});
  } else if (hookType === 'PreInvocation' || hookType === 'PostInvocation') {
    writeStdoutJson({ injectSteps: [] });
  } else if (hookType === 'Stop') {
    writeStdoutJson({ decision: 'allow' });
  } else {
    // PreToolUse
    writeStdoutJson({
      decision: 'allow',
      reason: 'Unified hook verification passed'
    });
  }
} catch (err) {
  // Fail-open fallback
  process.stderr.write(`[HOOK-ERROR] ${err.message}\n`);
  if (hookType === 'PostToolUse') writeStdoutJson({});
  else if (hookType === 'PreInvocation' || hookType === 'PostInvocation') writeStdoutJson({ injectSteps: [] });
  else writeStdoutJson({ decision: 'allow' });
}
