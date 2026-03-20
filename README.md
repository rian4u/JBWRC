# JBWRC — Claude Code 팀 환경 설정

팀 전체가 동일한 Claude Code 환경(지침, 스킬, 플러그인)을 사용할 수 있도록 설정을 공유하는 레포입니다.

## 빠른 설치

### Windows (PowerShell)
```powershell
git clone https://github.com/rian4u/JBWRC.git %TEMP%\JBWRC && powershell -ExecutionPolicy Bypass -File %TEMP%\JBWRC\install.ps1
```

### Windows (Git Bash) / Mac / Linux
```bash
git clone https://github.com/rian4u/JBWRC.git /tmp/JBWRC && bash /tmp/JBWRC/install.sh
```

## 포함 내용

| 파일 | 설명 |
|------|------|
| `config/CLAUDE.md` | 글로벌 지침 (세션 시작 흐름, 운영 원칙) |
| `config/docs/conventions.md` | 문서 작성 지침 (기획서·설계서·진행상황 템플릿) |
| `config/docs/engineering.md` | 전산 원칙 (코드 스타일, 파일 구조, 설계 원칙) |
| `config/skills/` | 9개 공유 스킬 |
| `config/settings.json` | 플러그인 설정 (context7, playwright) |

### 공유 스킬 목록

| 스킬 | 설명 |
|------|------|
| auto-permissions | 프로젝트 권한 자동 설정 |
| docx | Word 문서 생성 |
| xlsx | Excel 스프레드시트 생성/파싱 |
| pdf | PDF 텍스트·테이블 추출 |
| notebooklm | Google NotebookLM 자동화 |
| project-planner | 바이브코딩 프로젝트 기획 |
| security-audit | 보안 취약점 스캔 |
| troubleshooting | 에러 해결 이력 관리 |
| vibesec | 웹 보안 코딩 가이드 |

## 개인별 파일 (공유 안 됨)

- `~/.claude/docs/users/*.md` — 사용자 프로필 (각자 생성)
- `~/.claude/.credentials.json` — 인증 정보
- `~/.claude/sessions/`, `~/.claude/history.jsonl` — 세션 이력

## 업데이트

설치 스크립트를 다시 실행하면 최신 버전으로 업데이트됩니다.
기존 설정은 `~/.claude/backups/team-config-*`에 자동 백업됩니다.

## 관리자

설정을 수정하려면 이 레포의 `config/` 폴더 내 파일을 편집하고 push하세요.
팀원은 설치 스크립트를 재실행하면 반영됩니다.
