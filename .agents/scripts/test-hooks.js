#!/usr/bin/env node
/**
 * Test Runner Giả Lập Antigravity Lifecycle Hooks
 * Kiểm chứng cơ học Unified Hook Runner trước khi vận hành thực tế.
 */

const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

// Neo đường dẫn bất biến
const SCRIPTS_DIR = __dirname;
const AGENTS_DIR = path.resolve(SCRIPTS_DIR, '..');
const WORKSPACE_ROOT = path.resolve(AGENTS_DIR, '..');
const RUNNER_SCRIPT = path.join(SCRIPTS_DIR, 'hook-runner.js');

console.log('=================================================================');
console.log('  KIỂM CHỨNG CƠ HỌC UNIFIED HOOK RUNNER (.agents/scripts)');
console.log('=================================================================\n');

let passed = 0;
let total = 0;

function runHookTest(name, eventType, inputPayload, expectedPredicate) {
  total++;
  process.stdout.write(`[TEST ${total}] ${name} ... `);
  try {
    const inputStr = JSON.stringify(inputPayload);
    const cmd = `node "${RUNNER_SCRIPT}" ${eventType}`;
    
    // Test chạy từ Workspace Root để mô phỏng chính xác Antigravity CLI CWD
    const stdout = execSync(cmd, {
      cwd: WORKSPACE_ROOT,
      input: inputStr,
      encoding: 'utf-8',
      stdio: ['pipe', 'pipe', 'pipe']
    });

    const parsed = JSON.parse(stdout.trim());
    if (expectedPredicate(parsed)) {
      console.log('✅ PASSED (0 exit code)');
      passed++;
    } else {
      console.log('❌ FAILED (Output không khớp kỳ vọng)');
      console.error('Actual:', parsed);
    }
  } catch (err) {
    console.log(`❌ FAILED (Lỗi thực thi: ${err.message})`);
    if (err.stderr) console.error('Stderr:', err.stderr.toString());
  }
}

// 1. Test PreToolUse (Allow)
runHookTest(
  'PreToolUse: view_file -> allow',
  'PreToolUse',
  {
    conversationId: 'test-conv-001',
    workspacePaths: [WORKSPACE_ROOT],
    toolCall: { name: 'view_file', args: { AbsolutePath: 'C:\\test.txt' } },
    stepIdx: 1
  },
  (res) => res.decision === 'allow'
);

// 2. Test PreToolUse: Security Guard allow lệnh an toàn
runHookTest(
  'PreToolUse: Security Guard (git status -> allow)',
  'PreToolUse',
  {
    conversationId: 'test-conv-001',
    workspacePaths: [WORKSPACE_ROOT],
    toolCall: { name: 'run_command', args: { CommandLine: 'git status' } },
    stepIdx: 2
  },
  (res) => res.decision === 'allow'
);

// 3. Test PreToolUse: Security Guard deny lệnh nguy hiểm
runHookTest(
  'PreToolUse: Security Guard (rm -rf / -> deny)',
  'PreToolUse',
  {
    conversationId: 'test-conv-001',
    workspacePaths: [WORKSPACE_ROOT],
    toolCall: { name: 'run_command', args: { CommandLine: 'rm -rf /' } },
    stepIdx: 3
  },
  (res) => res.decision === 'deny' && res.reason && res.reason.includes('[SECURITY-GUARD]')
);

// 4. Test PostToolUse (STDOUT {})
runHookTest(
  'PostToolUse: STDOUT {} empty object',
  'PostToolUse',
  {
    conversationId: 'test-conv-001',
    workspacePaths: [WORKSPACE_ROOT],
    toolCall: { name: 'view_file', args: { AbsolutePath: 'C:\\test.txt' } },
    stepIdx: 1
  },
  (res) => typeof res === 'object' && Object.keys(res).length === 0
);

// 5. Test PreInvocation (injectSteps: [])
runHookTest(
  'PreInvocation: STDOUT injectSteps mảng rỗng',
  'PreInvocation',
  {
    conversationId: 'test-conv-001',
    workspacePaths: [WORKSPACE_ROOT],
    invocationNum: 0
  },
  (res) => Array.isArray(res.injectSteps) && res.injectSteps.length === 0
);

// 6. Test PostInvocation (injectSteps: [])
runHookTest(
  'PostInvocation: STDOUT injectSteps mảng rỗng',
  'PostInvocation',
  {
    conversationId: 'test-conv-001',
    workspacePaths: [WORKSPACE_ROOT],
    invocationNum: 0
  },
  (res) => Array.isArray(res.injectSteps) && res.injectSteps.length === 0
);

// 7. Test Stop (decision: allow)
runHookTest(
  'Stop: STDOUT decision allow & tạo session report',
  'Stop',
  {
    conversationId: 'test-conv-001',
    workspacePaths: [WORKSPACE_ROOT]
  },
  (res) => res.decision === 'allow'
);

console.log(`\nKết quả: ${passed}/${total} bài test vượt qua.`);
if (passed === total) {
  console.log('🎉 TẤT CẢ CÁC BÀI TEST ĐỀU ĐẠT CHUẨN 100%!');
  process.exit(0);
} else {
  console.error('⚠️ Có bài test thất bại.');
  process.exit(1);
}
