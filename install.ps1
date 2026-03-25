# =============================================================================
# Claude Code 환경 설치/업데이트 스크립트 (PowerShell)
# 사용법: powershell -ExecutionPolicy Bypass -File install.ps1
# 업데이트: 동일 명령 재실행 (동일 파일은 덮어씀)
# =============================================================================
$ErrorActionPreference = "Stop"

$RepoUrl = "https://github.com/rian4u/JBWRC.git"
$ClaudeHome = "$env:USERPROFILE\.claude"
$TempDir = Join-Path $env:TEMP "claude-config-$(Get-Date -Format 'yyyyMMdd_HHmmss')"

function Write-Info($msg)  { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn($msg)  { Write-Host "  [!] $msg" -ForegroundColor Yellow }
function Write-Err($msg)   { Write-Host "  [X] $msg" -ForegroundColor Red; exit 1 }

# --- 사전 조건 확인 ---
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Err "git이 설치되어 있지 않습니다. https://git-scm.com/download/win"
}

# --- 레포 클론 ---
Write-Info "설정 파일 다운로드 중..."
git clone --depth 1 $RepoUrl "$TempDir\repo" 2>$null
if ($LASTEXITCODE -ne 0) { Write-Err "다운로드 실패. 인터넷 연결을 확인하세요." }

$ConfigDir = "$TempDir\repo\config"

# --- 디렉토리 생성 ---
@(
    $ClaudeHome,
    "$ClaudeHome\docs",
    "$ClaudeHome\docs\users",
    "$ClaudeHome\skills"
) | ForEach-Object { New-Item -ItemType Directory -Path $_ -Force | Out-Null }

# --- CLAUDE.md 복사 ---
Write-Info "CLAUDE.md 복사..."
Copy-Item "$ConfigDir\CLAUDE.md" "$ClaudeHome\CLAUDE.md" -Force

# --- docs/ 복사 (users/ 제외, 동일 파일 덮어씀) ---
Write-Info "docs/ 복사..."
$docsCopied = 0
Get-ChildItem "$ConfigDir\docs\*.md" -File | ForEach-Object {
    Copy-Item $_.FullName "$ClaudeHome\docs\$($_.Name)" -Force
    $docsCopied++
}
Write-Host "       $docsCopied 개 문서 지침" -ForegroundColor Gray

# --- skills/ 복사 (로컬 전용 스킬은 유지, 동일 스킬은 덮어씀) ---
Write-Info "skills/ 복사..."
$skillsCopied = 0
Get-ChildItem "$ConfigDir\skills" -Directory | ForEach-Object {
    $skillName = $_.Name
    $destSkill = "$ClaudeHome\skills\$skillName"
    New-Item -ItemType Directory -Path $destSkill -Force | Out-Null
    Get-ChildItem $_.FullName -File | ForEach-Object {
        Copy-Item $_.FullName "$destSkill\$($_.Name)" -Force
    }
    $skillsCopied++
}
Write-Host "       $skillsCopied 개 스킬" -ForegroundColor Gray

# --- settings.json 처리 ---
Write-Info "settings.json 처리..."
if (Test-Path "$ConfigDir\settings.json") {
    if (Test-Path "$ClaudeHome\settings.json") {
        try {
            $existing = Get-Content "$ClaudeHome\settings.json" -Raw -Encoding UTF8 | ConvertFrom-Json
            $team = Get-Content "$ConfigDir\settings.json" -Raw -Encoding UTF8 | ConvertFrom-Json

            $team.PSObject.Properties | ForEach-Object {
                $key = $_.Name
                $val = $_.Value
                if ($existing.PSObject.Properties[$key]) {
                    $existing.$key = $val
                } else {
                    $existing | Add-Member -NotePropertyName $key -NotePropertyValue $val -Force
                }
            }

            $existing | ConvertTo-Json -Depth 10 | Set-Content "$ClaudeHome\settings.json" -Encoding UTF8
            Write-Host "       기존 settings.json에 병합 완료" -ForegroundColor Gray
        } catch {
            Write-Warn "settings.json 병합 실패. 기존 파일 유지."
        }
    } else {
        Copy-Item "$ConfigDir\settings.json" "$ClaudeHome\settings.json" -Force
        Write-Host "       새 settings.json 생성" -ForegroundColor Gray
    }
}

# --- 완료 ---
Write-Host ""
Write-Host "  ========================================" -ForegroundColor Cyan
Write-Host "   설치 완료!" -ForegroundColor Cyan
Write-Host "  ========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Claude Code를 재시작하면 적용됩니다."
Write-Host ""

$profiles = Get-ChildItem "$ClaudeHome\docs\users\*.md" -ErrorAction SilentlyContinue
if (-not $profiles) {
    Write-Warn "사용자 프로필이 없습니다."
    Write-Host "       Claude Code 실행 시 자동으로 프로필 생성을 안내합니다."
    Write-Host ""
}

# --- 정리 ---
Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
