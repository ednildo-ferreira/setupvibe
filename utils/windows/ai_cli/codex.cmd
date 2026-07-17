@echo off
setlocal

set "NPM_PREFIX="
for /f "delims=" %%I in ('npm.cmd config get prefix 2^>nul') do if not defined NPM_PREFIX set "NPM_PREFIX=%%I"

if not defined NPM_PREFIX (
    echo [ERROR] npm.cmd was not found or did not return its global prefix. 1>&2
    exit /b 1
)

set "CODEX_COMMAND=%NPM_PREFIX%\codex.cmd"
if not exist "%CODEX_COMMAND%" (
    echo [ERROR] Codex CLI was not found at "%CODEX_COMMAND%". 1>&2
    exit /b 1
)

call "%CODEX_COMMAND%" %*
exit /b %ERRORLEVEL%
