@echo off
chcp 65001 >nul 2>&1
title Claude Code 팀 환경 설치

echo.
echo  ========================================
echo   Claude Code 팀 환경 설치
echo  ========================================
echo.

:: git 확인
where git >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo  [!] git이 설치되어 있지 않습니다.
    echo      자동으로 설치합니다...
    echo.
    winget install --id Git.Git --accept-source-agreements --accept-package-agreements
    if %ERRORLEVEL% neq 0 (
        echo  [!] git 자동설치 실패.
        echo      https://git-scm.com/download/win 에서 직접 설치 후 다시 실행하세요.
        pause
        exit /b 1
    )
    echo.
    echo  [OK] git 설치 완료. 이 창을 닫고 다시 실행해주세요.
    pause
    exit /b 0
)

:: 임시 폴더
set "TMPDIR=%TEMP%\claude-team-%RANDOM%"
set "CLAUDE_HOME=%USERPROFILE%\.claude"
set "BACKUP=%CLAUDE_HOME%\backups\team-config-%DATE:~0,4%%DATE:~5,2%%DATE:~8,2%"

:: 다운로드
echo  [1/5] 최신 설정 다운로드 중...
git clone --depth 1 https://github.com/rian4u/JBWRC.git "%TMPDIR%" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo  [!] 다운로드 실패. 인터넷 연결을 확인하세요.
    pause
    exit /b 1
)

set "SRC=%TMPDIR%\config"

:: 백업
echo  [2/5] 기존 설정 백업 중...
if exist "%CLAUDE_HOME%\CLAUDE.md" (
    mkdir "%BACKUP%" >nul 2>&1
    if exist "%CLAUDE_HOME%\CLAUDE.md" copy /y "%CLAUDE_HOME%\CLAUDE.md" "%BACKUP%\" >nul 2>&1
    if exist "%CLAUDE_HOME%\settings.json" copy /y "%CLAUDE_HOME%\settings.json" "%BACKUP%\" >nul 2>&1
    if exist "%CLAUDE_HOME%\docs" xcopy /e /i /q /y "%CLAUDE_HOME%\docs" "%BACKUP%\docs" >nul 2>&1
    if exist "%CLAUDE_HOME%\skills" xcopy /e /i /q /y "%CLAUDE_HOME%\skills" "%BACKUP%\skills" >nul 2>&1
    echo         백업 위치: %BACKUP%
) else (
    echo         기존 설정 없음 (신규 설치)
)

:: 폴더 생성
mkdir "%CLAUDE_HOME%\docs\users" >nul 2>&1
mkdir "%CLAUDE_HOME%\skills" >nul 2>&1

:: 파일 복사
echo  [3/5] 설정 파일 복사 중...
copy /y "%SRC%\CLAUDE.md" "%CLAUDE_HOME%\CLAUDE.md" >nul
copy /y "%SRC%\docs\conventions.md" "%CLAUDE_HOME%\docs\conventions.md" >nul
copy /y "%SRC%\docs\engineering.md" "%CLAUDE_HOME%\docs\engineering.md" >nul

for /d %%S in ("%SRC%\skills\*") do (
    mkdir "%CLAUDE_HOME%\skills\%%~nxS" >nul 2>&1
    copy /y "%%S\SKILL.md" "%CLAUDE_HOME%\skills\%%~nxS\SKILL.md" >nul
)

:: settings.json 처리
echo  [4/5] 설정 병합 중...
if exist "%CLAUDE_HOME%\settings.json" (
    powershell -ExecutionPolicy Bypass -Command ^
        "$e = Get-Content '%CLAUDE_HOME%\settings.json' -Raw -Encoding UTF8 | ConvertFrom-Json;" ^
        "$t = Get-Content '%SRC%\settings.json' -Raw -Encoding UTF8 | ConvertFrom-Json;" ^
        "$e.enabledPlugins = $t.enabledPlugins;" ^
        "$e.extraKnownMarketplaces = $t.extraKnownMarketplaces;" ^
        "$e.autoUpdatesChannel = $t.autoUpdatesChannel;" ^
        "if (-not $e.permissions) { $e | Add-Member -NotePropertyName permissions -NotePropertyValue @{} -Force };" ^
        "if (-not $e.permissions.allow) { $e.permissions | Add-Member -NotePropertyName allow -NotePropertyValue @() -Force };" ^
        "if ($e.permissions.allow -notcontains 'WebSearch') { $e.permissions.allow += 'WebSearch' };" ^
        "$e | ConvertTo-Json -Depth 10 | Set-Content '%CLAUDE_HOME%\settings.json' -Encoding UTF8" >nul 2>&1
) else (
    copy /y "%SRC%\settings.json" "%CLAUDE_HOME%\settings.json" >nul
)

:: 정리
echo  [5/5] 임시 파일 정리 중...
rmdir /s /q "%TMPDIR%" >nul 2>&1

echo.
echo  ========================================
echo   설치 완료!
echo  ========================================
echo.
echo   복사된 항목:
echo     - CLAUDE.md        (글로벌 지침)
echo     - conventions.md   (문서 작성 지침)
echo     - engineering.md   (전산 원칙)
echo     - skills 9개       (팀 공유 스킬)
echo     - settings.json    (플러그인 설정)
echo.
echo   Claude Code를 재시작하면 적용됩니다.
echo.
pause
