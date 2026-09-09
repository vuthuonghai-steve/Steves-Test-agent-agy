<#
.SYNOPSIS
    Antigravity Session Deep Reporter & Observability Analyzer
    Phan tich toan dien hieu nang, cong cu, tai nguyen va chat luong phien chat tu du lieu NDJSON cua Hooks.
.EXAMPLE
    .\Get-AgySessionReport.ps1 -Latest
    .\Get-AgySessionReport.ps1 -Latest -ExportMarkdown
    .\Get-AgySessionReport.ps1 -SessionDir "Tests/Agy/Logs/Sessions/2026-09-09_042709_32015389-..."
#>

[CmdletBinding()]
param (
    [string]$SessionDir = "",
    [switch]$Latest,
    [switch]$ExportMarkdown,
    [string]$LogsDir = "Tests/Agy/Logs/Sessions"
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

function Write-Header([string]$Text, [ConsoleColor]$Color = [ConsoleColor]::Cyan) {
    Write-Host ""
    Write-Host ("=" * 85) -ForegroundColor $Color
    Write-Host "  $Text" -ForegroundColor Yellow
    Write-Host ("=" * 85) -ForegroundColor $Color
}

function Write-SubHeader([string]$Text) {
    Write-Host "`n--- $Text ---" -ForegroundColor Cyan
}

function Write-Metric([string]$Name, [string]$Value, [ConsoleColor]$Color = [ConsoleColor]::White) {
    $formatted = "  {0,-35} : " -f $Name
    Write-Host $formatted -NoNewline -ForegroundColor Gray
    Write-Host $Value -ForegroundColor $Color
}

# 1. Xac dinh thu muc Session can phan tich
if ($Latest -or ($SessionDir -eq "")) {
    $LatestFile = Join-Path $LogsDir "LATEST_SESSION.txt"
    if (Test-Path $LatestFile) {
        $LatestDirName = (Get-Content $LatestFile -Raw).Trim()
        $TargetDir = Join-Path $LogsDir $LatestDirName
        if (Test-Path $TargetDir) {
            $SessionDir = $TargetDir
        }
    }
    
    if ($SessionDir -eq "" -or (-not (Test-Path $SessionDir))) {
        # Fallback: Lay thu muc co thoi gian tao moi nhat
        $Dirs = Get-ChildItem -Path $LogsDir -Directory | Sort-Object CreationTime -Descending
        if ($Dirs.Count -gt 0) {
            $SessionDir = $Dirs[0].FullName
        } else {
            Write-Error "Khong tim thay thu muc session nao trong '$LogsDir'."
            exit 1
        }
    }
}

$SessionDirName = Split-Path $SessionDir -Leaf
Write-Header "ANTIGRAVITY SESSION DEEP REPORT & OBSERVABILITY ANALYZER"
Write-Metric "Thu muc phien lam viec" $SessionDirName ([ConsoleColor]::Yellow)

# 2. Doc tat ca cac file NDJSON trong thu muc
$NdjsonFiles = Get-ChildItem -Path $SessionDir -Filter "*.ndjson"
if ($NdjsonFiles.Count -eq 0) {
    Write-Error "Khong tim thay file .ndjson nao trong $SessionDir."
    exit 1
}

$AllEvents = @()
foreach ($file in $NdjsonFiles) {
    $lines = Get-Content $file.FullName -Encoding UTF8
    foreach ($line in $lines) {
        if ($line.Trim()) {
            try {
                $evt = $line | ConvertFrom-Json
                $evt | Add-Member -NotePropertyName "SourceFile" -NotePropertyValue $file.Name -Force
                $AllEvents += $evt
            } catch {}
        }
    }
}

# 3. Phan tich du lieu
$MainAgentEvents = @($AllEvents | Where-Object { ($_.IsSubagent -eq $false) -or ($_.Agent.IsSubagent -eq $false) })
$SubagentEvents = @($AllEvents | Where-Object { ($_.IsSubagent -eq $true) -or ($_.Agent.IsSubagent -eq $true) })

# Thong ke Subagents
$SubagentGroups = @($SubagentEvents | Group-Object ConversationId)
$SubagentCount = $SubagentGroups.Count

# Thong ke Tool Calls
$ToolCalls = $AllEvents | Where-Object { $_.HookType -eq "PostToolUse" -and $_.ToolName -and $_.ToolName -ne "none" }
$ToolGroups = $ToolCalls | Group-Object ToolName

# Thong ke Tai nguyen (Targets / Files)
$Targets = $AllEvents | Where-Object { $_.TargetResource } | Select-Object -ExpandProperty TargetResource -Unique

# Doc Summary neu co
$SummaryFile = Join-Path $SessionDir "session_summary.json"
$SummaryData = $null
if (Test-Path $SummaryFile) {
    try {
        $SummaryData = Get-Content $SummaryFile -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {}
}

# 4. Hien thi thong so tong quan
Write-SubHeader "[1] TONG QUAN PHIEN LAM VIEC"
Write-Metric "Tong so Lifecycle Events" $AllEvents.Count ([ConsoleColor]::White)
Write-Metric "Su kien Main Agent" $MainAgentEvents.Count ([ConsoleColor]::White)
Write-Metric "So luong Subagents duoc spawn" $SubagentCount $(if ($SubagentCount -gt 0) { [ConsoleColor]::Green } else { [ConsoleColor]::Gray })
Write-Metric "Tong so luot goi Tool" $ToolCalls.Count ([ConsoleColor]::Yellow)

if ($SummaryData) {
    Write-SubHeader "[2] TIEU HAO TAI NGUYEN & TOKEN (ENGINE DATA)"
    $statusVal = if ($SummaryData.Status) { $SummaryData.Status } else { $SummaryData.status }
    $durVal = if ($SummaryData.DurationSeconds) { $SummaryData.DurationSeconds } else { $SummaryData.duration_seconds }
    $tok = if ($SummaryData.Tokens) { $SummaryData.Tokens } else { $SummaryData.tokens }
    $qm = if ($SummaryData.QualityMetrics) { $SummaryData.QualityMetrics } else { $SummaryData.quality_metrics }

    $inTok = if ($tok.InputTokens) { $tok.InputTokens } else { $tok.input_tokens }
    $cacheTok = if ($tok.CacheReadTokens) { $tok.CacheReadTokens } else { $tok.cache_read_tokens }
    $outTok = if ($tok.OutputTokens) { $tok.OutputTokens } else { $tok.output_tokens }
    $thinkTok = if ($tok.ThinkingTokens) { $tok.ThinkingTokens } else { $tok.thinking_tokens }
    $totalTok = if ($tok.TotalTokens) { $tok.TotalTokens } else { $tok.total_tokens }
    $cacheEff = if ($qm.CacheEfficiencyPct) { $qm.CacheEfficiencyPct } else { $qm.cache_efficiency_pct }
    $thinkRatio = if ($qm.ThinkingRatioPct) { $qm.ThinkingRatioPct } else { $qm.thinking_ratio_pct }

    Write-Metric "Trang thai Engine" $statusVal $(if ($statusVal -eq "SUCCESS") { [ConsoleColor]::Green } else { [ConsoleColor]::Red })
    Write-Metric "Thoi gian phan hoi Engine" "$durVal s" ([ConsoleColor]::Yellow)
    Write-Metric "Input Tokens" "$inTok tokens" ([ConsoleColor]::Cyan)
    Write-Metric "Cache Read Tokens" "$cacheTok tokens ($cacheEff% tiet kiem)" ([ConsoleColor]::Green)
    Write-Metric "Output Tokens" "$outTok tokens" ([ConsoleColor]::White)
    Write-Metric "Thinking Tokens" "$thinkTok tokens ($thinkRatio% do sau tu duy)" ([ConsoleColor]::Magenta)
    Write-Metric "Tong Tokens giao dich" "$totalTok tokens" ([ConsoleColor]::Yellow)
}

# 5. Bang thong ke chi tiet cong cu (Tool Distribution & Latency)
Write-SubHeader "[3] PHAN BO CONG CU & THOI GIAN THUC THI (TOOL LATENCY)"
$headerStr = "  {0,-25} | {1,-10} | {2,-12} | {3,-12} | {4,-10}" -f "Ten Cong Cu (Tool)", "So Luot", "TB Latency", "Tong Latency", "Trang Thai"
Write-Host $headerStr -ForegroundColor Gray
Write-Host ("  " + ("-" * 78)) -ForegroundColor DarkGray

foreach ($g in $ToolGroups) {
    $durations = $g.Group | Where-Object { $_.ActualDurationMs -or ($_.Timing -and $_.Timing.ToolDurationMs) } | ForEach-Object { 
        if ($_.ActualDurationMs) { [double]$_.ActualDurationMs } else { [double]$_.Timing.ToolDurationMs }
    }
    $avgDur = if ($durations.Count -gt 0) { [Math]::Round(($durations | Measure-Object -Average).Average, 1) } else { 0 }
    $sumDur = if ($durations.Count -gt 0) { [Math]::Round(($durations | Measure-Object -Sum).Sum, 1) } else { 0 }
    $errors = $g.Group | Where-Object { $_.Error }
    $statusStr = if ($errors.Count -eq 0) { "100% OK" } else { "$($errors.Count) Loi" }
    $statusColor = if ($errors.Count -eq 0) { [ConsoleColor]::Green } else { [ConsoleColor]::Red }
    
    $line = "  {0,-25} | {1,-10} | {2,-12} | {3,-12} | " -f $g.Name, $g.Count, "${avgDur}ms", "${sumDur}ms"
    Write-Host $line -NoNewline -ForegroundColor White
    Write-Host $statusStr -ForegroundColor $statusColor
}

# 6. Danh sach Subagents da tham gia
if ($SubagentCount -gt 0) {
    Write-SubHeader "[4] CHI TIET SUBAGENTS DA THAM GIA"
    foreach ($sg in $SubagentGroups) {
        $firstEvt = $sg.Group[0]
        $subFile = $firstEvt.SourceFile
        $toolCallsInSub = ($sg.Group | Where-Object { $_.HookType -eq "PostToolUse" }).Count
        Write-Metric "Subagent File" $subFile ([ConsoleColor]::Green)
        Write-Metric "  -> Conversation ID" $sg.Name ([ConsoleColor]::DarkGray)
        Write-Metric "  -> So thao tac Tool" "$toolCallsInSub tools" ([ConsoleColor]::White)
    }
}

# 7. Dau chan tai nguyen (Resource Footprint)
if ($Targets.Count -gt 0) {
    Write-SubHeader "[5] DAU CHAN TAI NGUYEN (RESOURCE FOOTPRINT)"
    foreach ($target in ($Targets | Select-Object -First 10)) {
        Write-Host "  * $target" -ForegroundColor Gray
    }
    if ($Targets.Count -gt 10) {
        Write-Host "  ... va $($Targets.Count - 10) tai nguyen khac." -ForegroundColor DarkGray
    }
}

# 8. Xuat bao cao Markdown (session_report.md) neu co flag -ExportMarkdown hoac chua co report
$ReportFile = Join-Path $SessionDir "session_report.md"
if ($ExportMarkdown -or (-not (Test-Path $ReportFile))) {
    Write-SubHeader "[6] XUAT BAN BAO CAO MARKDOWN"
    
    $lastPrompt = if ($SummaryData.Prompt) { $SummaryData.Prompt } else { "Khong co thong tin" }
    $lastThinking = ""
    $lastResponse = ""
    
    for ($i = $AllEvents.Count - 1; $i -ge 0; $i--) {
        $q = $AllEvents[$i].QualityTelemetry
        if ($q) {
            if ($lastPrompt -eq "Khong co thong tin" -and $q.LastUserPrompt) { $lastPrompt = $q.LastUserPrompt }
            if ($lastThinking -eq "" -and $q.ThinkingSnippet) { $lastThinking = $q.ThinkingSnippet }
            if ($lastResponse -eq "" -and $q.ModelResponseSnippet) { $lastResponse = $q.ModelResponseSnippet }
        }
    }

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("# Bao Cao Do Luong Telemetry & Danh Gia Phien: $SessionDirName")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("- **Thoi gian tao**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    [void]$sb.AppendLine("- **Trang thai**: SUCCESS")
    [void]$sb.AppendLine("- **Prompt gan nhat**: $lastPrompt")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("## 1. Phan Bo Cong Cu & Thoi Gian Thuc Thi (Tool Latency)")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("| Ten Cong Cu (Tool) | So Luot | TB Latency | Tong Latency | Trang Thai |")
    [void]$sb.AppendLine("| :--- | :--- | :--- | :--- | :--- |")
    
    foreach ($g in $ToolGroups) {
        $durations = $g.Group | Where-Object { $_.ActualDurationMs -or ($_.Timing -and $_.Timing.ToolDurationMs) } | ForEach-Object { 
            if ($_.ActualDurationMs) { [double]$_.ActualDurationMs } else { [double]$_.Timing.ToolDurationMs }
        }
        $avgDur = if ($durations.Count -gt 0) { [Math]::Round(($durations | Measure-Object -Average).Average, 1) } else { 0 }
        $sumDur = if ($durations.Count -gt 0) { [Math]::Round(($durations | Measure-Object -Sum).Sum, 1) } else { 0 }
        $errors = $g.Group | Where-Object { $_.Error }
        $statusStr = if ($errors.Count -eq 0) { "100% OK" } else { "$($errors.Count) Loi" }
        [void]$sb.AppendLine("| **``$($g.Name)``** | $($g.Count) | ${avgDur}ms | ${sumDur}ms | $statusStr |")
    }

    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("## 2. Dau Chan Tai Nguyen (Resource Footprint)")
    [void]$sb.AppendLine("")
    foreach ($target in ($Targets | Select-Object -First 15)) {
        [void]$sb.AppendLine("- ``$target``")
    }
    if ($Targets.Count -gt 15) {
        [void]$sb.AppendLine("*... va $($Targets.Count - 15) tai nguyen khac.*")
    }

    if ($lastThinking) {
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("---")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("## 3. Noi Suy Tu Duy (Thinking Snippet)")
        [void]$sb.AppendLine('```markdown')
        [void]$sb.AppendLine($lastThinking)
        [void]$sb.AppendLine('```')
    }

    if ($lastResponse) {
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("---")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("## 4. Tom Tat Phan Hoi Cua Model")
        [void]$sb.AppendLine('```markdown')
        [void]$sb.AppendLine($lastResponse)
        [void]$sb.AppendLine('```')
    }

    [System.IO.File]::WriteAllText($ReportFile, $sb.ToString(), [System.Text.Encoding]::UTF8)
    Write-Metric "Da xuat bao cao Markdown" $ReportFile ([ConsoleColor]::Green)
}

Write-Header "HOAN TAT PHAN TICH SESSION OBSERVABILITY!" ([ConsoleColor]::Green)
Write-Host ""
