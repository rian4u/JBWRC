# =============================================================================
# Claude Code 팀 환경 설치 스크립트 (PowerShell)
# 사용법: powershell -ExecutionPolicy Bypass -File install.ps1
# 업데이트: 동일 명령 재실행
# =============================================================================
$ErrorActionPreference = "Stop"

$RepoUrl = "https://github.com/rian4u/JBWRC.git"
$ClaudeHome = "$env:USERPROFILE\.claude"
$TempDir = Join-Path $env:TEMP "claude-team-config-$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$BackupDir = Join-Path $ClaudeHome "backups\team-config-$(Get-Date -Format 'yyyyMMdd_HHmmss')"

function Write-Info($msg)  { Write-Host "[INFO] $msg" -ForegroundColor Green }
function Write-Warn($msg)  { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg)   { Write-Host "[ERROR] $msg" -ForegroundColor Red; exit 1 }

# --- 사전 조건 확인 ---
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Err "git이 설치되어 있지 않습니다."
}

# --- 레포 클론 ---
Write-Info "팀 설정 레포를 다운로드합니다..."
git clone --depth 1 $RepoUrl "$TempDir\repo" 2>$null
if ($LASTEXITCODE -ne 0) { Write-Err "레포 클론 실패. URL을 확인하세요: $RepoUrl" }

$ConfigDir = "$TempDir\repo\config"

# --- 디렉토리 생성 ---
@(
    $ClaudeHome,
    "$ClaudeHome\docs\users",
    "$ClaudeHome\skills"
) | ForEach-Object { New-Item -ItemType Directory -Path $_ -Force | Out-Null }

# --- 백업 ---
Write-Info "기존 설정을 백업합니다... ($BackupDir)"
New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

function Backup-IfExists($src, $destRelative) {
    if (Test-Path $src) {
        $dest = Join-Path $BackupDir $destRelative
        $destDir = Split-Path $dest -Parent
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        Copy-Item -Path $src -Destination $dest -Recurse -Force
    }
}

Backup-IfExists "$ClaudeHome\CLAUDE.md" "CLAUDE.md"
Backup-IfExists "$ClaudeHome\docs\conventions.md" "docs\conventions.md"
Backup-IfExists "$ClaudeHome\docs\engineering.md" "docs\engineering.md"
Backup-IfExists "$ClaudeHome\settings.json" "settings.json"

Get-ChildItem "$ClaudeHome\skills" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    Backup-IfExists $_.FullName "skills\$($_.Name)"
}

# --- 파일 복사 ---
Write-Info "CLAUDE.md 복사..."
Copy-Item "$ConfigDir\CLAUDE.md" "$ClaudeHome\CLAUDE.md" -Force

Write-Info "docs 복사..."
Copy-Item "$ConfigDir\docs\conventions.md" "$ClaudeHome\docs\conventions.md" -Force
Copy-Item "$ConfigDir\docs\engineering.md" "$ClaudeHome\docs\engineering.md" -Force

Write-Info "skills 복사..."
Get-ChildItem "$ConfigDir\skills" -Directory | ForEach-Object {
    $skillName = $_.Name
    $destSkill = "$ClaudeHome\skills\$skillName"
    New-Item -ItemType Directory -Path $destSkill -Force | Out-Null
    Copy-Item "$($_.FullName)\SKILL.md" "$destSkill\SKILL.md" -Force
}

# --- settings.json 병합 ---
Write-Info "settings.json 처리..."

if (Test-Path "$ClaudeHome\settings.json") {
    try {
        $existing = Get-Content "$ClaudeHome\settings.json" -Raw -Encoding UTF8 | ConvertFrom-Json
        $team = Get-Content "$ConfigDir\settings.json" -Raw -Encoding UTF8 | ConvertFrom-Json

        # 팀 설정 키 병합
        $existing.enabledPlugins = $team.enabledPlugins
        $existing.extraKnownMarketplaces = $team.extraKnownMarketplaces
        $existing.autoUpdatesChannel = $team.autoUpdatesChannel

        # WebSearch 권한 확인
        if (-not $existing.permissions) {
            $existing | Add-Member -NotePropertyName "permissions" -NotePropertyValue @{} -Force
        }
        if (-not $existing.permissions.allow) {
            $existing.permissions | Add-Member -NotePropertyName "allow" -NotePropertyValue @() -Force
        }
        if ($existing.permissions.allow -notcontains "WebSearch") {
            $existing.permissions.allow += "WebSearch"
        }

        $existing | ConvertTo-Json -Depth 10 | Set-Content "$ClaudeHome\settings.json" -Encoding UTF8
        Write-Info "  -> 기존 settings.json에 팀 설정을 병합했습니다."
    } catch {
        Write-Warn "settings.json 병합 실패. 기존 파일을 유지합니다."
    }
} else {
    Copy-Item "$ConfigDir\settings.json" "$ClaudeHome\settings.json" -Force
    Write-Info "  -> 새 settings.json을 생성했습니다."
}

# --- 완료 ---
Write-Host ""
Write-Info "============================================"
Write-Info "  설치 완료!"
Write-Info "============================================"
Write-Host ""
Write-Host "  복사된 파일:"
Write-Host "    - CLAUDE.md (글로벌 지침)"
Write-Host "    - docs/conventions.md (문서 작성 지침)"
Write-Host "    - docs/engineering.md (전산 원칙)"
Write-Host "    - skills/ (9개 스킬)"
Write-Host "    - settings.json (플러그인 설정)"
Write-Host ""
Write-Host "  백업 위치: $BackupDir"
Write-Host ""

$profiles = Get-ChildItem "$ClaudeHome\docs\users\*.md" -ErrorAction SilentlyContinue
if (-not $profiles) {
    Write-Warn "사용자 프로필이 없습니다."
    Write-Host "  Claude Code를 실행하면 자동으로 프로필 생성을 안내합니다."
    Write-Host ""
}

Write-Host "  플러그인(context7, playwright)은 Claude Code에서 자동 설치됩니다."
Write-Host "  업데이트하려면 이 스크립트를 다시 실행하세요."
Write-Host ""

# --- 정리 ---
Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
