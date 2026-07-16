# SetupVibe Windows Edition (Beta)

> Native Windows utility setup — v0.41.6

The Windows Edition (Beta) configures a focused set of native Windows utilities with WinGet as the primary package source and Chocolatey for packages not available through WinGet.

## Requirements

- Windows 11 version 22H2 (build 22621) or later
- A 64-bit Windows desktop edition; Windows 10 and Windows Server are not supported
- Windows PowerShell 5.1 or later
- An administrator account
- Internet access

## What It Installs

- OpenSSH Client
- WinGet through the official `Microsoft.WinGet.Client` repair workflow when missing
- Chocolatey through its official bootstrap script when missing
- WSL base without a Linux distribution, with WSL 2 as the default
- Mirrored WSL networking with VPN/LAN access, DNS tunneling, Windows proxy integration, Hyper-V firewall inbound access, automatic memory reclaim, and sparse virtual disks
- Git, 7-Zip, Wget, FFmpeg, ImageMagick, and GitHub CLI
- bat, eza, zoxide, fzf, ripgrep, fd, lazygit, Neovim, Glow, tldr, Fastfetch, duf, and jq
- Nmap, Speedtest CLI, Tailscale, gping, btop4win, trippy, and RustScan
- PowerShell 7, Windows Terminal, Starship, FiraCode Nerd Font, and JetBrains Mono Nerd Font

The installer is idempotent: installed WinGet packages are detected and skipped, while Chocolatey safely ensures its packages are present. Failures are recorded per package so remaining installations can continue. A transcript is saved under `C:\ProgramData\SetupVibe\Logs`.

Starship and zoxide are initialized in both Windows PowerShell and PowerShell 7 profiles.

This script is exclusively for native Windows utilities and the WSL base system. It does not install a Linux distribution, programming languages, frameworks, runtime managers, or AI CLI tools. After installing a distribution separately, use `desktop.sh` inside it to configure a complete development environment.

If `%USERPROFILE%\.wslconfig` already exists, SetupVibe backs it up before applying the development defaults. The backup and the previous WSL feature and firewall states are restored by `-Uninstall`.

Docker Desktop is intentionally excluded. SetupVibe prepares WSL 2 but does not install Docker or a Linux distribution.

**WSL network warning:** SetupVibe allows inbound traffic to WSL on all ports through the Hyper-V firewall so future services can be reached through the local network and compatible VPNs. Restrict this policy with specific Hyper-V firewall rules on untrusted networks. A future Linux service must listen on `0.0.0.0` or the appropriate network interface to accept remote connections.

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
6. Keep the PowerShell windows open until the summary is displayed.
7. Restart Windows if requested so pending component or package changes take effect.

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

1. Validates Windows 11 22H2 or later and the 64-bit architecture.
2. Requests administrator privileges through UAC.
3. Stops with an alert if a competing servicing or installer operation is active, recommends restarting the PC, rejects pending restarts, starts required services, checks WSUS policy, and validates the Windows component store.
4. Installs OpenSSH Client when needed.
5. Copies SetupVibe Windows helper scripts to `%USERPROFILE%\.setupvibe\bin` and adds that directory to the user `PATH`.
6. Installs the WSL base without a Linux distribution and makes WSL 2 the default.
7. Applies mirrored networking, VPN/LAN access, DNS, proxy, firewall, memory reclaim, and sparse VHD settings to WSL.
8. Installs WinGet and Chocolatey when needed.
9. Installs each Windows utility independently and continues after isolated package failures.
10. Configures Starship and zoxide for Windows PowerShell and PowerShell 7.
11. Displays a final summary and the transcript log location.

The process can take a while because package managers download and install each utility independently.

## After Installation

1. Restart Windows when requested so pending component or package changes can finish.
2. Open Windows Terminal or PowerShell 7 so the refreshed `PATH`, Starship, and zoxide initialization are loaded.
3. Complete any first-run authentication required by GitHub CLI or Tailscale.

