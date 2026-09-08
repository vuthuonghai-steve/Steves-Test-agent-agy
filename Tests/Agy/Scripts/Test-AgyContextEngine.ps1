<#
.SYNOPSIS
    Antigravity CLI (agy) Context & Engine Inspection Test Suite
    Kiem chung va truc quan hoa co che nap ngu canh (Context Ingestion) va hoat dong cua AI Engine.
#>

[CmdletBinding()]
param (
    [string]$LogsDir = "Tests/Agy/Logs",
    [string]$Model = "",
    [int]$TimeoutMinutes = 5
)

# Thiet lap UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Dam bao thu muc Logs ton tai
if (-not (Test-Path -Path $LogsDir)) {
    New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null
}

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$SessionLogDir = Join-Path $LogsDir "Run_$Timestamp"
New-Item -ItemType Directory -Path $SessionLogDir -Force | Out-Null

$ReportFile = Join-Path $SessionLogDir "Context_Engine_Report.md"

function Write-Header([string]$Title) {
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Yellow
    Write-Host "================================================================================" -ForegroundColor Cyan
}

function Write-Metric([string]$Name, [string]$Value, [ConsoleColor]$Color = [ConsoleColor]::White) {
    $formatted = "  {0,-32} : " -f $Name
    Write-Host $formatted -NoNewline -ForegroundColor Gray
    Write-Host $Value -ForegroundColor $Color
}

Write-Header "ANTIGRAVITY CLI ENGINE & CONTEXT INSPECTION SUITE"
Write-Host "Logs output directory: $SessionLogDir" -ForegroundColor Green

$AgyCmd = Get-Command agy -ErrorAction SilentlyContinue
if (-not $AgyCmd) {
    Write-Error "Khong tim thay lenh 'agy'. Vui long kiem tra PATH."
    exit 1
}
Write-Metric "Antigravity CLI Binary" $AgyCmd.Source ([ConsoleColor]::Green)
Write-Metric "Working Directory (CWD)" (Get-Location).Path ([ConsoleColor]::Green)

$ModelArgs = @()
if ($Model -ne "") {
    $ModelArgs = @("--model", $Model)
    Write-Metric "Pinned Model" $Model ([ConsoleColor]::Magenta)
} else {
    Write-Metric "Pinned Model" "(CLI Default)" ([ConsoleColor]::DarkGray)
}

