#!/usr/bin/env node
/**
 * validate-hook.js
 * Chốt chặn kiểm định cơ học (Mechanical Quality Gate) cho cấu hình Antigravity Lifecycle Hooks (hooks.json).
 * Kiểm tra:
 * 1. JSON cú pháp hợp lệ.
 * 2. Cấu trúc top-level hook objects.
 * 3. Tên event hợp lệ (PreToolUse, PostToolUse, PreInvocation, PostInvocation, Stop, enabled).
 * 4. Cấu trúc Matcher và Handler đối với tool events.
 * 5. Tính khả thi của lệnh shell và sự tồn tại của script handler.
 */

const fs = require('fs');
const path = require('path');

const targetFile = process.argv[2] || path.join(process.cwd(), '.agents', 'hooks.json');
const resolvedPath = path.resolve(targetFile);

console.log(`[HOOK-VALIDATOR] Đang kiểm tra cấu hình: ${resolvedPath}`);

if (!fs.existsSync(resolvedPath)) {
  console.error(`[ERROR] File không tồn tại: ${resolvedPath}`);
  process.exit(1);
}

let content;
try {
  content = JSON.parse(fs.readFileSync(resolvedPath, 'utf8'));
} catch (e) {
  console.error(`[ERROR] Lỗi cú pháp JSON trong file hooks: ${e.message}`);
  process.exit(1);
}

const VALID_EVENTS = new Set(['PreToolUse', 'PostToolUse', 'PreInvocation', 'PostInvocation', 'Stop', 'enabled']);
const errors = [];
const warnings = [];

const hookDir = path.dirname(resolvedPath);

// Duyệt qua từng named hook
for (const [hookName, hookConfig] of Object.entries(content)) {
  if (typeof hookConfig !== 'object' || hookConfig === null || Array.isArray(hookConfig)) {
    errors.push(`[${hookName}] Cấu hình hook phải là một JSON Object.`);
    continue;
  }

  for (const [eventKey, eventVal] of Object.entries(hookConfig)) {
    if (!VALID_EVENTS.has(eventKey)) {
      errors.push(`[${hookName}] Sự kiện '${eventKey}' không hợp lệ! Antigravity chỉ hỗ trợ: PreToolUse, PostToolUse, PreInvocation, PostInvocation, Stop, enabled.`);
      continue;
    }

    if (eventKey === 'enabled') {
      if (typeof eventVal !== 'boolean') {
        errors.push(`[${hookName}] Thuộc tính 'enabled' phải là boolean (true/false).`);
      }
      continue;
    }

    if (!Array.isArray(eventVal)) {
      errors.push(`[${hookName}.${eventKey}] Sự kiện phải là một Array các handler groups.`);
      continue;
    }

    if (eventKey === 'PreToolUse' || eventKey === 'PostToolUse') {
      // Grouped matcher structure
      eventVal.forEach((group, gIdx) => {
        if (!group.matcher && group.matcher !== '') {
          errors.push(`[${hookName}.${eventKey}[${gIdx}]] Thiếu trường 'matcher' (dùng regex, ví dụ: '*', 'run_command', 'run_command|view_file').`);
        }
        if (!Array.isArray(group.hooks) || group.hooks.length === 0) {
          errors.push(`[${hookName}.${eventKey}[${gIdx}]] Trường 'hooks' phải là mảng chứa tối thiểu 1 command handler.`);
        } else {
          group.hooks.forEach((h, hIdx) => {
            validateHandler(`${hookName}.${eventKey}[${gIdx}].hooks[${hIdx}]`, h, hookDir);
          });
        }
      });
    } else {
      // Flat handler list (PreInvocation, PostInvocation, Stop)
      eventVal.forEach((h, hIdx) => {
        validateHandler(`${hookName}.${eventKey}[${hIdx}]`, h, hookDir);
      });
    }
  }
}

function validateHandler(context, handler, baseDir) {
  if (!handler.command || typeof handler.command !== 'string') {
    errors.push(`[${context}] Thiếu trường 'command' hoặc command không phải chuỗi.`);
    return;
  }
  if (handler.type && handler.type !== 'command') {
    errors.push(`[${context}] Type '${handler.type}' không được hỗ trợ. Hiện chỉ hỗ trợ 'command'.`);
  }
  if (handler.timeout && typeof handler.timeout !== 'number') {
    errors.push(`[${context}] Timeout phải là số nguyên (giây).`);
  }

  // Phân tích đường dẫn script trong command
  const parts = handler.command.trim().split(/\s+/);
  if (parts.length >= 2 && (parts[0] === 'node' || parts[0] === 'python' || parts[0] === 'bash')) {
    const scriptRelative = parts[1];
    const scriptPath = path.resolve(baseDir, scriptRelative);
    if (!fs.existsSync(scriptPath)) {
      warnings.push(`[${context}] Cảnh báo: File script '${scriptRelative}' không tìm thấy tại '${scriptPath}'. Vui lòng tạo script trước khi chạy agent.`);
    }
  }
}

console.log('\n--- KẾT QUẢ KIỂM ĐỊNH (AUDIT REPORT) ---');
if (warnings.length > 0) {
  console.log(`[CẢNH BÁO] Phát hiện ${warnings.length} lưu ý:`);
  warnings.forEach(w => console.log(`  ⚠️  ${w}`));
}

if (errors.length > 0) {
  console.error(`[THẤT BẠI] Phát hiện ${errors.length} lỗi vi phạm schema:`);
  errors.forEach(e => console.error(`  ❌ ${e}`));
  process.exit(1);
} else {
  console.log(`[APPROVED] Cấu hình hooks.json hoàn toàn hợp lệ theo Antigravity Lifecycle Hook Spec! (Exit Code: 0)`);
  process.exit(0);
}
