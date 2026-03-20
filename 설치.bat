@echo off
chcp 65001 >nul 2>&1
title Claude Code 팀 환경 설치

echo.
echo  ========================================
echo   Claude Code 팀 환경 설치 중...
echo  ========================================
echo.

:: git 확인
where git >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo  [!] git이 설치되어 있지 않습니다.
    echo      먼저 git을 설치해주세요.
    echo      다운로드: https://git-scm.com/download/win
    echo.
    pause
    exit /b 1
)

:: 임시 폴더 준비
set "TMPDIR=%TEMP%\claude-team-install"
if exist "%TMPDIR%" rmdir /s /q "%TMPDIR%"

:: 레포 다운로드
echo  [1/4] 설정 파일 다운로드 중...
git clone --depth 1 https://github.com/rian4u/JBWRC.git "%TMPDIR%" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo  [!] 다운로드 실패. 인터넷 연결을 확인하세요.
    pause
    exit /b 1
)

:: PowerShell로 설치 스크립트 실행
echo  [2/4] 설치 스크립트 실행 중...
powershell -ExecutionPolicy Bypass -File "%TMPDIR%\install.ps1"

:: 정리
echo  [3/4] 임시 파일 정리 중...
rmdir /s /q "%TMPDIR%" >nul 2>&1

echo  [4/4] 완료!
echo.
echo  ========================================
echo   설치가 완료되었습니다!
echo   Claude Code를 재시작하면 적용됩니다.
echo  ========================================
echo.
pause