SetupVibe helper scripts are stored in `%USERPROFILE%\.setupvibe\bin`. The `ssh_copy_id.ps1` core and its minimal `ssh_copy_id.cmd` launcher can be started as `ssh_copy_id` from any new PowerShell, Windows Terminal, or Command Prompt session.

Verify the main components in a new terminal:

```powershell
winget --version
choco --version
git --version
rg --version
fzf --version
pwsh --version
Get-Command ssh_copy_id
wsl --status
wsl --list --verbose
Get-Content $HOME\.wslconfig
Get-NetFirewallHyperVVMSetting -PolicyStore ActiveStore -Name '{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}'
```

`wsl --list --verbose` should report that no distributions are installed unless the machine already had one. The firewall output should show `DefaultInboundAction` as `Allow`.

## Rerunning and Logs

The installer is designed to be rerun. SetupVibe helper scripts are refreshed, WinGet packages already present are skipped, and Chocolatey ensures its managed utilities remain installed.

Complete transcript and dedicated DISM logs are stored in:

```text
C:\ProgramData\SetupVibe\Logs
```

If one package fails, review the final summary and log, resolve the reported issue, and run the same command again.

## Windows Servicing Safety

Before installation or removal, SetupVibe checks for active `DISM`, `dismhost`, `TiWorker`, Windows Installer, Windows Update installers, WinGet, Chocolatey, and other known servicing processes. It also checks the Windows Installer registry transaction and global MSI execution mutex. It then rejects Component Based Servicing or Windows Update restarts that are still pending, starts `TrustedInstaller` and, during installation, starts `wuauserv` and `bits`, then runs `DISM /Online /Cleanup-Image /CheckHealth`.

SetupVibe never waits for or forcibly terminates a competing installer. If it detects one, it displays an alert with the process names and PIDs or active transaction, exits before making changes, and recommends restarting the PC before running SetupVibe again. This protects the component store from partial package or optional-feature operations.

On WSUS-managed computers, Features on Demand such as OpenSSH may still fail when the corporate update source does not provide optional content. The OpenSSH error points to its dedicated `dism-OpenSSH-Client-*.log` file.

## Options

Restart Windows automatically after a completely successful installation when Windows reports that a restart is required:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; & ([scriptblock]::Create((irm https://raw.githubusercontent.com/promovaweb/setupvibe/windows/desktop.ps1))) -Restart
```

Without `-Restart`, the installer never restarts Windows automatically.

### Uninstall

Remove all utilities and configurations managed by the Windows Edition from a local clone:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\desktop.ps1 -Uninstall
```

Or run the uninstaller from the `windows` branch:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; & ([scriptblock]::Create((irm https://raw.githubusercontent.com/promovaweb/setupvibe/windows/desktop.ps1))) -Uninstall
```

The uninstall mode removes OpenSSH Client, the SetupVibe-managed files from `%USERPROFILE%\.setupvibe\bin` and their user `PATH` entry, restores the previous WSL optional-feature and firewall states, removes the SetupVibe WSL configuration, removes every WinGet and Chocolatey utility managed by SetupVibe, and removes the Starship and zoxide profile block and generated Starship configuration. It also removes language runtimes, framework tools, runtime-manager paths, and npm packages installed by earlier Windows Beta versions. Existing Linux distributions are not deleted. WinGet, Chocolatey, transcript logs, and unrelated files under `%USERPROFILE%\.setupvibe` are preserved.

**Uninstall warning:** the current Beta does not track whether OpenSSH Client or a managed package existed before SetupVibe. `-Uninstall` therefore removes OpenSSH Client and every package in its managed lists, including components that may have been installed separately before SetupVibe.

Combine `-Uninstall` with `-Restart` to restart automatically when Windows reports that a restart is required.

## Scope and Limitations

- Windows 10, Windows Server, Windows 11 builds older than 22621, and 32-bit Windows are rejected during preflight checks.
- WSL is installed and configured for WSL 2, mirrored VPN/LAN networking, and common development optimizations, but no Linux distribution is installed.
- Programming languages, frameworks, runtime managers, and AI CLI tools are not installed.
- Docker Desktop and a local Docker engine are not installed.
