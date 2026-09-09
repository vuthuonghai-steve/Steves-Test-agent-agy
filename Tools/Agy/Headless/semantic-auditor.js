/**
 * Headless Semantic Auditor
 * Sử dụng agy headless mode với structured output (--json-schema) để tự động thẩm định ngữ nghĩa.
 * Tham chiếu đặc tả: Docs/Antigravities/CLI/Headless-mode.md (L89-128)
 */

const { exec } = require('child_process');

/**
 * Thực thi lệnh audit ngữ nghĩa qua headless agent
 * @param {string} prompt
 * @param {object|string} jsonSchema
 * @param {object} options
 * @returns {Promise<object>}
 */
function auditWithHeadlessAgent(prompt, jsonSchema, options = {}) {
  return new Promise((resolve, reject) => {
    const schemaStr = typeof jsonSchema === 'object' ? JSON.stringify(jsonSchema) : jsonSchema;
    const model = options.model || '';
    const effort = options.effort || 'low'; // Mặc định effort low để thẩm định siêu tốc & tiết kiệm token
    const timeout = options.timeoutMinutes || 2;

    const cmdParts = [
      'agy',
      '-p', `"${prompt.replace(/"/g, '\\"')}"`,
      '--output-format', 'json',
      '--json-schema', `'${schemaStr.replace(/'/g, "\\'")}'`,
      '--effort', effort,
      '--print-timeout', `${timeout}m`
    ];

    if (model) cmdParts.push('--model', model);

    exec(cmdParts.join(' '), { maxBuffer: 10 * 1024 * 1024 }, (err, stdout, stderr) => {
      if (err) {
        return reject(new Error(`Headless audit thất bại: ${err.message}\nStderr: ${stderr}`));
      }

      try {
        const result = JSON.parse(stdout);
        resolve({
          status: result.status,
          structuredOutput: result.structured_output,
          usage: result.usage,
          durationSeconds: result.duration_seconds
        });
      } catch (parseErr) {
        reject(new Error(`Không phân tích được JSON output từ headless agent: ${parseErr.message}\nRaw: ${stdout}`));
      }
    });
  });
}

module.exports = {
  auditWithHeadlessAgent
};