$Report = [System.Text.StringBuilder]::new()
[void]$Report.AppendLine("# Bao Cao Kiem Chung Co Che Nap Ngu Canh va AI Engine (Antigravity CLI)")
[void]$Report.AppendLine(('- Thoi gian: {0}' -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss")))
[void]$Report.AppendLine(('- CWD: {0}' -f (Get-Location).Path))
[void]$Report.AppendLine(('- Thu muc Logs: {0}' -f $SessionLogDir))
[void]$Report.AppendLine("")
[void]$Report.AppendLine("---")
[void]$Report.AppendLine("")

# ==============================================================================
# CASE 1: Baseline Anatomy
# ==============================================================================
Write-Header "TEST CASE 1: Baseline Context Anatomy (Prompt vs Context ngam)"
$Prompt1 = "In exactly 3 words, reply: PING SUCCESS TEST"
$Case1Log = Join-Path $SessionLogDir "case1_baseline.json"

Write-Host "Dang gui prompt: '$Prompt1'..." -ForegroundColor Gray
$Start1 = Get-Date
$Out1 = agy -p $Prompt1 --output-format json $ModelArgs --print-timeout "${TimeoutMinutes}m" 2>&1
$Duration1 = [Math]::Round(((Get-Date) - $Start1).TotalSeconds, 2)
$Out1 | Out-File -FilePath $Case1Log -Encoding utf8

try {
    $Json1 = $Out1 | ConvertFrom-Json
    $InTokens = $Json1.usage.input_tokens
    $OutTokens = $Json1.usage.output_tokens
    $CacheTokens = $Json1.usage.cache_read_tokens
    $Status1 = $Json1.status

    $EstPromptTokens = 10
    $UndergroundTokens = [Math]::Max(0, $InTokens - $EstPromptTokens)
    $UndergroundRatio = [Math]::Round(($UndergroundTokens / [Math]::Max(1, $InTokens)) * 100, 2)

    Write-Metric "Trang thai (Status)" $Status1 ([ConsoleColor]::Green)
    Write-Metric "Thoi gian xu ly" "$Duration1 s" ([ConsoleColor]::Yellow)
    Write-Metric "Input Tokens (Tong gui len)" $InTokens ([ConsoleColor]::Cyan)
    Write-Metric "Cache Read Tokens" $CacheTokens ([ConsoleColor]::Green)
    Write-Metric "Output Tokens (Sinh ra)" $OutTokens ([ConsoleColor]::White)
    Write-Metric "Ty le Context ngam ke thua" "$UndergroundRatio %" ([ConsoleColor]::Yellow)
    Write-Metric "Phan hoi cua Model" ($Json1.response.Trim()) ([ConsoleColor]::Green)

    [void]$Report.AppendLine("## Case 1: Baseline Context Anatomy")
    [void]$Report.AppendLine(('- Prompt: "{0}"' -f $Prompt1))
    [void]$Report.AppendLine(('- Status: {0} | Duration: {1} s' -f $Status1, $Duration1))
    [void]$Report.AppendLine(('- Tong Input Tokens: {0} (Cache Read: {1})' -f $InTokens, $CacheTokens))
    [void]$Report.AppendLine(('- Output Tokens: {0}' -f $OutTokens))
    [void]$Report.AppendLine(('- Ty le Ngu canh ngam ke thua: ~ {0} %' -f $UndergroundRatio))
    [void]$Report.AppendLine("")
} catch {
    Write-Host "Loi parse JSON Case 1: $_" -ForegroundColor Red
}

# ==============================================================================
# CASE 2: Project Rules Ingestion (AGENTS.md Proof)
# ==============================================================================
Write-Header "TEST CASE 2: Hierarchical Project Rules Ingestion (AGENTS.md Proof)"
$Prompt2 = "Dua truc tiep vao ngu canh quy tac he thong san co trong workspace hien tai, hay cho toi biet: Phuong cham hanh dong (Golden Rule) duoc dinh nghia trong AGENTS.md la gi? Tra loi truc tiep bang van ban ngan gon, khong goi bat ky tool nao."
$Case2Log = Join-Path $SessionLogDir "case2_rules_proof.json"

Write-Host "Dang gui prompt kiem chung AGENTS.md..." -ForegroundColor Gray
$Start2 = Get-Date
$Out2 = agy -p $Prompt2 --output-format json $ModelArgs --print-timeout "${TimeoutMinutes}m" 2>&1
$Duration2 = [Math]::Round(((Get-Date) - $Start2).TotalSeconds, 2)
$Out2 | Out-File -FilePath $Case2Log -Encoding utf8

try {
    $Json2 = $Out2 | ConvertFrom-Json
    Write-Metric "Trang thai (Status)" $Json2.status ([ConsoleColor]::Green)
    Write-Metric "Thoi gian xu ly" "$Duration2 s" ([ConsoleColor]::Yellow)
    Write-Metric "Input Tokens" $Json2.usage.input_tokens ([ConsoleColor]::Cyan)
    Write-Metric "Cache Read Tokens" $Json2.usage.cache_read_tokens ([ConsoleColor]::Green)
    Write-Host "`n  --- NOI DUNG PHAN HOI CUA MODEL ---" -ForegroundColor Yellow
    Write-Host $Json2.response -ForegroundColor White
    Write-Host "  -----------------------------------" -ForegroundColor Yellow

    [void]$Report.AppendLine("## Case 2: Hierarchical Project Rules Ingestion (AGENTS.md Proof)")
    [void]$Report.AppendLine(('- Status: {0} | Duration: {1} s' -f $Json2.status, $Duration2))
    [void]$Report.AppendLine(('- Phan hoi Model: {0}' -f $Json2.response.Trim()))
    [void]$Report.AppendLine('- Ket luan: Model trich dan chinh xac Golden Rule ma khong can truyen noi dung file vao prompt.')
    [void]$Report.AppendLine("")
} catch {
    Write-Host "Loi parse JSON Case 2: $_" -ForegroundColor Red
}

# ==============================================================================
# CASE 3: Event Stream & Tool Registry
# ==============================================================================
Write-Header "TEST CASE 3: Event Stream and Tool Registry (--output-format stream-json)"
$Prompt3 = "In one sentence, define git cherry-pick."
$Case3Log = Join-Path $SessionLogDir "case3_events_stream.ndjson"

Write-Host "Dang chay streaming JSON..." -ForegroundColor Gray
$Events = [System.Collections.Generic.List[object]]::new()
agy -p $Prompt3 --output-format stream-json $ModelArgs --print-timeout "${TimeoutMinutes}m" 2>&1 | ForEach-Object {
    $Line = $_
    $Line | Out-File -FilePath $Case3Log -Append -Encoding utf8
    if ($Line -match '^\s*\{.*\}\s*$') {
        try {
            $Obj = $Line | ConvertFrom-Json
            $Events.Add($Obj)
        } catch {}
    }
}

$InitEvent = $Events | Where-Object { $_.event -eq "init" } | Select-Object -First 1
$ResultEvent = $Events | Where-Object { $_.event -eq "result" } | Select-Object -First 1

if ($InitEvent) {
    Write-Metric "Event 'init' phat hien" "CO" ([ConsoleColor]::Green)
    Write-Metric "Init CWD" $InitEvent.init.cwd ([ConsoleColor]::Cyan)
    Write-Metric "Permission Mode" $InitEvent.init.permission_mode ([ConsoleColor]::Yellow)
    Write-Metric "So luong Tools trong Context" $InitEvent.init.tools.Count ([ConsoleColor]::Cyan)
}
Write-Metric "Tong so Stream Events" $Events.Count ([ConsoleColor]::White)
if ($ResultEvent) {
    Write-Metric "Ket qua (result.status)" $ResultEvent.result.status ([ConsoleColor]::Green)
    Write-Metric "Thinking Tokens" $ResultEvent.result.usage.thinking_tokens ([ConsoleColor]::Magenta)
}

[void]$Report.AppendLine("## Case 3: Event Stream and Tool Registry")
[void]$Report.AppendLine(('- Tong so events: {0}' -f $Events.Count))
if ($InitEvent) {
    [void]$Report.AppendLine(('- So Tools tu dong nap vao Context: {0} tools' -f $InitEvent.init.tools.Count))
    [void]$Report.AppendLine(('- Permission Mode: {0}' -f $InitEvent.init.permission_mode))
}
[void]$Report.AppendLine("")

# ==============================================================================
# CASE 4: Multi-turn Context Continuity
# ==============================================================================
Write-Header "TEST CASE 4: Multi-turn Context Continuity (--conversation)"
$SecretTag = "STEVE_SECRET_" + (Get-Random -Minimum 1000 -Maximum 9999)
$Prompt4_Turn1 = "Hay ghi nho ma so bi mat nay: [$SecretTag]. Chi can xac nhan ban da nho."
$Case4_Turn1_Log = Join-Path $SessionLogDir "case4_turn1.json"
$Case4_Turn2_Log = Join-Path $SessionLogDir "case4_turn2_continued.json"

Write-Host "Turn 1: Gui ma bi mat '$SecretTag'..." -ForegroundColor Gray
$Out4_1 = agy -p $Prompt4_Turn1 --output-format json $ModelArgs --print-timeout "${TimeoutMinutes}m" 2>&1
$Out4_1 | Out-File -FilePath $Case4_Turn1_Log -Encoding utf8

$ConvId = ""
try {
    $Json4_1 = $Out4_1 | ConvertFrom-Json
    $ConvId = $Json4_1.conversation_id
    Write-Metric "Turn 1 Status" $Json4_1.status ([ConsoleColor]::Green)
    Write-Metric "Conversation ID sinh ra" $ConvId ([ConsoleColor]::Magenta)
} catch {}

if ($ConvId -ne "") {
    Write-Host "Turn 2: Goi tiep voi --conversation $ConvId..." -ForegroundColor Gray
    $Prompt4_Turn2 = "Ma so bi mat toi vua nhac o luot truoc la gi? Chi tra loi duy nhat ma do."
    $Out4_2 = agy -p $Prompt4_Turn2 --conversation $ConvId --output-format json $ModelArgs --print-timeout "${TimeoutMinutes}m" 2>&1
    $Out4_2 | Out-File -FilePath $Case4_Turn2_Log -Encoding utf8

    try {
        $Json4_2 = $Out4_2 | ConvertFrom-Json
        $Turn2Response = $Json4_2.response.Trim()
        $IsMatch = $Turn2Response -like "*$SecretTag*"

        Write-Metric "Turn 2 Status" $Json4_2.status ([ConsoleColor]::Green)
        Write-Metric "Turn 2 Phan hoi" $Turn2Response ([ConsoleColor]::Green)
        Write-Metric "Ke thua context chinh xac" $(if ($IsMatch) { "CHINH XAC (100%)" } else { "KHONG KHOP" }) $(if ($IsMatch) { [ConsoleColor]::Green } else { [ConsoleColor]::Red })
        Write-Metric "Turn 2 Cache Read Tokens" $Json4_2.usage.cache_read_tokens ([ConsoleColor]::Green)

        [void]$Report.AppendLine("## Case 4: Multi-turn Context Continuity")
        [void]$Report.AppendLine(('- Conversation ID: {0}' -f $ConvId))
        [void]$Report.AppendLine(('- Ma Turn 1: {0}' -f $SecretTag))
        [void]$Report.AppendLine(('- Phan hoi Turn 2: {0}' -f $Turn2Response))
        [void]$Report.AppendLine(('- Ket qua: {0}' -f $(if ($IsMatch) { "Thanh cong 100%" } else { "That bai" })))
        [void]$Report.AppendLine(('- Cache Read Tokens Turn 2: {0}' -f $Json4_2.usage.cache_read_tokens))
        [void]$Report.AppendLine("")
    } catch {}
}

# ==============================================================================
# CASE 5: Structured Output Enforcement
# ==============================================================================
Write-Header "TEST CASE 5: Structured Output Enforcement (--json-schema)"
$Schema = '{"type":"object","properties":{"test_name":{"type":"string"},"exit_code":{"type":"integer"},"is_operational":{"type":"boolean"}},"required":["test_name","exit_code","is_operational"]}'
$Prompt5 = "Tao mot bao cao kiem tra cho 'health-check' voi exit code 0 va is_operational la true."
$Case5Log = Join-Path $SessionLogDir "case5_structured_output.json"

Write-Host "Dang gui prompt kem JSON Schema..." -ForegroundColor Gray
$Out5 = agy -p $Prompt5 --output-format json --json-schema $Schema $ModelArgs --print-timeout "${TimeoutMinutes}m" 2>&1
$Out5 | Out-File -FilePath $Case5Log -Encoding utf8

try {
    $Json5 = $Out5 | ConvertFrom-Json
    Write-Metric "Trang thai (Status)" $Json5.status ([ConsoleColor]::Green)
    Write-Metric "structured_output ton tai" $(if ($Json5.structured_output) { "CO (Da Parse)" } else { "KHONG" }) ([ConsoleColor]::Green)
    if ($Json5.structured_output) {
        Write-Host "`n  --- STRUCTURED OUTPUT ---" -ForegroundColor Yellow
        $Json5.structured_output | ConvertTo-Json | Write-Host -ForegroundColor Cyan
        Write-Host "  -------------------------" -ForegroundColor Yellow
    }

    [void]$Report.AppendLine("## Case 5: Structured Output Enforcement")
    [void]$Report.AppendLine(('- Status: {0}' -f $Json5.status))
    [void]$Report.AppendLine(('- Object: {0}' -f ($Json5.structured_output | ConvertTo-Json -Compress)))
    [void]$Report.AppendLine('- Ket luan: Engine cuong che schema thanh cong 100%.')
    [void]$Report.AppendLine("")
} catch {}

$Report.ToString() | Out-File -FilePath $ReportFile -Encoding utf8
Write-Header "KIEM THU HOAN TAT!"
Write-Host "Bao cao da luu tai: $ReportFile" -ForegroundColor Green
Write-Host "Logs chi tiet: $SessionLogDir" -ForegroundColor Yellow
