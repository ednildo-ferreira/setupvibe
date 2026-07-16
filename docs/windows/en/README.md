# SetupVibe Windows Edition (Beta)

> Native Windows development environment setup — v0.41.6

The Windows Edition (Beta) configures a complete native Windows development environment with WinGet as the primary package source and Chocolatey for packages not available through WinGet.

## Requirements

- Windows 10 version 1809 (build 17763) or later, or Windows 11
- A 64-bit Windows desktop edition; Windows Server is not supported
- Windows PowerShell 5.1 or later
- An administrator account
- Internet access

## What It Installs

- Asks whether to disable User Account Control (UAC), defaulting to `Yes`, and sets the machine-wide `EnableLUA` policy to `0` when accepted
- OpenSSH Client
- WinGet through the official `Microsoft.WinGet.Client` repair workflow when missing
- Chocolatey through its official bootstrap script when missing
- Git, 7-Zip, Wget, FFmpeg, ImageMagick, and GitHub CLI
- PHP 8.4, Composer, Laravel Installer, Ruby 3.3, Bundler, and Rails
- Python 3.12, uv, Spec-Kit, Go, Rustup, and Cargo
- Node.js LTS, Bun, PNPM, PM2, n8n, and the configured AI CLI tools
- bat, eza, zoxide, fzf, ripgrep, fd, lazygit, Neovim, Glow, tldr, Fastfetch, duf, jq, and mise
- Nmap, Speedtest CLI, Tailscale, gping, btop4win, trippy, and RustScan
- PowerShell 7, Windows Terminal, Starship, FiraCode Nerd Font, and JetBrains Mono Nerd Font

The installer is idempotent: installed WinGet packages are detected and skipped, while Chocolatey and ecosystem installers safely ensure their packages are present. Failures are recorded per package so remaining installations can continue. A transcript is saved under `C:\ProgramData\SetupVibe\Logs`.

Composer is installed from its official installer after SHA-384 signature verification. Starship and zoxide are initialized in both Windows PowerShell and PowerShell 7 profiles.

This script is exclusively for native Windows tools. Use `desktop.sh` inside WSL to configure the Linux environment.

Docker Desktop is intentionally excluded because its usual backends require WSL 2 or Hyper-V.

**Security warning:** Disabling UAC removes its security benefits for the entire computer. [Microsoft recommends keeping this policy enabled](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-10/security/threat-protection/security-policy-settings/user-account-control-run-all-administrators-in-admin-approval-mode). SetupVibe changes this setting only when you answer `Yes`; Windows must restart before it takes effect.

## One-Command Installation

This is the Windows equivalent of `curl -sSL desktop.setupvibe.dev | bash`.

For now, the Windows installer URLs target the `windows` development branch.

1. Open the Start menu.
2. Search for **Windows PowerShell** and open it. Starting it as administrator is optional because the script requests UAC elevation automatically.
3. Review the repository's [`desktop.ps1`](../../../desktop.ps1) before executing remote code.
4. Paste the following command and press `Enter`:

   ```powershell
   [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm https://raw.githubusercontent.com/promovaweb/setupvibe/windows/desktop.ps1 | iex
   ```

5. Accept the Windows UAC prompt.
6. Answer `Yes` or `No` when asked whether to disable UAC. Pressing `Enter` selects the default, `Yes`.
7. Keep the PowerShell windows open until the summary is displayed.
8. Restart Windows if requested so the UAC policy and any pending package changes take effect.

The command downloads `desktop.ps1` from the official SetupVibe repository and executes it in the current PowerShell session. When elevation is needed, the installer downloads a temporary copy and continues in an administrator session.

## Local Installation

To download the script before running it:

```powershell
$scriptPath = Join-Path $HOME 'Downloads\desktop.ps1'
Invoke-WebRequest -UseBasicParsing -Uri https://raw.githubusercontent.com/promovaweb/setupvibe/windows/desktop.ps1 -OutFile $scriptPath
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $scriptPath
```

From an existing clone of this repository:

```powershell
Set-Location C:\path\to\setupvibe
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\desktop.ps1
```

## What to Expect

During execution, the installer:

1. Validates the Windows edition, build, and 64-bit architecture.
2. Requests administrator privileges through UAC.
3. Asks whether to disable UAC, with `Yes` as the default, and sets the machine-wide `EnableLUA` registry policy to `0` when accepted.
4. Configures persistent user `PATH` entries.
5. Installs OpenSSH Client, WinGet, and Chocolatey when needed.
6. Installs each Windows package independently and continues after isolated package failures.
7. Installs the PHP, Ruby, Node.js, Python, and Rust ecosystem tools.
8. Configures Starship and zoxide for Windows PowerShell and PowerShell 7.
9. Displays a final summary and the transcript log location.

The process can take a while because Ruby, Rust, Rails, n8n, and AI CLI packages may download or compile additional dependencies.

## After Installation

1. Restart Windows when requested. If you chose to disable UAC, it remains active until this restart is complete.
2. Open Windows Terminal or PowerShell 7 so the refreshed `PATH`, Starship, and zoxide initialization are loaded.
3. Complete any first-run authentication required by GitHub CLI, Tailscale, Claude Code, Codex, or other external services.

Verify the main components in a new terminal:

```powershell
winget --version
choco --version
git --version
php --version
composer --version
ruby --version
python --version
node --version
rustc --version
pwsh --version
Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLUA
```

The final command must return `0` after the restart if you answered `Yes` to the UAC question. Answering `No` leaves the existing policy unchanged and does not re-enable UAC if it was already disabled.

## Rerunning and Logs

The installer is designed to be rerun. WinGet packages already present are skipped, while ecosystem installers ensure their tools remain installed.

Complete transcript logs are stored in:

```text
C:\ProgramData\SetupVibe\Logs
```

If one package fails, review the final summary and log, resolve the reported issue, and run the same command again.

## Options

Restart Windows automatically after a completely successful installation when Windows reports that a restart is required:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; & ([scriptblock]::Create((irm https://raw.githubusercontent.com/promovaweb/setupvibe/windows/desktop.ps1))) -Restart
```

Without `-Restart`, the installer never restarts Windows automatically.

## Re-enabling UAC

To restore the Windows default security behavior, run the following command from an administrator PowerShell session and restart Windows:

```powershell
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLUA -PropertyType DWord -Value 1 -Force
```

## Scope and Limitations

- Windows Server and 32-bit Windows are rejected during preflight checks.
- When accepted, disabling UAC is machine-wide and reduces Windows security. A domain or device-management policy can restore the setting after the script changes it.
- WSL is not installed or configured. Run `desktop.sh` inside an existing WSL distribution for the Linux environment.
- Docker Desktop and a local Docker engine are not installed.
