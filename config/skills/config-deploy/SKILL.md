---
name: config-deploy
description: 글로벌 지침(CLAUDE.md), 문서 지침(docs/), 스킬(skills/)을 GitHub 리포(rian4u/JBWRC)에 배포한다. "배포", "deploy", "push", "깃헙에 올려" 등의 요청 시 실행한다.
---

# Config Deploy Skill

로컬 `~/.claude/`의 글로벌 지침·문서 지침·스킬을 GitHub 리포에 배포한다.

---

## 배포 대상

| 로컬 경로 | 리포 경로 | 비고 |
|---------|---------|------|
| `~/.claude/CLAUDE.md` | `config/CLAUDE.md` | 글로벌 운영 지침 |
| `~/.claude/docs/*.md` | `config/docs/*.md` | 문서 작성 지침 (users/ 제외) |
| `~/.claude/skills/*/` | `config/skills/*/` | 스킬 전체 |
| `~/.claude/settings.json` | `config/settings.json` | 설정 파일 (있는 경우만) |

**제외 대상:**
- `~/.claude/docs/users/` — 개인 프로필, 배포 대상 아님
- `~/.claude/projects/` — 프로젝트별 메모리, 배포 대상 아님
- `~/.claude/plans/` — 플랜 모드 임시 파일, 배포 대상 아님
- `~/.claude/memory/` — 자동 메모리, 배포 대상 아님

---

## 실행 절차

### 1단계: 사전 확인

1. `gh auth status`로 GitHub 인증 상태 확인
2. 인증 안 되어 있으면 `gh auth login` 안내 후 종료

### 2단계: 리포 클론 및 동기화

1. 임시 디렉토리에 리포를 shallow clone한다:
   ```bash
   TEMP_DIR=$(mktemp -d)
   git clone --depth 1 https://github.com/rian4u/JBWRC.git "$TEMP_DIR/JBWRC"
   ```

2. `config/` 폴더를 정리하고 로컬 파일을 복사한다:
   ```bash
   REPO_CONFIG="$TEMP_DIR/JBWRC/config"

   # CLAUDE.md 복사
   cp ~/.claude/CLAUDE.md "$REPO_CONFIG/CLAUDE.md"

   # docs/ 복사 (users/ 제외)
   rm -rf "$REPO_CONFIG/docs"
   mkdir -p "$REPO_CONFIG/docs"
   find ~/.claude/docs -maxdepth 1 -name "*.md" ! -path "*/users/*" -exec cp {} "$REPO_CONFIG/docs/" \;

   # skills/ 복사
   rm -rf "$REPO_CONFIG/skills"
   cp -r ~/.claude/skills "$REPO_CONFIG/skills"

   # settings.json 복사 (있으면)
   [ -f ~/.claude/settings.json ] && cp ~/.claude/settings.json "$REPO_CONFIG/settings.json"
   ```

### 3단계: 변경 확인 및 커밋

1. `git diff --stat`으로 변경 사항 확인
2. 변경 사항을 사용자에게 보여주고 `AskUserQuestion`으로 배포 확인
3. 승인 시:
   ```bash
   cd "$TEMP_DIR/JBWRC"
   git add config/
   git commit -m "chore: sync claude config $(date +%Y-%m-%d)"
   git push origin main
   ```
4. 임시 디렉토리 정리: `rm -rf "$TEMP_DIR"`

### 4단계: 완료 보고

- 배포된 파일 목록 요약
- 리포 URL 안내

---

## 주의사항

- `docs/users/` 디렉토리는 절대 배포하지 않는다 (개인 정보)
- 배포 전 반드시 변경 사항을 사용자에게 보여주고 확인받는다
- `git push --force`는 사용하지 않는다
