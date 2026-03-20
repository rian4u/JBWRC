#!/usr/bin/env bash
# =============================================================================
# Claude Code 팀 환경 설치 스크립트
# 사용법: bash install.sh
# 업데이트: 동일 명령 재실행
# =============================================================================
set -euo pipefail

REPO_URL="https://github.com/rian4u/JBWRC.git"
CLAUDE_HOME="$HOME/.claude"
TEMP_DIR="$(mktemp -d)"
BACKUP_DIR="$CLAUDE_HOME/backups/team-config-$(date +%Y%m%d_%H%M%S)"

# 색상
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- 사전 조건 확인 ---
command -v git >/dev/null 2>&1 || error "git이 설치되어 있지 않습니다."

# --- 레포 클론 ---
info "팀 설정 레포를 다운로드합니다..."
git clone --depth 1 "$REPO_URL" "$TEMP_DIR/repo" 2>/dev/null || error "레포 클론 실패. URL을 확인하세요: $REPO_URL"

CONFIG_DIR="$TEMP_DIR/repo/config"

# --- ~/.claude 디렉토리 확인 ---
mkdir -p "$CLAUDE_HOME"
mkdir -p "$CLAUDE_HOME/docs/users"
mkdir -p "$CLAUDE_HOME/skills"

# --- 백업 ---
info "기존 설정을 백업합니다... ($BACKUP_DIR)"
mkdir -p "$BACKUP_DIR"

backup_if_exists() {
    local src="$1"
    local dest="$BACKUP_DIR/$2"
    if [ -e "$src" ]; then
        mkdir -p "$(dirname "$dest")"
        cp -r "$src" "$dest"
    fi
}

backup_if_exists "$CLAUDE_HOME/CLAUDE.md" "CLAUDE.md"
backup_if_exists "$CLAUDE_HOME/docs/conventions.md" "docs/conventions.md"
backup_if_exists "$CLAUDE_HOME/docs/engineering.md" "docs/engineering.md"
backup_if_exists "$CLAUDE_HOME/settings.json" "settings.json"

for skill_dir in "$CLAUDE_HOME/skills"/*/; do
    if [ -d "$skill_dir" ]; then
        skill_name="$(basename "$skill_dir")"
        backup_if_exists "$skill_dir" "skills/$skill_name"
    fi
done

# --- 파일 복사 ---
info "CLAUDE.md 복사..."
cp "$CONFIG_DIR/CLAUDE.md" "$CLAUDE_HOME/CLAUDE.md"

info "docs 복사..."
cp "$CONFIG_DIR/docs/conventions.md" "$CLAUDE_HOME/docs/conventions.md"
cp "$CONFIG_DIR/docs/engineering.md" "$CLAUDE_HOME/docs/engineering.md"

info "skills 복사..."
for skill_dir in "$CONFIG_DIR/skills"/*/; do
    if [ -d "$skill_dir" ]; then
        skill_name="$(basename "$skill_dir")"
        mkdir -p "$CLAUDE_HOME/skills/$skill_name"
        cp "$skill_dir/SKILL.md" "$CLAUDE_HOME/skills/$skill_name/SKILL.md"
    fi
done

# --- settings.json 병합 ---
info "settings.json 처리..."

if [ -f "$CLAUDE_HOME/settings.json" ]; then
    # 기존 설정이 있으면: 팀 설정의 enabledPlugins, extraKnownMarketplaces, autoUpdatesChannel만 업데이트
    # 개인 permissions는 유지
    if command -v python3 >/dev/null 2>&1 || command -v python >/dev/null 2>&1; then
        PYTHON=$(command -v python3 || command -v python)
        $PYTHON - "$CLAUDE_HOME/settings.json" "$CONFIG_DIR/settings.json" << 'PYEOF'
import json, sys

existing_path, team_path = sys.argv[1], sys.argv[2]

with open(existing_path, 'r', encoding='utf-8') as f:
    existing = json.load(f)
with open(team_path, 'r', encoding='utf-8') as f:
    team = json.load(f)

# 팀 설정에서 가져올 키들 (개인 permissions는 건드리지 않음)
for key in ['enabledPlugins', 'extraKnownMarketplaces', 'autoUpdatesChannel']:
    if key in team:
        existing[key] = team[key]

# permissions.allow에 WebSearch가 없으면 추가
perms = existing.setdefault('permissions', {})
allow = perms.setdefault('allow', [])
if 'WebSearch' not in allow:
    allow.append('WebSearch')

with open(existing_path, 'w', encoding='utf-8') as f:
    json.dump(existing, f, indent=2, ensure_ascii=False)
    f.write('\n')

print("  -> 기존 settings.json에 팀 설정을 병합했습니다.")
PYEOF
    else
        warn "Python이 없어 settings.json 병합을 건너뜁니다. 수동으로 설정하세요."
    fi
else
    # 기존 설정이 없으면 팀 설정 그대로 복사
    cp "$CONFIG_DIR/settings.json" "$CLAUDE_HOME/settings.json"
    info "  -> 새 settings.json을 생성했습니다."
fi

# --- 플러그인 설치 안내 ---
echo ""
info "============================================"
info "  설치 완료!"
info "============================================"
echo ""
echo "  복사된 파일:"
echo "    - CLAUDE.md (글로벌 지침)"
echo "    - docs/conventions.md (문서 작성 지침)"
echo "    - docs/engineering.md (전산 원칙)"
echo "    - skills/ (9개 스킬)"
echo "    - settings.json (플러그인 설정)"
echo ""
echo "  백업 위치: $BACKUP_DIR"
echo ""

if [ ! -f "$CLAUDE_HOME/docs/users/"*.md ] 2>/dev/null; then
    warn "사용자 프로필이 없습니다."
    echo "  Claude Code를 실행하면 자동으로 프로필 생성을 안내합니다."
    echo ""
fi

echo "  플러그인(context7, playwright)은 Claude Code에서 자동 설치됩니다."
echo "  업데이트하려면 이 스크립트를 다시 실행하세요."
echo ""

# --- 정리 ---
rm -rf "$TEMP_DIR"
