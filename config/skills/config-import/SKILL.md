---
name: config-import
description: GitHub 리포(rian4u/JBWRC)에서 글로벌 지침·문서 지침·스킬을 가져와 로컬에 덮어쓴다. "가져오기", "import", "pull", "깃헙에서 받아" 등의 요청 시 실행한다.
---

# Config Import Skill

GitHub 리포의 `config/` 폴더 내용을 로컬 `~/.claude/`로 가져온다.
동일한 파일이 있으면 덮어쓴다.

---

## 가져오기 대상

| 리포 경로 | 로컬 경로 | 비고 |
|---------|---------|------|
| `config/CLAUDE.md` | `~/.claude/CLAUDE.md` | 글로벌 운영 지침 |
| `config/docs/*.md` | `~/.claude/docs/*.md` | 문서 작성 지침 |
| `config/skills/*/` | `~/.claude/skills/*/` | 스킬 전체 |
| `config/settings.json` | `~/.claude/settings.json` | 설정 파일 (있는 경우만) |

**보존 대상 (덮어쓰지 않음):**
- `~/.claude/docs/users/` — 로컬 전용 개인 프로필
- `~/.claude/projects/` — 프로젝트별 메모리
- 리포에 없지만 로컬에만 있는 스킬 — 삭제하지 않고 유지

---

## 실행 절차

### 1단계: 사전 확인

1. `gh auth status`로 GitHub 인증 상태 확인
2. 인증 안 되어 있으면 `gh auth login` 안내 후 종료

### 2단계: 리포 다운로드

1. 임시 디렉토리에 리포를 shallow clone한다:
   ```bash
   TEMP_DIR=$(mktemp -d)
   git clone --depth 1 https://github.com/rian4u/JBWRC.git "$TEMP_DIR/JBWRC"
   ```

### 3단계: 변경 사항 미리보기

1. 리포의 `config/` 와 로컬 `~/.claude/`를 비교한다:
   - 새로 추가될 파일
   - 덮어쓰여질 파일 (diff 표시)
   - 로컬에만 있는 파일 (유지됨)
2. `AskUserQuestion`으로 가져오기 확인

### 4단계: 파일 복사 (덮어쓰기)

승인 시 아래를 실행한다:

```bash
REPO_CONFIG="$TEMP_DIR/JBWRC/config"

# CLAUDE.md 덮어쓰기
[ -f "$REPO_CONFIG/CLAUDE.md" ] && cp "$REPO_CONFIG/CLAUDE.md" ~/.claude/CLAUDE.md

# docs/ 덮어쓰기 (users/ 보존)
if [ -d "$REPO_CONFIG/docs" ]; then
    find "$REPO_CONFIG/docs" -maxdepth 1 -name "*.md" -exec cp {} ~/.claude/docs/ \;
fi

# skills/ 덮어쓰기 (로컬 전용 스킬은 유지)
if [ -d "$REPO_CONFIG/skills" ]; then
    cp -r "$REPO_CONFIG/skills/"* ~/.claude/skills/
fi

# settings.json 덮어쓰기 (있으면)
[ -f "$REPO_CONFIG/settings.json" ] && cp "$REPO_CONFIG/settings.json" ~/.claude/settings.json
```

### 5단계: 정리 및 완료 보고

1. 임시 디렉토리 정리: `rm -rf "$TEMP_DIR"`
2. 가져온 파일 목록 요약
3. 덮어쓰여진 파일 목록

---

## 주의사항

- `docs/users/` 디렉토리는 절대 덮어쓰지 않는다 (로컬 전용)
- 가져오기 전 반드시 변경 사항을 사용자에게 보여주고 확인받는다
- 로컬에만 있는 스킬/파일은 삭제하지 않는다 (추가만 하고 제거 안 함)
- 덮어쓰기 방식이므로 로컬 수정 사항이 있으면 먼저 deploy로 백업 후 import 권장
