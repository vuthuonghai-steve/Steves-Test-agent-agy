/**
 * Headless Stream Driver for Antigravity CLI
 * Tích hợp điều khiển phiên headless liên tục qua giao thức 2 chiều (stream-json).
 * Tham chiếu đặc tả: Docs/Antigravities/CLI/Headless-mode.md (L241-367)
 */

const { spawn } = require('child_process');
const readline = require('readline');
const EventEmitter = require('events');

class HeadlessStreamDriver extends EventEmitter {
  constructor(options = {}) {
    super();
    this.model = options.model || '';
    this.effort = options.effort || '';
    this.workspaceDir = options.workspaceDir || process.cwd();
    this.proc = null;
    this.rl = null;
    this.isReady = false;
  }

  /**
   * Khởi động tiến trình persistent agy stream-json
   */
  start() {
    const args = [
      '--input-format', 'stream-json',
      '--output-format', 'stream-json',
      '--add-dir', this.workspaceDir
    ];
    if (this.model) args.push('--model', this.model);
    if (this.effort) args.push('--effort', this.effort);

    this.proc = spawn('agy', args, {
      stdio: ['pipe', 'pipe', 'pipe'],
      shell: true
    });

    this.rl = readline.createInterface({
      input: this.proc.stdout,
      terminal: false
    });

    this.rl.on('line', (line) => {
      if (!line || !line.trim()) return;
      try {
        const evt = JSON.parse(line);
        this.emit('event', evt);

        if (evt.event === 'init') {
          this.isReady = true;
          this.emit('init', evt.init);
        } else if (evt.event === 'step_update') {
          this.emit('step_update', evt.step_update);
        } else if (evt.event === 'result') {
          this.emit('result', evt.result);
        }
      } catch (err) {
        this.emit('parse_error', { line, error: err.message });
      }
    });

    this.proc.stderr.on('data', (chunk) => {
      this.emit('stderr', chunk.toString('utf-8'));
    });

    this.proc.on('close', (code) => {
      this.isReady = false;
      this.emit('close', code);
    });
  }

  /**
   * Gửi một prompt turn tới agent đang kết nối và chờ kết quả result event
   * @param {string} promptText
   * @returns {Promise<object>} result payload
   */
  async sendPrompt(promptText) {
    if (!this.proc) {
      throw new Error('Headless stream chưa được khởi động. Hãy gọi start() trước.');
    }

    return new Promise((resolve, reject) => {
      const onResult = (result) => {
        this.removeListener('result', onResult);
        resolve(result);
      };

      const onClose = (code) => {
        this.removeListener('result', onResult);
        if (code !== 0) {
          reject(new Error(`Tiến trình headless thoát với mã lỗi: ${code}`));
        }
      };

      this.once('result', onResult);
      this.once('close', onClose);

      const messagePayload = {
        event: 'user',
        message: { content: promptText }
      };

      this.proc.stdin.write(JSON.stringify(messagePayload) + '\n');
    });
  }

  /**
   * Đóng phiên làm việc một cách duyên dáng
   */
  stop() {
    if (this.proc) {
      try {
        this.proc.stdin.end();
      } catch (_) {}
    }
  }
}

module.exports = {
  HeadlessStreamDriver
};
