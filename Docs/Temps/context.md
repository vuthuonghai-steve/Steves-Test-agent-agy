Cách 2 — cấu hình server tùy chỉnh (custom server):

Click … ở đầu panel agent → MCP Servers → Manage MCP Servers → View raw config.

Sửa file mcp_config.json — nằm ở global path ~/.gemini/config/mcp_config.json, hoặc workspace-level tại .agents/mcp_config.json trong project của bạn.

Thêm đúng object mcpServers như trên (giống hệt cấu hình dùng cho Claude):

json
{
  "mcpServers": {
    "drawio": {
      "command": "npx",
      "args": ["-y", "@drawio/mcp"]
    }
  }
}
Lưu file, Antigravity sẽ tự nhận tool mới — không cần khởi động lại toàn bộ IDE, chỉ cần refresh trong panel MCP Servers.

Nếu bạn dùng Antigravity CLI thay vì IDE, gõ /mcp trong prompt panel để mở MCP Manager Overlay, xem trạng thái kết nối trực tiếp, hoặc sửa cùng file mcp_config.json ở ~/.gemini/config/ (global) hay .agents/mcp_config.json (workspace).

Về quyền thực thi (permission)
Antigravity mặc định chạy MCP tool ở chế độ Ask — mỗi lần agent gọi tool drawio để tạo/sửa sơ đồ, nó sẽ hỏi bạn xác nhận trước khi thực thi. Nếu muốn agent tự động chạy không hỏi lại, bạn có thể thêm policy cho phép cả server:

text
mcp(drawio/*)
hoặc chỉ cho phép 1 tool cụ thể dạng mcp(drawio/create_diagram) — nên giữ ở mode Ask ban đầu để kiểm soát, vì đây là tool sinh file, bạn vẫn muốn xem trước khi ghi đè.

Cách 2 — cấu hình server tùy chỉnh (custom server):

Click … ở đầu panel agent → MCP Servers → Manage MCP Servers → View raw config.

Sửa file mcp_config.json — nằm ở global path ~/.gemini/config/mcp_config.json, hoặc workspace-level tại .agents/mcp_config.json trong project của bạn.

Thêm đúng object mcpServers như trên (giống hệt cấu hình dùng cho Claude):

json
{
  "mcpServers": {
    "drawio": {
      "command": "npx",
      "args": ["-y", "@drawio/mcp"]
    }
  }
}
Lưu file, Antigravity sẽ tự nhận tool mới — không cần khởi động lại toàn bộ IDE, chỉ cần refresh trong panel MCP Servers.

Nếu bạn dùng Antigravity CLI thay vì IDE, gõ /mcp trong prompt panel để mở MCP Manager Overlay, xem trạng thái kết nối trực tiếp, hoặc sửa cùng file mcp_config.json ở ~/.gemini/config/ (global) hay .agents/mcp_config.json (workspace).

Về quyền thực thi (permission)
Antigravity mặc định chạy MCP tool ở chế độ Ask — mỗi lần agent gọi tool drawio để tạo/sửa sơ đồ, nó sẽ hỏi bạn xác nhận trước khi thực thi. Nếu muốn agent tự động chạy không hỏi lại, bạn có thể thêm policy cho phép cả server:

text
mcp(drawio/*)
hoặc chỉ cho phép 1 tool cụ thể dạng mcp(drawio/create_diagram) — nên giữ ở mode Ask ban đầu để kiểm soát, vì đây là tool sinh file, bạn vẫn muốn xem trước khi ghi đè.

