@echo off
setlocal EnableExtensions

where pwsh.exe >nul 2>&1
if errorlevel 1 (
    set "SETUPVIBE_POWERSHELL=powershell.exe"
) else (
    set "SETUPVIBE_POWERSHELL=pwsh.exe"
)

"%SETUPVIBE_POWERSHELL%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0ssh_copy_id.ps1" %*
exit /b %ERRORLEVEL%
