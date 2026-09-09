<#
.SYNOPSIS
    Antigravity CLI (agy) Session Auditor & Token Telemetry Inspector
    Do luong co hoc 100% luong token tieu thu, chat luong lap luan (Cognitive Depth) va hieu nang caching.
.EXAMPLE
    .\Invoke-AgySessionAuditor.ps1 -Prompt "Hay phan tich file AGENTS.md"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$Prompt,

    [string]$Model = "",
    [string]$ConversationId = "",
    [int]$TimeoutMinutes = 5,
    [string]$LogsDir = "Tests/Agy/Logs/Sessions"
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

function Write-Box([string]$Text, [ConsoleColor]$Color = [ConsoleColor]::Cyan) {
    Write-Host ""
    Write-Host ("=" * 85) -ForegroundColor $Color
    Write-Host "  $Text" -ForegroundColor Yellow
    Write-Host ("=" * 85) -ForegroundColor $Color
}

function Write-Metric([string]$Name, [string]$Value, [ConsoleColor]$Color = [ConsoleColor]::White) {
    $formatted = "  {0,-35} : " -f $Name
    Write-Host $formatted -NoNewline -ForegroundColor Gray
    Write-Host $Value -ForegroundColor $Color
}

Write-Box "ANTIGRAVITY CLI SESSION AUDITOR & TOKEN TELEMETRY"

$AgyCmd = Get-Command agy -ErrorAction SilentlyContinue
if (-not $AgyCmd) {
    Write-Error "Khong tim thay lenh 'agy'. Vui long kiem tra PATH."
    exit 1
}

$ArgsList = @("--add-dir", (Get-Location).Path, "-p", $Prompt, "--output-format", "json", "--print-timeout", "${TimeoutMinutes}m")
if ($Model -ne "") { $ArgsList += @("--model", $Model) }
if ($ConversationId -ne "") { $ArgsList += @("--conversation", $ConversationId) }

Write-Host "Dang thuc thi agy va thu thap du lieu telemetry..." -ForegroundColor Gray
$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$RawOutput = agy @ArgsList 2>&1
$Stopwatch.Stop()
$WallDuration = [Math]::Round($Stopwatch.Elapsed.TotalSeconds, 2)

try {
    $Result = $RawOutput | ConvertFrom-Json
} catch {
    Write-Host "[FAIL] Khong parse duoc JSON output tu agy:" -ForegroundColor Red
    Write-Host $RawOutput -ForegroundColor DarkGray
    exit 1
}

$ConvId = if ($Result.conversation_id) { $Result.conversation_id } else { "session_unknown" }
$Usage = $Result.usage
$InTokens = if ($Usage.input_tokens) { [int]$Usage.input_tokens } else { 0 }
$OutTokens = if ($Usage.output_tokens) { [int]$Usage.output_tokens } else { 0 }
$ThinkingTokens = if ($Usage.thinking_tokens) { [int]$Usage.thinking_tokens } else { 0 }
$CacheReadTokens = if ($Usage.cache_read_tokens) { [int]$Usage.cache_read_tokens } else { 0 }
$TotalTokens = if ($Usage.total_tokens) { [int]$Usage.total_tokens } else { ($InTokens + $OutTokens) }
$EngineDuration = if ($Result.duration_seconds) { [Math]::Round([double]$Result.duration_seconds, 2) } else { $WallDuration }

# Tinh toan chi so chat luong (Cognitive Depth) va tiet kiem (Cache Efficiency)
$ThinkingRatio = if ($OutTokens -gt 0) { [Math]::Round(($ThinkingTokens / $OutTokens) * 100, 2) } else { 0 }
$CacheEfficiency = if (($InTokens + $CacheReadTokens) -gt 0) { [Math]::Round(($CacheReadTokens / ($InTokens + $CacheReadTokens)) * 100, 2) } else { 0 }

$ReasoningLevel = if ($ThinkingRatio -ge 50) { "Cao (Cognitive Depth / Tu duy sau)" } elseif ($ThinkingRatio -ge 20) { "Trung binh (Balanced)" } else { "Nhe / Nhanh (Fast Response)" }
$ReasoningColor = if ($ThinkingRatio -ge 50) { [ConsoleColor]::Magenta } elseif ($ThinkingRatio -ge 20) { [ConsoleColor]::Cyan } else { [ConsoleColor]::Gray }

# Hien thi ket qua console
Write-Metric "Session ID (Conversation)" $ConvId ([ConsoleColor]::Yellow)
Write-Metric "Trang thai thuc thi (Status)" $Result.status $(if ($Result.status -eq "SUCCESS") { [ConsoleColor]::Green } else { [ConsoleColor]::Red })
Write-Metric "Thoi gian phan hoi Engine" "$EngineDuration giay" ([ConsoleColor]::Yellow)
Write-Metric "Thoi gian tong (Wall clock)" "$WallDuration giay" ([ConsoleColor]::DarkGray)

