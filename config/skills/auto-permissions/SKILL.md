---
name: auto-permissions
description: 현재 프로젝트에 Claude Code 전체 권한을 자동으로 설정한다. "전체 권한", "모든 권한", "권한 다 줘", "auto approve", "자동 승인", "퍼미션 설정", "permissions 설정", "승인 없이 실행" 같은 말이 나오면 즉시 이 스킬을 사용해야 한다. 사용자가 명시적으로 요청하지 않아도 권한 관련 불편함을 언급하면 적극적으로 제안한다.
---
# Auto Permissions

현재 작업 디렉토리의 `.claude/settings.json`을 생성하거나 업데이트해서 프로젝트에 전체 권한을 설정한다.

## 실행 순서

### 1단계: 현재 상태 확인

```bash
# 프로젝트 루트 확인
pwd

# 기존 설정 파일 존재 여부 확인
ls -la .claude/settings.json 2>/dev/null && cat .claude/settings.json || echo "설정 파일 없음"
```

### 2단계: 모드 결정

사용자 요청 강도에 따라 두 가지 중 선택:

**A. 실용적 전권** (기본 추천 — "전체 권한", "모든 권한")

- 모든 파일 읽기/편집 허용
- 대부분의 bash 명령 허용
- `.env` 파일 읽기 및 `rm -rf`, `git push --force` 는 차단

**B. 완전 전권** (bypassPermissions — "묻지도 따지지도 말고", "완전히 다 줘")

- 모든 권한 체크 비활성화
- 가장 빠르지만 가장 위험
- 사용자에게 위험성 한 번 고지 후 진행

### 3단계: .claude 디렉토리 및 settings.json 생성

**A. 실용적 전권 설정:**

```bash
mkdir -p .claude
cat > .claude/settings.json << 'EOF'
{
  "permissions": {
    "allow": [
      "Read",
      "Edit",
      "MultiEdit",
      "Write",
      "Bash(*)"
    ],
    "deny": [
      "Read(.env*)",
      "Edit(.env*)",
      "Bash(rm -rf /*)",
      "Bash(git push --force*)",
      "Bash(sudo rm *)",
      "Bash(> /dev/sda*)"
    ]
  }
}
EOF
echo "✅ 실용적 전권 설정 완료"
```

**B. 완전 전권 설정:**

```bash
mkdir -p .claude
cat > .claude/settings.json << 'EOF'
{
  "permissions": {
    "defaultMode": "bypassPermissions"
  }
}
EOF
echo "✅ 완전 전권(bypassPermissions) 설정 완료"
```

### 4단계: 설정 확인 및 결과 보고

```bash
echo "=== 현재 권한 설정 ==="
cat .claude/settings.json
echo ""
echo "=== .claude 디렉토리 ==="
ls -la .claude/
```

### 5단계: 사용자에게 결과 보고

설정 완료 후 다음을 알려준다:

- 어떤 모드로 설정됐는지
- 차단된 명령어가 있다면 무엇인지 (실용적 전권의 경우)
- **Claude Code를 재시작하거나 새 세션을 시작해야 설정이 적용된다**는 것
- `.gitignore`에 `.claude/settings.json`을 추가할지 여부 (팀 프로젝트라면 공유, 개인 설정이라면 `.claude/settings.local.json` 사용 권장)

## 주의사항

- 기존 `.claude/settings.json`이 있으면 덮어쓰기 전에 백업 여부를 사용자에게 확인한다
- `bypassPermissions` 모드는 위험성을 한 줄로 고지한 뒤 진행한다: "⚠️ 모든 권한 체크가 비활성화됩니다. 개인 로컬 프로젝트에서만 사용하세요."
- 팀 프로젝트라면 개인 설정은 `.claude/settings.local.json`에 저장하고 `.gitignore`에 추가할 것을 권장한다
