# AI CLI Launchers for Windows

> Compatibility launchers managed by the SetupVibe Windows Edition.

## Codex Launcher

`codex.cmd` allows the `codex` command to run from Windows PowerShell, PowerShell 7, Windows Terminal, and Command Prompt when persistent PowerShell script execution is restricted.

The official `@openai/codex` npm package creates both `codex.ps1` and `codex.cmd` shims. PowerShell can select the `.ps1` shim first and reject it under a restricted execution policy. SetupVibe places this CMD launcher in `%USERPROFILE%\.setupvibe\bin`, before the npm global prefix in the managed environment, and delegates to the package's full `codex.cmd` path.

The launcher:

1. Uses `npm.cmd config get prefix` to resolve the current global npm directory.
2. Checks that the official npm `codex.cmd` shim exists.
3. Forwards every argument and returns the original Codex CLI exit code.

It does not change PowerShell profiles or execution policies. The Windows `-Uninstall` mode removes the launcher with the other SetupVibe-managed utilities and removes the official `@openai/codex` package separately.
