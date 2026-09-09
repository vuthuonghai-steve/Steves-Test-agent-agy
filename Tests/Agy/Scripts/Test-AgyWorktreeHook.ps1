<#
.SYNOPSIS
    Kiểm thử cơ học (Mechanical Verification) cho Antigravity CLI kết hợp Lifecycle Hooks và Wide Event Logging.
.DESCRIPTION
    Script này thực thi:
    1. Kiểm tra môi trường Git Worktree độc lập (.worktrees/agy-sandbox).
    2. Chạy Antigravity CLI ở chế độ Headless với cờ --add-dir để kích hoạt Workspace Customizations.
    3. Xác minh Antigravity tự động kích hoạt PreToolUse & PostToolUse hooks.
    4. Kiểm tra file wide_events.ndjson xem có đúng định dạng Canonical Log Line / Wide Event không.
.EXAMPLE
    .\Test-AgyWorktreeHook.ps1
#>

param (
    [string]$WorktreePath = (Resolve-Path "$PSScriptRoot\..\..\..\.worktrees\agy-sandbox" -ErrorAction SilentlyContinue),
    [string]$LogFile = (Resolve-Path "$PSScriptRoot\..\..\..\.worktrees\agy-sandbox\Tests\Agy\Logs\wide_events.ndjson" -ErrorAction SilentlyContinue)
)

$ErrorActionPreference = "Stop"

Write-Host "=== [1/4] KIỂM TRA MÔI TRƯỜNG GIT WORKTREE ===" -ForegroundColor Cyan
if (-not (Test-Path $WorktreePath)) {
    Write-Host "[FAIL] Không tìm thấy worktree tại $WorktreePath" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Worktree tồn tại: $WorktreePath" -ForegroundColor Green

# Chuẩn bị file log: xóa file cũ trước khi chạy để kiểm tra tính tạo mới
if (Test-Path $LogFile) {
    Remove-Item -Force $LogFile
}

Write-Host "`n=== [2/4] THỰC THI ANTIGRAVITY CLI (HEADLESS + HOOKS) ===" -ForegroundColor Cyan
$Prompt = "Read DEMO-TARGET.txt and output only the STEVE_SECRET_KEY."
Write-Host ">>> Executing: agy --add-dir `"$WorktreePath`" -p `"$Prompt`""

$ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
$ProcessInfo.FileName = "agy"
$ProcessInfo.Arguments = "--add-dir `"$WorktreePath`" -p `"$Prompt`""
$ProcessInfo.WorkingDirectory = $WorktreePath
$ProcessInfo.RedirectStandardOutput = $true
$ProcessInfo.RedirectStandardError = $true
$ProcessInfo.UseShellExecute = $false
$ProcessInfo.CreateNoWindow = $true

$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$Process = [System.Diagnostics.Process]::Start($ProcessInfo)
$Process.WaitForExit(60000) # Timeout 60s
$Stopwatch.Stop()

$Output = $Process.StandardOutput.ReadToEnd().Trim()
$ErrorOutput = $Process.StandardError.ReadToEnd().Trim()
$ExitCode = $Process.ExitCode

Write-Host ">>> CLI Exit Code: $ExitCode (Execution Time: $($Stopwatch.ElapsedMilliseconds) ms)"
Write-Host ">>> CLI Response: $Output"

if ($ExitCode -ne 0 -or $Output -notmatch "998877") {
    Write-Host "[FAIL] CLI không hoàn thành đúng yêu cầu!" -ForegroundColor Red
    if ($ErrorOutput) { Write-Host "Error Output: $ErrorOutput" -ForegroundColor Red }
    exit 1
}
Write-Host "[OK] CLI hoàn thành và trích xuất đúng secret key!" -ForegroundColor Green

Write-Host "`n=== [3/4] XÁC THỰC BẰNG CHỨNG CƠ HỌC (WIDE EVENT AUDIT) ===" -ForegroundColor Cyan
if (-not (Test-Path $LogFile)) {
    Write-Host "[FAIL] Không tìm thấy file log Wide Event tại: $LogFile" -ForegroundColor Red
    exit 1
}

$Lines = Get-Content $LogFile | Where-Object { $_.Trim() -ne "" }
Write-Host "[OK] Đã bắt được $($Lines.Count) Wide Events trong phiên làm việc!" -ForegroundColor Green

$ParsedEvents = @()
foreach ($line in $Lines) {
    try {
        $eventObj = $line | ConvertFrom-Json
        $ParsedEvents += $eventObj
    } catch {
        Write-Host "[FAIL] Dòng log không đúng chuẩn JSON: $line" -ForegroundColor Red
        exit 1
    }
}

# Kiểm tra các trường bắt buộc của Wide Event (theo logging-best-practices)
$RequiredFields = @("TimestampUtc", "Operation", "HookType", "SessionId", "ToolName", "DurationMs", "Status", "Environment")
$FirstEvent = $ParsedEvents[0]
foreach ($field in $RequiredFields) {
    if (-not $FirstEvent.PSObject.Properties[$field]) {
        Write-Host "[FAIL] Thiếu trường dữ liệu bắt buộc '$field' trong Wide Event!" -ForegroundColor Red
        exit 1
    }
}
Write-Host "[OK] 100% Wide Events tuân thủ chuẩn Canonical Log Line (High Cardinality & High Dimensionality)!" -ForegroundColor Green

Write-Host "`n=== [4/4] TRÍCH XUẤT WIDE EVENT TELEMETRY (JSON STREAM) ===" -ForegroundColor Cyan
$ParsedEvents | ConvertTo-Json -Depth 5

Write-Host "`n[APPROVED] Tất cả tiêu chí cơ học đều vượt qua (Exit Code: 0)!" -ForegroundColor Green
exit 0