Write-Host "`n--- [1] DO LUONG TAI NGUYEN & TOKEN CONSUMPTION ---" -ForegroundColor Cyan
Write-Metric "Input Tokens (Tong gui len)" "$InTokens tokens" ([ConsoleColor]::Cyan)
Write-Metric "Prompt Cache Read Tokens" "$CacheReadTokens tokens" ([ConsoleColor]::Green)
Write-Metric "Hieu qua Cache Read" "$CacheEfficiency %" ([ConsoleColor]::Green)
Write-Metric "Output Tokens (Tong sinh ra)" "$OutTokens tokens" ([ConsoleColor]::White)
Write-Metric "Thinking Tokens (Tu duy)" "$ThinkingTokens tokens" ([ConsoleColor]::Magenta)
Write-Metric "Tong Tokens giao dich" "$TotalTokens tokens" ([ConsoleColor]::Yellow)

Write-Host "`n--- [2] DANH GIA CHAT LUONG & COGNITIVE DEPTH ---" -ForegroundColor Cyan
Write-Metric "Ty le Tu duy (Thinking Ratio)" "$ThinkingRatio %" $ReasoningColor
Write-Metric "Muc do dao sau ban chat" $ReasoningLevel $ReasoningColor
Write-Metric "Do dai phan hoi Model" "$($Result.response.Length) ky tu" ([ConsoleColor]::White)

# Ghi Summary Telemetry vao thu muc Session da duoc tao boi wide-event-hook (co chua $ConvId)
$MatchingDirs = Get-ChildItem -Path $LogsDir -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$ConvId" }
if ($MatchingDirs -and $MatchingDirs.Count -gt 0) {
    $SessionDir = $MatchingDirs[0].FullName
} else {
    $TimestampPrefix = (Get-Date).ToString("yyyy-MM-dd_HHmmss")
    $SessionDir = Join-Path $LogsDir "${TimestampPrefix}_$ConvId"
    if (-not (Test-Path $SessionDir)) {
        New-Item -ItemType Directory -Path $SessionDir -Force | Out-Null
    }
}

$SessionLeafName = Split-Path $SessionDir -Leaf
Set-Content -Path (Join-Path $LogsDir "LATEST_SESSION.txt") -Value $SessionLeafName -Encoding utf8

$SummaryData = [PSCustomObject]@{
    TimestampUtc = (Get-Date).ToUniversalTime().ToString("o")
    SessionId = $ConvId
    Prompt = $Prompt
    Status = $Result.status
    DurationSeconds = $EngineDuration
    WallDurationSeconds = $WallDuration
    Tokens = [PSCustomObject]@{
        InputTokens = $InTokens
        CacheReadTokens = $CacheReadTokens
        OutputTokens = $OutTokens
        ThinkingTokens = $ThinkingTokens
        TotalTokens = $TotalTokens
    }
    QualityMetrics = [PSCustomObject]@{
        ThinkingRatioPct = $ThinkingRatio
        CacheEfficiencyPct = $CacheEfficiency
        ReasoningDepth = $ReasoningLevel
        ResponseLengthChars = $Result.response.Length
    }
    ResponseSnippet = if ($Result.response.Length -gt 500) { $Result.response.Substring(0, 500) + "... [truncated]" } else { $Result.response }
}

$SummaryJsonPath = Join-Path $SessionDir "session_summary.json"
$SummaryData | ConvertTo-Json -Depth 5 | Out-File -FilePath $SummaryJsonPath -Encoding utf8

# Ghi bao cao Markdown
$ReportMdPath = Join-Path $SessionDir "session_report.md"
$MdReportLines = @(
    "# Bao Cao Do Luong Telemetry & Danh Gia Phien: $ConvId",
    "",
    "- **Thoi gian chay**: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))",
    "- **Trang thai**: $($Result.status)",
    "- **Prompt**: $Prompt",
    "",
    "---",
    "",
    "## 1. Do Luong Token Tieu Thu (Token Usage)",
    "| Chi So Telemetry | Gia Tri | Danh Gia Y Nghia |",
    "| :--- | :--- | :--- |",
    "| **Input Tokens** | $InTokens | Tokens gui toi engine (bao gom rules va prompt) |",
    "| **Cache Read Tokens** | $CacheReadTokens | Tokens doc tu cache (tiet kiem chi phi & tang toc) |",
    "| **Output Tokens** | $OutTokens | Tong tokens model sinh ra |",
    "| **Thinking Tokens** | $ThinkingTokens | Luong token model dung de lap luan noi tam |",
    "| **Tong Tokens** | $TotalTokens | Tong chi phi transaction |",
    "",
    "---",
    "",
    "## 2. Danh Gia Chat Luong & Chi Phi (Quality Scorecard)",
    "- **Do sau lap luan (Cognitive Depth)**: **$ReasoningLevel** ($ThinkingRatio% output la token tu duy).",
    "- **Hieu qua Caching**: **$CacheEfficiency%** tokens ngu canh duoc tai su dung qua cache.",
    "- **Thoi gian phan hoi**: **$EngineDuration giay**.",
    "",
    "---",
    "",
    '## 3. Noi Dung Phan Hoi Cua Model',
    '```markdown',
    "$($Result.response)",
    '```'
)
$MdReport = $MdReportLines -join [Environment]::NewLine
$MdReport | Out-File -FilePath $ReportMdPath -Encoding utf8

Write-Box "HOAN TAT KIEM DINH TELEMETRY!" ([ConsoleColor]::Green)
Write-Host "  -> File JSON chi tiet: $SummaryJsonPath" -ForegroundColor Green
Write-Host "  -> File Markdown Report: $ReportMdPath" -ForegroundColor Green
Write-Host ""
