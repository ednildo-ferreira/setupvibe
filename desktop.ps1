#Requires -Version 5.1

[CmdletBinding()]
param(
    [switch]$Restart,
    [switch]$Uninstall
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'Continue'

$script:Version = '0.41.6'
$script:InstallUrl = 'https://raw.githubusercontent.com/promovaweb/setupvibe/windows/desktop.ps1'
$script:RestartRequired = $false
$script:RestartBeforeRetryRequired = $false
$script:SystemFileCheckerCompleted = $false
$script:Failures = New-Object System.Collections.Generic.List[string]
$script:LogDirectory = Join-Path $env:ProgramData 'SetupVibe\Logs'
$script:TranscriptStarted = $false
$script:WinGetPath = $null
$script:ChocolateyPath = $null
$script:WslVmCreatorId = '{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}'
$script:WslFeatureStatePath = Join-Path $env:ProgramData 'SetupVibe\wsl-feature-state.json'
$script:WslFirewallStatePath = Join-Path $env:ProgramData 'SetupVibe\wsl-firewall-inbound.txt'
$script:RuntimePathStatePath = Join-Path $env:ProgramData 'SetupVibe\windows-runtime-paths.json'
$script:AiCliPathStatePath = Join-Path $env:ProgramData 'SetupVibe\windows-ai-cli-paths.json'
$script:SetupVibeUserDirectory = Join-Path $env:USERPROFILE '.setupvibe'
$script:WindowsUtilitiesDirectory = Join-Path $script:SetupVibeUserDirectory 'bin'
$script:WindowsUtilitiesStatePath = Join-Path $script:SetupVibeUserDirectory 'windows-utilities.json'

$script:WindowsUtilities = @(
    @{ Path = 'utils/windows/ssh_copy_id/ssh_copy_id.ps1'; Name = 'ssh_copy_id.ps1' }
    @{ Path = 'utils/windows/ssh_copy_id/ssh_copy_id.cmd'; Name = 'ssh_copy_id.cmd' }
    @{ Path = 'utils/windows/ai_cli/codex.cmd'; Name = 'codex.cmd' }
)
$script:LegacyWindowsUtilityFiles = @('ssh_copy_id.bat')

$script:WinGetPackages = @(
    @{ Id = 'Git.Git'; Name = 'Git' }
    @{ Id = '7zip.7zip'; Name = '7-Zip' }
    @{ Id = 'JernejSimoncic.Wget'; Name = 'Wget' }
    @{ Id = 'Gyan.FFmpeg'; Name = 'FFmpeg' }
    @{ Id = 'ImageMagick.ImageMagick'; Name = 'ImageMagick' }
    @{ Id = 'GitHub.cli'; Name = 'GitHub CLI (gh)' }
    @{ Id = 'sharkdp.bat'; Name = 'bat' }
    @{ Id = 'eza-community.eza'; Name = 'eza' }
    @{ Id = 'ajeetdsouza.zoxide'; Name = 'zoxide' }
    @{ Id = 'junegunn.fzf'; Name = 'fzf' }
    @{ Id = 'BurntSushi.ripgrep.MSVC'; Name = 'ripgrep' }
    @{ Id = 'sharkdp.fd'; Name = 'fd' }
    @{ Id = 'JesseDuffield.lazygit'; Name = 'lazygit' }
    @{ Id = 'Neovim.Neovim'; Name = 'Neovim' }
    @{ Id = 'charmbracelet.glow'; Name = 'Glow' }
    @{ Id = 'tldr-pages.tlrc'; Name = 'tldr' }
    @{ Id = 'Fastfetch-cli.Fastfetch'; Name = 'Fastfetch' }
    @{ Id = 'muesli.duf'; Name = 'duf' }
    @{ Id = 'jqlang.jq'; Name = 'jq' }
    @{ Id = 'Insecure.Nmap'; Name = 'Nmap' }
    @{ Id = 'Ookla.Speedtest.CLI'; Name = 'Speedtest CLI' }
    @{ Id = 'Tailscale.Tailscale'; Name = 'Tailscale' }
    @{ Id = 'orf.gping'; Name = 'gping' }
    @{ Id = 'aristocratos.btop4win'; Name = 'btop4win' }
    @{ Id = 'Microsoft.PowerShell'; Name = 'PowerShell 7' }
    @{ Id = 'Microsoft.WindowsTerminal'; Name = 'Windows Terminal' }
    @{ Id = 'DEVCOM.JetBrainsMonoNerdFont'; Name = 'JetBrains Mono Nerd Font' }
)

$script:ChocolateyPackages = @(
    @{ Id = 'trippy'; Name = 'trippy' }
    @{ Id = 'rustscan'; Name = 'RustScan' }
    @{ Id = 'firacodenf'; Name = 'FiraCode Nerd Font' }
)

$script:LegacyWinGetPackages = @(
    @{ Id = 'PHP.PHP.8.4'; Name = 'PHP 8.4' }
    @{ Id = 'RubyInstallerTeam.RubyWithDevKit.3.3'; Name = 'Ruby 3.3 with DevKit' }
    @{ Id = 'Python.Python.3.12'; Name = 'Python 3.12' }
    @{ Id = 'astral-sh.uv'; Name = 'uv' }
    @{ Id = 'GoLang.Go'; Name = 'Go' }
    @{ Id = 'Rustlang.Rustup'; Name = 'Rustup' }
    @{ Id = 'Starship.Starship'; Name = 'Starship' }
    @{ Id = 'Oven-sh.Bun'; Name = 'Bun' }
    @{ Id = 'jdx.mise'; Name = 'mise' }
)

$script:LegacyNpmPackages = @('pnpm', 'pm2', '@n8n/cli', 'agentlytics', '@githubnext/github-copilot-cli', 'npm')

function Write-Section {
    param([Parameter(Mandatory = $true)][string]$Message)

    Write-Host ''
    Write-Host ("==> {0}" -f $Message) -ForegroundColor Cyan
}

function Write-Success {
    param([Parameter(Mandatory = $true)][string]$Message)

    Write-Host ("[OK] {0}" -f $Message) -ForegroundColor Green
}

function Write-WarningMessage {
    param([Parameter(Mandatory = $true)][string]$Message)

    Write-Host ("[WARN] {0}" -f $Message) -ForegroundColor Yellow
}

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Request-Elevation {
    $scriptPath = $PSCommandPath
    $temporaryScript = $null

    if ([string]::IsNullOrWhiteSpace($scriptPath)) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        $temporaryScript = Join-Path ([IO.Path]::GetTempPath()) ("SetupVibe-desktop-{0}.ps1" -f $PID)
        $webClient = New-Object Net.WebClient
        try {
            $webClient.DownloadFile($script:InstallUrl, $temporaryScript)
        }
        finally {
            $webClient.Dispose()
        }
        $scriptPath = $temporaryScript
    }

    $powerShellArguments = @(
        '-NoLogo'
        '-NoProfile'
        '-ExecutionPolicy'
        'Bypass'
        '-File'
        ('"{0}"' -f $scriptPath)
    )

    if ($Restart) {
        $powerShellArguments += '-Restart'
    }
    if ($Uninstall) {
        $powerShellArguments += '-Uninstall'
    }

    Write-Host 'Administrator privileges are required. Opening the UAC prompt...' -ForegroundColor Yellow
    try {
        $process = Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $powerShellArguments -Wait -PassThru
        exit $process.ExitCode
    }
    finally {
        if ($temporaryScript) {
            Remove-Item -Path $temporaryScript -Force -ErrorAction SilentlyContinue
        }
    }
}

function Invoke-NativeCommand {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter()][string[]]$ArgumentList = @(),
        [Parameter()][int[]]$SuccessExitCode = @(0)
    )

    & $FilePath @ArgumentList
    $exitCode = $LASTEXITCODE
    if ($SuccessExitCode -notcontains $exitCode) {
        throw "Command '$FilePath $($ArgumentList -join ' ')' failed with exit code $exitCode."
    }
    if ($exitCode -in @(1641, 3010)) {
        $script:RestartRequired = $true
    }
}

function Invoke-SetupStep {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][scriptblock]$Action
    )

    Write-Section $Name
    Write-Host ("[RUN] {0} started at {1:HH:mm:ss}." -f $Name, (Get-Date)) -ForegroundColor Cyan
    $stopwatch = [Diagnostics.Stopwatch]::StartNew()
    try {
        & $Action
        $stopwatch.Stop()
        Write-Host ("[DONE] {0} finished in {1:N1}s." -f $Name, $stopwatch.Elapsed.TotalSeconds) -ForegroundColor DarkGray
    }
    catch {
        $stopwatch.Stop()
        $script:Failures.Add($Name)
        Write-Host ("[ERROR] {0} failed after {1:N1}s: {2}" -f $Name, $stopwatch.Elapsed.TotalSeconds, $_.Exception.Message) -ForegroundColor Red
    }
}

function Stop-SetupIfFailed {
    param([Parameter(Mandatory = $true)][string]$LogPath)

    if ($script:Failures.Count -eq 0) {
        return
    }

    Write-Section 'Summary'
    Write-Host ("Failed steps: {0}" -f ($script:Failures -join ', ')) -ForegroundColor Red
    Write-Host ("Review the log and run desktop.ps1 again: {0}" -f $LogPath)
    if ($script:RestartBeforeRetryRequired) {
        Write-WarningMessage 'Restart the PC before running SetupVibe again.'
    }
    elseif ($script:RestartRequired) {
        Write-WarningMessage 'Windows must be restarted before all changes can take effect.'
    }
    if ($script:TranscriptStarted) {
        Stop-Transcript | Out-Null
        $script:TranscriptStarted = $false
    }
    exit 1
}

function Get-ActiveWindowsInstallerProcesses {
    $installerProcessNames = @(
        'AppInstallerCLI'
        'choco'
        'dism'
        'dismhost'
        'msiexec'
        'poqexec'
        'setuphost'
        'TiWorker'
        'winget'
        'Windows10UpgraderApp'
        'Windows11InstallationAssistant'
        'WindowsUpdateBox'
        'wusa'
    )

    return @(Get-Process -Name $installerProcessNames -ErrorAction SilentlyContinue | Sort-Object ProcessName, Id)
}

function Resolve-ActiveWindowsInstallerOperations {
    $activeProcesses = @(Get-ActiveWindowsInstallerProcesses)
    if ($activeProcesses.Count -eq 0) {
        Write-Success 'No competing Windows servicing or package-installer operation is active.'
        return
    }

    $script:RestartBeforeRetryRequired = $true
    Write-Host ''
    Write-Host '[ALERT] Another Windows installation or servicing operation is in progress:' -ForegroundColor Red
    foreach ($process in $activeProcesses) {
        Write-Host ("  - {0} (PID {1})" -f $process.ProcessName, $process.Id) -ForegroundColor Red
    }

    $confirmation = [string](Read-Host '[CONFIRM] Terminate these installer processes? SetupVibe will try normally first and force remaining processes if needed. [y/N]')
    if ($confirmation.Trim().ToLowerInvariant() -notin @('y', 'yes', 's', 'sim')) {
        Write-Host '[ACTION] No process was terminated. Restart the PC, then run SetupVibe again.' -ForegroundColor Yellow
        [void](Read-Host '[PAUSE] Press ENTER to close SetupVibe')
        throw 'SetupVibe stopped because the user declined to terminate active installer processes.'
    }

    foreach ($process in $activeProcesses) {
        Write-Host ("[RUN] Stopping {0} (PID {1})..." -f $process.ProcessName, $process.Id)
        try {
            Stop-Process -Id $process.Id -ErrorAction Stop
        }
        catch {
            Write-WarningMessage ("Normal stop failed for {0} (PID {1})." -f $process.ProcessName, $process.Id)
        }

        Start-Sleep -Seconds 1
        if (Get-Process -Id $process.Id -ErrorAction SilentlyContinue) {
            Write-WarningMessage ("Forcing {0} (PID {1}) to stop." -f $process.ProcessName, $process.Id)
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        }
    }

    Write-Section 'System integrity verification after installer termination'
    Ensure-WindowsServiceReady -Name 'TrustedInstaller'
    Invoke-SystemFileChecker

    $remainingProcesses = @(Get-ActiveWindowsInstallerProcesses)
    if ($remainingProcesses.Count -gt 0) {
        Write-Host '[ALERT] Installer processes remain active after the termination attempts:' -ForegroundColor Red
        foreach ($process in $remainingProcesses) {
            Write-Host ("  - {0} (PID {1})" -f $process.ProcessName, $process.Id) -ForegroundColor Red
        }
        Write-Host '[ACTION] Restart the PC, then run SetupVibe again.' -ForegroundColor Yellow
        [void](Read-Host '[PAUSE] Press ENTER to close SetupVibe')
        throw 'SetupVibe stopped because installer processes remain active after normal and forced termination attempts.'
    }

    $script:RestartBeforeRetryRequired = $false
    Write-Success 'Competing installer processes were terminated and system integrity was verified.'
}

function Get-PendingWindowsRestartReasons {
    $reasons = New-Object System.Collections.Generic.List[string]
    $rebootKeys = @(
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'; Reason = 'Component Based Servicing' }
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'; Reason = 'Windows Update' }
    )

    foreach ($rebootKey in $rebootKeys) {
        if (Test-Path $rebootKey.Path) {
            $reasons.Add([string]$rebootKey.Reason)
        }
    }
    return @($reasons)
}

function Ensure-WindowsServiceReady {
    param([Parameter(Mandatory = $true)][string]$Name)

    $service = Get-Service -Name $Name -ErrorAction Stop
    if ($service.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Running) {
        Write-Host ("[RUN] Starting required Windows service: {0}" -f $Name)
        try {
            Start-Service -Name $Name -ErrorAction Stop
            $service.WaitForStatus([System.ServiceProcess.ServiceControllerStatus]::Running, [TimeSpan]::FromSeconds(30))
            $service.Refresh()
        }
        catch {
            throw "Required Windows service '$Name' could not be started. Its startup may be disabled by local or domain policy. $($_.Exception.Message)"
        }
    }

    if ($service.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Running) {
        throw "Required Windows service '$Name' did not reach the Running state."
    }
    Write-Success ("Required Windows service is ready: {0}" -f $Name)
}

function Invoke-SystemFileChecker {
    $sfcPath = Join-Path $env:SystemRoot 'System32\sfc.exe'
    Write-Host '[RUN] Running System File Checker before SetupVibe makes changes.'
    Write-WarningMessage 'sfc.exe /scannow can take several minutes. Keep this window open until verification reaches 100%.'
    Invoke-NativeCommand -FilePath $sfcPath -ArgumentList @('/scannow')
    $script:SystemFileCheckerCompleted = $true
    Write-Success 'System File Checker completed. Details are available in C:\Windows\Logs\CBS\CBS.log.'
}

function Invoke-WindowsInstallerPreflight {
    param([Parameter()][switch]$RequireWindowsUpdate)

    Resolve-ActiveWindowsInstallerOperations

    $restartReasons = @(Get-PendingWindowsRestartReasons)
    if ($restartReasons.Count -gt 0) {
        $script:RestartRequired = $true
        throw "Windows has a pending restart requested by: $($restartReasons -join ', '). Restart Windows before running SetupVibe so component and package operations begin from a consistent state."
    }

    Ensure-WindowsServiceReady -Name 'TrustedInstaller'
    if (-not $script:SystemFileCheckerCompleted) {
        Invoke-SystemFileChecker
    }
    if ($RequireWindowsUpdate) {
        Ensure-WindowsServiceReady -Name 'wuauserv'
        Ensure-WindowsServiceReady -Name 'bits'

        $useWsus = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Name 'UseWUServer' -ErrorAction SilentlyContinue
        $blockPublicWindowsUpdate = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name 'DoNotConnectToWindowsUpdateInternetLocations' -ErrorAction SilentlyContinue
        if ([int]$useWsus -eq 1 -or [int]$blockPublicWindowsUpdate -eq 1) {
            Write-WarningMessage 'Windows Update is controlled by WSUS or domain policy. Windows optional features may fail if the corporate update source does not provide the required content.'
        }
    }

    $dismPath = Join-Path $env:SystemRoot 'System32\dism.exe'
    $preflightLogPath = Join-Path $script:LogDirectory ("dism-preflight-{0:yyyyMMdd-HHmmss}.log" -f (Get-Date))
    Write-Host ("[RUN] Checking the Windows component store. DISM log: {0}" -f $preflightLogPath)
    Invoke-NativeCommand -FilePath $dismPath -ArgumentList @('/Online', '/Cleanup-Image', '/CheckHealth', "/LogPath:$preflightLogPath")
    Write-Success 'Windows servicing and installer prerequisites are ready.'
}

function Import-EnvironmentPath {
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $additionalPaths = @(
        (Join-Path $env:ProgramData 'chocolatey\bin')
    )

    $env:Path = (@($machinePath, $userPath) + $additionalPaths | Where-Object { $_ }) -join ';'
}

function Find-Executable {
    param([Parameter(Mandatory = $true)][string]$Name)

    Import-EnvironmentPath
    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $command) {
        throw "Required command '$Name' was not found after package installation. Open a new terminal and run desktop.ps1 again."
    }
    return $command.Source
}

function Install-OpenSsh {
    $temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ("SetupVibe-OpenSSH-{0}" -f $PID)
    $msiLogPath = Join-Path $script:LogDirectory ("openssh-client-msi-{0:yyyyMMdd-HHmmss}.log" -f (Get-Date))
    $msiRepairLogPath = Join-Path $script:LogDirectory ("openssh-client-repair-{0:yyyyMMdd-HHmmss}.log" -f (Get-Date))

    New-Item -Path $temporaryDirectory -ItemType Directory -Force | Out-Null
    try {
        Write-Host '[RUN] Resolving the latest official Microsoft Win32-OpenSSH x64 MSI...'
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        $githubHeaders = @{ 'User-Agent' = 'SetupVibe-Windows' }
        $latestReleasePage = Invoke-WebRequest -Uri 'https://github.com/PowerShell/Win32-OpenSSH/releases/latest' -Headers $githubHeaders -UseBasicParsing
        $tagMatch = [regex]::Match($latestReleasePage.Content, '/PowerShell/Win32-OpenSSH/releases/tag/([^"&<]+)')
        if (-not $tagMatch.Success) {
            throw 'The latest Win32-OpenSSH release tag could not be resolved from the official GitHub release page.'
        }

        $releaseTag = [Uri]::UnescapeDataString($tagMatch.Groups[1].Value)
        $expandedAssetsUrl = "https://github.com/PowerShell/Win32-OpenSSH/releases/expanded_assets/$releaseTag"
        $expandedAssetsPage = Invoke-WebRequest -Uri $expandedAssetsUrl -Headers $githubHeaders -UseBasicParsing
        $assetMatch = [regex]::Match($expandedAssetsPage.Content, '/PowerShell/Win32-OpenSSH/releases/download/[^"?]+/OpenSSH-Win64-v[^"?]+\.msi')
        if (-not $assetMatch.Success) {
            throw "The official Win32-OpenSSH release '$releaseTag' does not contain an x64 Win64 MSI."
        }

        $assetUrl = "https://github.com$($assetMatch.Value)"
        $assetName = [IO.Path]::GetFileName($assetMatch.Value)
        $msiPath = Join-Path $temporaryDirectory $assetName
        Write-Host ("[RUN] Downloading OpenSSH {0}: {1}" -f $releaseTag, $assetName)
        Invoke-WebRequest -Uri $assetUrl -Headers $githubHeaders -OutFile $msiPath -UseBasicParsing
        Assert-ValidAuthenticodeSignature -Path $msiPath -Name "Microsoft Win32-OpenSSH $releaseTag x64 MSI"

        Write-Host '[RUN] Installing the OpenSSH Client and Server components from the official Microsoft MSI...'
        $msiArguments = @(
            '/i'
            $msiPath
            'ADDLOCAL=Client,Server'
            'REINSTALLMODE=amus'
            '/qn'
            '/norestart'
            '/L*v'
            $msiLogPath
        )
        Invoke-NativeCommand -FilePath (Join-Path $env:SystemRoot 'System32\msiexec.exe') -ArgumentList $msiArguments -SuccessExitCode @(0, 1641, 3010)

        $installedProduct = @(Get-ItemProperty -Path @(
                    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
                    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
                ) -ErrorAction SilentlyContinue | Where-Object {
                $_.DisplayName -match '^OpenSSH' -and $_.PSChildName -match '^\{[0-9A-Fa-f-]+\}$'
            } | Select-Object -First 1)
        if ($installedProduct.Count -gt 0) {
            Write-Host '[RUN] Forcing repair of all installed OpenSSH Client and Server files...'
            Invoke-NativeCommand -FilePath (Join-Path $env:SystemRoot 'System32\msiexec.exe') -ArgumentList @('/fa', $installedProduct[0].PSChildName, '/qn', '/norestart', '/L*v', $msiRepairLogPath) -SuccessExitCode @(0, 1641, 3010)
        }
    }
    finally {
        Remove-Item -Path $temporaryDirectory -Recurse -Force -ErrorAction SilentlyContinue
    }

    $openSshDirectories = @(
        (Join-Path $env:ProgramFiles 'OpenSSH')
        (Join-Path $env:ProgramFiles 'OpenSSH-Win64')
    )
    $openSshDirectory = @($openSshDirectories | Where-Object { Test-Path (Join-Path $_ 'ssh.exe') } | Select-Object -First 1)
    if ($openSshDirectory.Count -eq 0) {
        throw "OpenSSH Client MSI completed, but ssh.exe was not found. Review $msiLogPath."
    }

    Add-PathEntry -Path $openSshDirectory[0] -Scope 'Machine' -Prepend
    New-Item -Path (Join-Path $env:USERPROFILE '.ssh') -ItemType Directory -Force | Out-Null
    Import-EnvironmentPath
    $sshVersion = & (Join-Path $openSshDirectory[0] 'ssh.exe') -V 2>&1

    $sshdService = Get-Service -Name 'sshd' -ErrorAction Stop
    Set-Service -Name 'sshd' -StartupType Automatic
    if ($sshdService.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Running) {
        Start-Service -Name 'sshd'
        $sshdService.WaitForStatus([System.ServiceProcess.ServiceControllerStatus]::Running, [TimeSpan]::FromSeconds(30))
        $sshdService.Refresh()
    }
    if ($sshdService.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Running) {
        throw 'OpenSSH Server was installed, but the sshd service did not reach the Running state.'
    }

    $firewallRule = Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue
    if ($firewallRule) {
        Set-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -Enabled True -Action Allow
    }
    else {
        New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
    }

    Write-Success ("OpenSSH Client installed: {0}" -f ($sshVersion -join ' '))
    Write-Success 'OpenSSH Server is running automatically and the inbound TCP/22 firewall rule is enabled.'
}

function Uninstall-OpenSsh {
    $uninstallRegistryPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    $openSshProducts = @(Get-ItemProperty -Path $uninstallRegistryPaths -ErrorAction SilentlyContinue | Where-Object {
            $_.DisplayName -match '^OpenSSH'
        })

    foreach ($product in $openSshProducts) {
        if ($product.PSChildName -match '^\{[0-9A-Fa-f-]+\}$') {
            Write-Host ("[RUN] Removing Microsoft OpenSSH MSI product: {0}" -f $product.DisplayName)
            Invoke-NativeCommand -FilePath (Join-Path $env:SystemRoot 'System32\msiexec.exe') -ArgumentList @('/x', $product.PSChildName, '/qn', '/norestart') -SuccessExitCode @(0, 1605, 1641, 3010)
        }
    }

    foreach ($openSshDirectory in @((Join-Path $env:ProgramFiles 'OpenSSH'), (Join-Path $env:ProgramFiles 'OpenSSH-Win64'))) {
        Remove-PathEntry -Path $openSshDirectory -Scope 'Machine'
    }
    Write-Success 'SetupVibe-managed Microsoft OpenSSH Client and Server MSI installation removed.'
}

function Install-WindowsSubsystemForLinux {
    $wslPath = Join-Path $env:SystemRoot 'System32\wsl.exe'
    $featureNames = @('Microsoft-Windows-Subsystem-Linux', 'VirtualMachinePlatform')
    $featureStates = @{}
    foreach ($featureName in $featureNames) {
        $featureStates[$featureName] = (Get-WindowsOptionalFeature -Online -FeatureName $featureName).State
    }
    if (-not (Test-Path $script:WslFeatureStatePath)) {
        $featureStates | ConvertTo-Json | Set-Content -Path $script:WslFeatureStatePath -Encoding ASCII
    }

    $hasPendingFeature = $featureStates.Values -contains 'EnablePending'
    $hasDisabledFeature = @($featureStates.Values | Where-Object { $_ -notin @('Enabled', 'EnablePending') }).Count -gt 0

    if ($hasDisabledFeature) {
        Invoke-NativeCommand -FilePath $wslPath -ArgumentList @('--install', '--no-distribution', '--web-download') -SuccessExitCode @(0, 3010)
        $script:RestartRequired = $true
        Write-Success 'WSL base installed without a Linux distribution. New distributions will use WSL 2 by default.'
        return
    }

    if ($hasPendingFeature) {
        $script:RestartRequired = $true
        Write-WarningMessage 'WSL features are waiting for a Windows restart. WSL 2 will be finalized after the restart.'
        return
    }

    Invoke-NativeCommand -FilePath $wslPath -ArgumentList @('--update', '--web-download')
    Invoke-NativeCommand -FilePath $wslPath -ArgumentList @('--set-default-version', '2')
    Write-Success 'WSL is up to date and WSL 2 is the default for future distributions.'
}

function Install-WslDevelopmentConfiguration {
    $configPath = Join-Path $env:USERPROFILE '.wslconfig'
    $backupPath = Join-Path $env:USERPROFILE '.wslconfig.setupvibe.bak'
    if ((Test-Path $configPath) -and -not (Test-Path $backupPath)) {
        Copy-Item -Path $configPath -Destination $backupPath -Force
    }

    $configContent = @(
        '# Managed by SetupVibe Windows'
        '[wsl2]'
        'networkingMode=mirrored'
        'dnsTunneling=true'
        'autoProxy=true'
        'firewall=true'
        'guiApplications=true'
        'nestedVirtualization=true'
        ''
        '[experimental]'
        'autoMemoryReclaim=gradual'
        'sparseVhd=true'
        'bestEffortDnsParsing=true'
        'hostAddressLoopback=true'
    )
    Set-Content -Path $configPath -Value $configContent -Encoding ASCII

    $firewallSetting = Get-NetFirewallHyperVVMSetting -Name $script:WslVmCreatorId -ErrorAction SilentlyContinue
    if (-not (Test-Path $script:WslFirewallStatePath)) {
        $previousInboundAction = if ($firewallSetting) { [string]$firewallSetting.DefaultInboundAction } else { 'NotConfigured' }
        Set-Content -Path $script:WslFirewallStatePath -Value $previousInboundAction -Encoding ASCII
    }
    if ($firewallSetting) {
        Set-NetFirewallHyperVVMSetting -Name $script:WslVmCreatorId -DefaultInboundAction Allow
    }
    else {
        New-NetFirewallHyperVVMSetting -Name $script:WslVmCreatorId -DefaultInboundAction Allow
    }

    Write-Success 'WSL mirrored networking, VPN/LAN access, DNS, proxy, firewall, memory reclaim, and sparse VHD settings configured.'
    Write-WarningMessage 'WSL inbound traffic is allowed for all ports. Restrict it with Hyper-V firewall rules if the machine is on an untrusted network.'
}

function Uninstall-WindowsSubsystemForLinux {
    $wslPath = Join-Path $env:SystemRoot 'System32\wsl.exe'
    if (Test-Path $wslPath) {
        & $wslPath --shutdown 2>$null
    }

    $configPath = Join-Path $env:USERPROFILE '.wslconfig'
    $backupPath = Join-Path $env:USERPROFILE '.wslconfig.setupvibe.bak'
    if (Test-Path $backupPath) {
        Move-Item -Path $backupPath -Destination $configPath -Force
    }
    elseif ((Test-Path $configPath) -and (Select-String -Path $configPath -SimpleMatch '# Managed by SetupVibe Windows' -Quiet)) {
        Remove-Item -Path $configPath -Force -ErrorAction SilentlyContinue
    }

    $firewallSetting = Get-NetFirewallHyperVVMSetting -Name $script:WslVmCreatorId -ErrorAction SilentlyContinue
    if ($firewallSetting -and (Test-Path $script:WslFirewallStatePath)) {
        $previousInboundAction = (Get-Content -Path $script:WslFirewallStatePath -Raw).Trim()
        if ($previousInboundAction -notin @('Allow', 'Block', 'NotConfigured')) {
            $previousInboundAction = 'NotConfigured'
        }
        Set-NetFirewallHyperVVMSetting -Name $script:WslVmCreatorId -DefaultInboundAction $previousInboundAction
    }
    Remove-Item -Path $script:WslFirewallStatePath -Force -ErrorAction SilentlyContinue

    if (Test-Path $script:WslFeatureStatePath) {
        $previousFeatureStates = Get-Content -Path $script:WslFeatureStatePath -Raw | ConvertFrom-Json
        foreach ($featureName in @('Microsoft-Windows-Subsystem-Linux', 'VirtualMachinePlatform')) {
            $previousState = $previousFeatureStates.PSObject.Properties[$featureName].Value
            $feature = Get-WindowsOptionalFeature -Online -FeatureName $featureName
            if ($previousState -notin @('Enabled', 'EnablePending') -and $feature.State -in @('Enabled', 'EnablePending')) {
                $result = Disable-WindowsOptionalFeature -Online -FeatureName $featureName -NoRestart
                if ($result.RestartNeeded) {
                    $script:RestartRequired = $true
                }
            }
            elseif ($feature.State -eq 'DisablePending') {
                $script:RestartRequired = $true
            }
        }
        Remove-Item -Path $script:WslFeatureStatePath -Force
    }

    Write-Success 'The previous WSL feature state and firewall policy were restored, and the SetupVibe WSL configuration was removed. Existing Linux distributions were not deleted.'
}

function Find-WinGet {
    $command = Get-Command 'winget.exe' -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $aliasPath = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\winget.exe'
    if (Test-Path $aliasPath) {
        return $aliasPath
    }

    return $null
}

function Install-WinGet {
    $wingetPath = Find-WinGet
    if (-not $wingetPath) {
        Write-Host 'WinGet was not found. Installing it with Microsoft.WinGet.Client...'
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

        if (-not (Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) {
            Install-PackageProvider -Name NuGet -Force -Scope AllUsers | Out-Null
        }

        Install-Module -Name Microsoft.WinGet.Client -Repository PSGallery -Scope AllUsers -Force -AllowClobber
        Import-Module Microsoft.WinGet.Client -Force
        Repair-WinGetPackageManager -AllUsers
        $wingetPath = Find-WinGet
    }

    if (-not $wingetPath) {
        throw 'WinGet installation completed, but winget.exe could not be found. Sign out and run the script again.'
    }

    Invoke-NativeCommand -FilePath $wingetPath -ArgumentList @('--version')
    $script:WinGetPath = $wingetPath
    Write-Success 'WinGet is installed and available.'
}

function Test-WinGetPackageInstalled {
    param([Parameter(Mandatory = $true)][string]$Id)

    $output = @(& $script:WinGetPath list --id $Id --exact --source winget --accept-source-agreements --disable-interactivity 2>$null)
    $exitCode = $LASTEXITCODE
    return $exitCode -eq 0 -and (($output -join "`n") -match [regex]::Escape($Id))
}

function Install-WinGetPackage {
    param(
        [Parameter(Mandatory = $true)][string]$Id,
        [Parameter(Mandatory = $true)][string]$Name
    )

    $commonArguments = @(
        '--id', $Id
        '--exact'
        '--source', 'winget'
        '--silent'
        '--accept-package-agreements'
        '--accept-source-agreements'
        '--disable-interactivity'
    )

    if (Test-WinGetPackageInstalled -Id $Id) {
        Write-Success ("{0} is already installed." -f $Name)
        return
    }

    Invoke-NativeCommand -FilePath $script:WinGetPath -ArgumentList (@('install') + $commonArguments) -SuccessExitCode @(0, 1641, 3010)
    Write-Success ("{0} installed." -f $Name)
}

function Uninstall-WinGetPackage {
    param(
        [Parameter(Mandatory = $true)][string]$Id,
        [Parameter(Mandatory = $true)][string]$Name
    )

    if (-not (Test-WinGetPackageInstalled -Id $Id)) {
        Write-Success ("{0} is already absent." -f $Name)
        return
    }

    $arguments = @(
        'uninstall'
        '--id', $Id
        '--exact'
        '--source', 'winget'
        '--silent'
        '--accept-source-agreements'
        '--disable-interactivity'
    )
    Invoke-NativeCommand -FilePath $script:WinGetPath -ArgumentList $arguments -SuccessExitCode @(0, 1641, 3010)
    Write-Success ("{0} removed." -f $Name)
}

function Test-GitHubCli {
    $ghPath = Find-Executable -Name 'gh.exe'
    Invoke-NativeCommand -FilePath $ghPath -ArgumentList @('--version')
    Write-Success 'GitHub CLI is available as gh in the Windows PATH.'
}

function Test-WindowsTerminal {
    Import-EnvironmentPath
    $terminalPackage = Get-AppxPackage -Name 'Microsoft.WindowsTerminal' -ErrorAction SilentlyContinue
    $terminalCommand = Get-Command 'wt.exe' -ErrorAction SilentlyContinue
    $terminalAliasPath = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\wt.exe'

    if (-not $terminalPackage) {
        throw 'The Microsoft.WindowsTerminal AppX package was not found after WinGet installation.'
    }
    if (-not $terminalCommand -and -not (Test-Path $terminalAliasPath -PathType Leaf)) {
        throw 'Windows Terminal is installed, but its wt.exe app execution alias is unavailable.'
    }
    Write-Success 'Windows Terminal is installed and available as wt without changing its default profile.'
}

function Find-Chocolatey {
    $chocoCommand = Get-Command 'choco.exe' -ErrorAction SilentlyContinue
    if ($chocoCommand) {
        return $chocoCommand.Source
    }

    $defaultChocoPath = Join-Path $env:ProgramData 'chocolatey\bin\choco.exe'
    if (Test-Path $defaultChocoPath) {
        return $defaultChocoPath
    }

    return $null
}

function Install-Chocolatey {
    $chocoPath = Find-Chocolatey

    if (-not $chocoPath) {
        Write-Host 'Chocolatey was not found. Running the official bootstrap script...'
        Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        $webClient = New-Object Net.WebClient
        $installerPath = Join-Path $env:TEMP 'SetupVibe-ChocolateyInstall.ps1'
        try {
            $webClient.DownloadFile('https://community.chocolatey.org/install.ps1', $installerPath)
            & $installerPath
        }
        finally {
            Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue
            $webClient.Dispose()
        }

        $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
        $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        $env:Path = "${machinePath};${userPath}"
        $chocoCommand = Get-Command 'choco.exe' -ErrorAction SilentlyContinue
        if ($chocoCommand) {
            $chocoPath = $chocoCommand.Source
        }
    }

    if (-not $chocoPath) {
        throw 'Chocolatey installation completed, but choco.exe could not be found.'
    }

    Invoke-NativeCommand -FilePath $chocoPath -ArgumentList @('--version')
    $script:ChocolateyPath = $chocoPath
    Write-Success 'Chocolatey is installed and available.'
}

function Install-ChocolateyPackage {
    param(
        [Parameter(Mandatory = $true)][string]$Id,
        [Parameter(Mandatory = $true)][string]$Name
    )

    Invoke-NativeCommand -FilePath $script:ChocolateyPath -ArgumentList @('install', $Id, '--yes', '--no-progress') -SuccessExitCode @(0, 1641, 3010)
    Write-Success ("{0} is installed." -f $Name)
}

function Uninstall-ChocolateyPackage {
    param(
        [Parameter(Mandatory = $true)][string]$Id,
        [Parameter(Mandatory = $true)][string]$Name
    )

    Invoke-NativeCommand -FilePath $script:ChocolateyPath -ArgumentList @('uninstall', $Id, '--yes', '--no-progress') -SuccessExitCode @(0, 1605, 1614, 1641, 3010)
    Write-Success ("{0} is removed." -f $Name)
}

function Get-UserPowerShellProfilePaths {
    $documentsDirectory = [Environment]::GetFolderPath('MyDocuments')
    return @(
        (Join-Path $documentsDirectory 'WindowsPowerShell\profile.ps1')
        (Join-Path $documentsDirectory 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1')
        (Join-Path $documentsDirectory 'PowerShell\profile.ps1')
        (Join-Path $documentsDirectory 'PowerShell\Microsoft.PowerShell_profile.ps1')
    )
}

function Invoke-WithUserPowerShellProfilesPreserved {
    param([Parameter(Mandatory = $true)][scriptblock]$Action)

    $profileStates = @{}
    foreach ($profilePath in Get-UserPowerShellProfilePaths) {
        $profileStates[$profilePath] = if (Test-Path $profilePath -PathType Leaf) {
            [Convert]::ToBase64String([IO.File]::ReadAllBytes($profilePath))
        }
        else {
            $null
        }
    }

    try {
        & $Action
    }
    finally {
        foreach ($profilePath in Get-UserPowerShellProfilePaths) {
            $profileContent = $profileStates[$profilePath]
            if ($null -eq $profileContent) {
                Remove-Item -Path $profilePath -Force -ErrorAction SilentlyContinue
                continue
            }

            $profileDirectory = Split-Path -Parent $profilePath
            New-Item -Path $profileDirectory -ItemType Directory -Force | Out-Null
            [IO.File]::WriteAllBytes($profilePath, [Convert]::FromBase64String($profileContent))
        }
    }
    Write-Success 'The original Windows PowerShell and PowerShell 7 profile files were preserved.'
}

function Uninstall-PowerShellProfile {
    $profilePaths = Get-UserPowerShellProfilePaths
    $profileMarker = '# SetupVibe shell initialization'
    $profileEndMarker = '# End SetupVibe shell initialization'

    foreach ($profilePath in $profilePaths) {
        if (-not (Test-Path $profilePath)) {
            continue
        }

        $lines = @(Get-Content -Path $profilePath)
        $updatedLines = New-Object System.Collections.Generic.List[string]
        for ($index = 0; $index -lt $lines.Count; $index++) {
            if ($lines[$index] -ne $profileMarker) {
                $updatedLines.Add($lines[$index])
                continue
            }

            $endIndex = -1
            for ($candidateIndex = $index + 1; $candidateIndex -lt $lines.Count; $candidateIndex++) {
                if ($lines[$candidateIndex] -eq $profileEndMarker) {
                    $endIndex = $candidateIndex
                    break
                }
            }
            if ($endIndex -ge 0) {
                $index = $endIndex
            }
            else {
                $index = [Math]::Min($index + 2, $lines.Count - 1)
            }
        }

        if ($updatedLines.Count -eq 0 -or -not ($updatedLines | Where-Object { $_.Trim() })) {
            Remove-Item -Path $profilePath -Force
        }
        else {
            Set-Content -Path $profilePath -Value $updatedLines -Encoding UTF8
        }
    }

    $starshipConfig = Join-Path $env:USERPROFILE '.config\starship.toml'
    Remove-Item -Path $starshipConfig -Force -ErrorAction SilentlyContinue
    Write-Success 'SetupVibe shell initialization and Starship configuration removed.'
}

function Uninstall-LegacyEcosystemTools {
    Import-EnvironmentPath
    $cleanupCommands = @(
        @{ Name = 'npm ecosystem packages'; Command = 'npm.cmd'; Arguments = @('uninstall', '--global') + $script:LegacyNpmPackages }
        @{ Name = 'Laravel Installer'; Command = 'composer'; Arguments = @('global', 'remove', 'laravel/installer', '--no-interaction') }
        @{ Name = 'Bundler and Rails'; Command = 'gem'; Arguments = @('uninstall', 'bundler', 'rails', '--all', '--executables', '--ignore-dependencies') }
        @{ Name = 'Spec-Kit'; Command = 'uv.exe'; Arguments = @('tool', 'uninstall', 'specify-cli') }
    )

    foreach ($cleanup in $cleanupCommands) {
        $command = Get-Command $cleanup.Command -ErrorAction SilentlyContinue
        if (-not $command) {
            continue
        }
        try {
            Invoke-NativeCommand -FilePath $command.Source -ArgumentList $cleanup.Arguments
            Write-Success ("Legacy {0} removed." -f $cleanup.Name)
        }
        catch {
            Write-WarningMessage ("Could not remove legacy {0}: {1}" -f $cleanup.Name, $_.Exception.Message)
        }
    }
}

function Remove-PathEntry {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][ValidateSet('User', 'Machine')][string]$Scope
    )

    $currentPath = [Environment]::GetEnvironmentVariable('Path', $Scope)
    $normalizedPath = $Path.TrimEnd('\')
    $remainingEntries = @($currentPath -split ';' | Where-Object {
        $_ -and ([Environment]::ExpandEnvironmentVariables($_)).TrimEnd('\') -ne $normalizedPath
    })
    [Environment]::SetEnvironmentVariable('Path', ($remainingEntries -join ';'), $Scope)
}

function Add-PathEntry {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][ValidateSet('User', 'Machine')][string]$Scope,
        [Parameter()][switch]$Prepend
    )

    $currentPath = [Environment]::GetEnvironmentVariable('Path', $Scope)
    $normalizedPath = $Path.TrimEnd('\')
    $existingEntries = @($currentPath -split ';' | Where-Object { $_ })
    $pathExists = @($existingEntries | Where-Object {
            ([Environment]::ExpandEnvironmentVariables($_)).TrimEnd('\') -eq $normalizedPath
        }).Count -gt 0
    if ($pathExists -and -not $Prepend) {
        return
    }

    $remainingEntries = @($existingEntries | Where-Object {
            ([Environment]::ExpandEnvironmentVariables($_)).TrimEnd('\') -ne $normalizedPath
        })
    $updatedPath = if ($Prepend) { @($Path) + $remainingEntries } else { $remainingEntries + $Path }
    [Environment]::SetEnvironmentVariable('Path', ($updatedPath -join ';'), $Scope)
}

function Test-PathEntry {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][ValidateSet('User', 'Machine')][string]$Scope
    )

    $normalizedPath = $Path.TrimEnd('\')
    $currentPath = [Environment]::GetEnvironmentVariable('Path', $Scope)
    return @($currentPath -split ';' | Where-Object {
            $_ -and ([Environment]::ExpandEnvironmentVariables($_)).TrimEnd('\') -eq $normalizedPath
        }).Count -gt 0
}

function Register-AiCliPath {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][bool]$WasPresent
    )

    $pathsAdded = @()
    if (Test-Path $script:AiCliPathStatePath -PathType Leaf) {
        try {
            $state = Get-Content -Path $script:AiCliPathStatePath -Raw | ConvertFrom-Json
            if ($state.PSObject.Properties['PathsAdded']) {
                $pathsAdded = @($state.PathsAdded)
            }
        }
        catch {
            Write-WarningMessage ("Could not read the AI CLI PATH state: {0}" -f $_.Exception.Message)
        }
    }

    if (-not $WasPresent -and $pathsAdded -notcontains $Path) {
        $pathsAdded += $Path
    }
    @{ PathsAdded = @($pathsAdded) } | ConvertTo-Json | Set-Content -Path $script:AiCliPathStatePath -Encoding ASCII
}

function Uninstall-AiCliPaths {
    if (Test-Path $script:AiCliPathStatePath -PathType Leaf) {
        try {
            $state = Get-Content -Path $script:AiCliPathStatePath -Raw | ConvertFrom-Json
            foreach ($path in @($state.PathsAdded)) {
                if (-not [string]::IsNullOrWhiteSpace([string]$path)) {
                    Remove-PathEntry -Path ([string]$path) -Scope 'User'
                }
            }
        }
        catch {
            Write-WarningMessage ("Could not restore the AI CLI PATH state: {0}" -f $_.Exception.Message)
        }
    }
    Remove-Item -Path $script:AiCliPathStatePath -Force -ErrorAction SilentlyContinue
    Import-EnvironmentPath
    Write-Success 'SetupVibe-managed AI CLI user PATH entries were removed.'
}

function Assert-ValidAuthenticodeSignature {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Name
    )

    $signature = Get-AuthenticodeSignature -FilePath $Path
    if ($signature.Status -ne [System.Management.Automation.SignatureStatus]::Valid) {
        throw "$Name does not have a valid Authenticode signature. Status: $($signature.Status)."
    }
    Write-Success ("Valid Authenticode signature: {0}" -f $Name)
}

function Install-Python {
    $pythonArchitecture = 'amd64'
    $pythonDirectory = Join-Path $env:ProgramFiles 'Python314'
    $temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ("SetupVibe-Python-{0}" -f $PID)
    $installerLogPath = Join-Path $script:LogDirectory ("python-installer-{0:yyyyMMdd-HHmmss}.log" -f (Get-Date))

    New-Item -Path $temporaryDirectory -ItemType Directory -Force | Out-Null
    try {
        Write-Host '[RUN] Finding the latest official Python 3.14 standalone installer...'
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        $pythonIndex = Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/' -UseBasicParsing
        $versions = @([regex]::Matches($pythonIndex.Content, 'href="(3\.14\.\d+)/"') | ForEach-Object {
                [version]$_.Groups[1].Value
            } | Sort-Object -Descending -Unique)
        if ($versions.Count -eq 0) {
            throw 'Python.org did not return an official Python 3.14 release.'
        }

        $pythonVersion = $versions[0].ToString()
        $installerName = "python-$pythonVersion-$pythonArchitecture.exe"
        $installerUrl = "https://www.python.org/ftp/python/$pythonVersion/$installerName"
        $installerPath = Join-Path $temporaryDirectory $installerName
        Write-Host ("[RUN] Downloading Python {0} from python.org..." -f $pythonVersion)
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
        Assert-ValidAuthenticodeSignature -Path $installerPath -Name "Python $pythonVersion installer"

        Write-Host '[RUN] Installing Python for all users with pip and the Python launcher...'
        Invoke-NativeCommand -FilePath $installerPath -ArgumentList @(
            '/quiet'
            'InstallAllUsers=1'
            "TargetDir=$pythonDirectory"
            'PrependPath=0'
            'Include_pip=1'
            'Include_launcher=1'
            'InstallLauncherAllUsers=1'
            'Include_test=0'
            '/log'
            $installerLogPath
        ) -SuccessExitCode @(0, 1641, 3010)
        Write-Success ("Python {0} installed from the official python.org installer." -f $pythonVersion)
    }
    finally {
        Remove-Item -Path $temporaryDirectory -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Get-NodeJsMsiProducts {
    return @(Get-ItemProperty -Path @(
                'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
                'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
            ) -ErrorAction SilentlyContinue | Where-Object {
            $_.DisplayName -match '^Node\.js'
        })
}

function Uninstall-NodeJs {
    $products = @(Get-NodeJsMsiProducts)
    if ($products.Count -eq 0) {
        Write-Success 'Node.js is already absent.'
        return
    }

    foreach ($product in $products) {
        if ($product.PSChildName -notmatch '^\{[0-9A-Fa-f-]+\}$') {
            continue
        }
        Write-Host ("[RUN] Removing Node.js MSI product: {0}" -f $product.DisplayName)
        Invoke-NativeCommand -FilePath (Join-Path $env:SystemRoot 'System32\msiexec.exe') -ArgumentList @('/x', $product.PSChildName, '/qn', '/norestart') -SuccessExitCode @(0, 1605, 1641, 3010)
    }
    Write-Success 'Node.js MSI installation removed.'
}

function Install-NodeJs {
    $temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ("SetupVibe-NodeJS-{0}" -f $PID)
    $installerLogPath = Join-Path $script:LogDirectory ("nodejs-installer-{0:yyyyMMdd-HHmmss}.log" -f (Get-Date))
    $releaseUrl = 'https://nodejs.org/dist/latest-v24.x'
    $curlPath = Join-Path $env:SystemRoot 'System32\curl.exe'

    New-Item -Path $temporaryDirectory -ItemType Directory -Force | Out-Null
    try {
        if (-not (Test-Path $curlPath -PathType Leaf)) {
            throw "The Windows curl.exe executable was not found at $curlPath."
        }

        Write-Host '[RUN] Resolving Node.js 24 LTS from the official latest-v24.x channel...'
        $checksumsPath = Join-Path $temporaryDirectory 'SHASUMS256.txt'
        Invoke-NativeCommand -FilePath $curlPath -ArgumentList @(
            '--fail'
            '--location'
            '--retry', '3'
            '--connect-timeout', '30'
            '--proto', '=https'
            '--tlsv1.2'
            '--user-agent', ("SetupVibe-Windows/{0}" -f $script:Version)
            '--output', $checksumsPath
            "$releaseUrl/SHASUMS256.txt"
        )
        if (-not (Test-Path $checksumsPath -PathType Leaf) -or (Get-Item $checksumsPath).Length -eq 0) {
            throw 'The official Node.js SHASUMS256.txt file was empty or missing.'
        }

        $checksumMatch = @(Get-Content -Path $checksumsPath | Where-Object {
                $_ -match '^([0-9a-fA-F]{64})\s{2}(node-(v24\.\d+\.\d+)-x64\.msi)$'
            } | Select-Object -First 1)
        if ($checksumMatch.Count -eq 0 -or $checksumMatch[0] -notmatch '^([0-9a-fA-F]{64})\s{2}(node-(v24\.\d+\.\d+)-x64\.msi)$') {
            throw 'The official Node.js 24 LTS checksum file does not contain an x64 MSI.'
        }

        $expectedChecksum = $matches[1]
        $installerName = $matches[2]
        $nodeVersion = $matches[3]
        $installerPath = Join-Path $temporaryDirectory $installerName
        Write-Host ("[RUN] Downloading Node.js {0} LTS from nodejs.org..." -f $nodeVersion)
        Invoke-NativeCommand -FilePath $curlPath -ArgumentList @(
            '--fail'
            '--location'
            '--retry', '3'
            '--connect-timeout', '30'
            '--proto', '=https'
            '--tlsv1.2'
            '--user-agent', ("SetupVibe-Windows/{0}" -f $script:Version)
            '--output', $installerPath
            "$releaseUrl/$installerName"
        )
        if (-not (Test-Path $installerPath -PathType Leaf) -or (Get-Item $installerPath).Length -eq 0) {
            throw "The official Node.js MSI was empty or missing: $installerName"
        }

        $actualChecksum = (Get-FileHash -Path $installerPath -Algorithm SHA256).Hash
        if ($actualChecksum -ne $expectedChecksum) {
            throw "Node.js MSI SHA-256 mismatch. Expected $expectedChecksum, received $actualChecksum."
        }
        Write-Success 'Node.js MSI matches the official SHASUMS256.txt checksum.'
        Assert-ValidAuthenticodeSignature -Path $installerPath -Name "Node.js $nodeVersion MSI"

        Write-Host '[RUN] Installing the official Node.js LTS MSI...'
        Invoke-NativeCommand -FilePath (Join-Path $env:SystemRoot 'System32\msiexec.exe') -ArgumentList @('/i', $installerPath, 'REINSTALLMODE=amus', '/qn', '/norestart', '/L*v', $installerLogPath) -SuccessExitCode @(0, 1638, 1641, 3010)
        if ($LASTEXITCODE -eq 1638) {
            Write-WarningMessage 'Another Node.js MSI version is installed. Removing it before the forced LTS installation.'
            Uninstall-NodeJs
            Invoke-NativeCommand -FilePath (Join-Path $env:SystemRoot 'System32\msiexec.exe') -ArgumentList @('/i', $installerPath, '/qn', '/norestart', '/L*v', $installerLogPath) -SuccessExitCode @(0, 1641, 3010)
        }
        Write-Success ("Node.js {0} installed from the official nodejs.org MSI." -f $nodeVersion)
    }
    finally {
        Remove-Item -Path $temporaryDirectory -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Uninstall-Python {
    $products = @(Get-ItemProperty -Path @(
                'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
                'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
                'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
            ) -ErrorAction SilentlyContinue | Where-Object {
            $_.DisplayName -match '^Python 3\.14\.\d+ \(64-bit\)$'
        })
    if ($products.Count -eq 0) {
        Write-Success 'Python 3.14 is already absent.'
        return
    }

    foreach ($product in $products) {
        $quietUninstallProperty = $product.PSObject.Properties['QuietUninstallString']
        $uninstallProperty = $product.PSObject.Properties['UninstallString']
        $commandLine = if ($quietUninstallProperty) { [string]$quietUninstallProperty.Value } elseif ($uninstallProperty) { [string]$uninstallProperty.Value } else { $null }
        if ([string]::IsNullOrWhiteSpace($commandLine)) {
            Write-WarningMessage ("Python uninstaller command was not found for {0}." -f $product.DisplayName)
            continue
        }
        if ($commandLine -notmatch '^\s*"([^"]+)"\s*(.*)$') {
            throw "Python uninstaller command has an unsupported format: $commandLine"
        }

        $uninstallerPath = $matches[1]
        $uninstallerArguments = $matches[2]
        if ($uninstallerArguments -notmatch '(?i)/quiet') {
            $uninstallerArguments = "$uninstallerArguments /quiet"
        }
        Write-Host ("[RUN] Removing {0}..." -f $product.DisplayName)
        $process = Start-Process -FilePath $uninstallerPath -ArgumentList $uninstallerArguments -Wait -PassThru
        if ($process.ExitCode -notin @(0, 1641, 3010)) {
            throw "Python uninstaller failed with exit code $($process.ExitCode)."
        }
        if ($process.ExitCode -in @(1641, 3010)) {
            $script:RestartRequired = $true
        }
    }
    Write-Success 'Python 3.14 installation removed.'
}

function Find-RuntimeExecutable {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter()][string[]]$PreferredPaths = @()
    )

    $commandPaths = @(Get-Command $Name -All -ErrorAction SilentlyContinue | ForEach-Object { $_.Source })
    $candidates = @($PreferredPaths) + $commandPaths
    foreach ($candidate in $candidates) {
        if ([string]::IsNullOrWhiteSpace($candidate)) {
            continue
        }
        if ($candidate -like '*\Microsoft\WindowsApps\*') {
            continue
        }
        if (Test-Path $candidate -PathType Leaf) {
            return (Resolve-Path $candidate).Path
        }
    }

    throw "Required runtime executable '$Name' was not found after package installation."
}

function Install-DevelopmentRuntimePaths {
    Import-EnvironmentPath

    $pythonPath = Find-RuntimeExecutable -Name 'python.exe' -PreferredPaths @(
        (Join-Path $env:ProgramFiles 'Python314\python.exe')
        (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python314\python.exe')
    )
    $nodePath = Find-RuntimeExecutable -Name 'node.exe' -PreferredPaths @(
        (Join-Path $env:ProgramFiles 'nodejs\node.exe')
    )

    $pythonDirectory = Split-Path -Parent $pythonPath
    $pythonScriptsDirectory = Join-Path $pythonDirectory 'Scripts'
    $nodeDirectory = Split-Path -Parent $nodePath
    $pipPath = Join-Path $pythonScriptsDirectory 'pip.exe'
    $npmPath = Join-Path $nodeDirectory 'npm.cmd'
    $npxPath = Join-Path $nodeDirectory 'npx.cmd'

    foreach ($requiredFile in @($pipPath, $npmPath, $npxPath)) {
        if (-not (Test-Path $requiredFile -PathType Leaf)) {
            throw "Required runtime command was not found: $requiredFile"
        }
    }

    $runtimePaths = @($pythonDirectory, $pythonScriptsDirectory, $nodeDirectory)
    foreach ($runtimePath in $runtimePaths) {
        Remove-PathEntry -Path $runtimePath -Scope 'User'
        Add-PathEntry -Path $runtimePath -Scope 'Machine' -Prepend
    }
    @{ Paths = $runtimePaths } | ConvertTo-Json | Set-Content -Path $script:RuntimePathStatePath -Encoding ASCII
    Import-EnvironmentPath

    Invoke-NativeCommand -FilePath $pythonPath -ArgumentList @('--version')
    Invoke-NativeCommand -FilePath $pipPath -ArgumentList @('--version')
    Invoke-NativeCommand -FilePath $nodePath -ArgumentList @('--version')
    Invoke-NativeCommand -FilePath $npmPath -ArgumentList @('--version')
    Invoke-NativeCommand -FilePath $npxPath -ArgumentList @('--version')
    Write-Success 'Python, pip, Node.js, npm, and npx are available in the machine PATH for Claude and Codex.'
}

function Uninstall-DevelopmentRuntimePaths {
    $runtimePaths = @(
        (Join-Path $env:ProgramFiles 'Python314')
        (Join-Path $env:ProgramFiles 'Python314\Scripts')
        (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python314')
        (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python314\Scripts')
        (Join-Path $env:ProgramFiles 'nodejs')
    )
    if (Test-Path $script:RuntimePathStatePath -PathType Leaf) {
        try {
            $state = Get-Content -Path $script:RuntimePathStatePath -Raw | ConvertFrom-Json
            $runtimePaths += @($state.Paths)
        }
        catch {
            Write-WarningMessage ("Could not read the runtime PATH state; removing known paths: {0}" -f $_.Exception.Message)
        }
    }

    foreach ($runtimePath in @($runtimePaths | Where-Object { $_ } | Select-Object -Unique)) {
        Remove-PathEntry -Path ([string]$runtimePath) -Scope 'Machine'
    }
    Remove-Item -Path $script:RuntimePathStatePath -Force -ErrorAction SilentlyContinue
    Import-EnvironmentPath
    Write-Success 'SetupVibe-managed Python and Node.js machine PATH entries were removed.'
}

function Invoke-OfficialPowerShellInstaller {
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter()][string[]]$ScriptArguments = @()
    )

    $installerUri = [Uri]$Uri
    if ($installerUri.Scheme -ne 'https' -or $installerUri.Host -notin @('claude.ai', 'antigravity.google')) {
        throw "Unsupported official installer URL for ${Name}: $Uri"
    }

    $installerPath = Join-Path ([IO.Path]::GetTempPath()) ("SetupVibe-{0}-{1}.ps1" -f ($Name -replace '[^A-Za-z0-9]', ''), ([Guid]::NewGuid().ToString('N')))
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        Write-Host ("[RUN] Downloading the official {0} installer from {1}..." -f $Name, $installerUri.Host)
        Invoke-WebRequest -Uri $installerUri.AbsoluteUri -OutFile $installerPath -UseBasicParsing
        if (-not (Test-Path $installerPath -PathType Leaf) -or (Get-Item $installerPath).Length -eq 0) {
            throw "The official $Name installer was empty or missing."
        }

        $windowsPowerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $arguments = @('-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', $installerPath) + $ScriptArguments
        Invoke-NativeCommand -FilePath $windowsPowerShell -ArgumentList $arguments
    }
    finally {
        Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue
    }
}

function Get-NpmCommandPath {
    return Find-RuntimeExecutable -Name 'npm.cmd' -PreferredPaths @(
        (Join-Path $env:ProgramFiles 'nodejs\npm.cmd')
    )
}

function Install-ClaudeCode {
    $npmPath = Get-NpmCommandPath
    try {
        Invoke-NativeCommand -FilePath $npmPath -ArgumentList @('uninstall', '--global', '@anthropic-ai/claude-code')
    }
    catch {
        Write-WarningMessage ("Could not remove a legacy npm Claude Code installation: {0}" -f $_.Exception.Message)
    }

    $claudeDirectory = Join-Path $env:USERPROFILE '.local\bin'
    $pathWasPresent = Test-PathEntry -Path $claudeDirectory -Scope 'User'
    Invoke-WithUserPowerShellProfilesPreserved -Action {
        Invoke-OfficialPowerShellInstaller -Uri 'https://claude.ai/install.ps1' -Name 'Claude Code' -ScriptArguments @('latest')
    }
    Add-PathEntry -Path $claudeDirectory -Scope 'User'
    Register-AiCliPath -Path $claudeDirectory -WasPresent $pathWasPresent
    Import-EnvironmentPath

    $claudePath = Find-RuntimeExecutable -Name 'claude.exe' -PreferredPaths @(
        (Join-Path $claudeDirectory 'claude.exe')
    )
    Invoke-NativeCommand -FilePath $claudePath -ArgumentList @('--version')
    Write-Success 'Claude Code was installed with the official native Windows installer.'
}

function Install-CodexCli {
    $npmPath = Get-NpmCommandPath
    Invoke-NativeCommand -FilePath $npmPath -ArgumentList @('install', '--global', '@openai/codex@latest', '--no-audit', '--no-fund')

    $prefixOutput = @(& $npmPath 'config' 'get' 'prefix')
    if ($LASTEXITCODE -ne 0 -or $prefixOutput.Count -eq 0) {
        throw 'npm did not return its global prefix after installing Codex CLI.'
    }
    $npmPrefix = ([string]$prefixOutput[0]).Trim()
    $npmCodexPath = Join-Path $npmPrefix 'codex.cmd'
    if (-not (Test-Path $npmCodexPath -PathType Leaf)) {
        throw "The official Codex CLI npm shim was not found at $npmCodexPath."
    }
    Invoke-NativeCommand -FilePath $npmCodexPath -ArgumentList @('--version')

    $codexLauncher = Join-Path $script:WindowsUtilitiesDirectory 'codex.cmd'
    if (-not (Test-Path $codexLauncher -PathType Leaf)) {
        throw "The SetupVibe Codex launcher was not found at $codexLauncher."
    }
    Import-EnvironmentPath
    $resolvedCodexCommand = Get-Command 'codex' -ErrorAction SilentlyContinue
    if (-not $resolvedCodexCommand -or [IO.Path]::GetFullPath($resolvedCodexCommand.Source) -ne [IO.Path]::GetFullPath($codexLauncher)) {
        throw 'The codex command does not resolve to the SetupVibe CMD launcher before PowerShell npm shims.'
    }
    Invoke-NativeCommand -FilePath $resolvedCodexCommand.Source -ArgumentList @('--version')
    Write-Success 'Codex CLI was installed from @openai/codex and is available through the execution-policy-safe codex.cmd launcher.'
}

function Install-AntigravityCli {
    $antigravityDirectory = Join-Path $env:LOCALAPPDATA 'agy\bin'
    $pathWasPresent = Test-PathEntry -Path $antigravityDirectory -Scope 'User'
    Invoke-WithUserPowerShellProfilesPreserved -Action {
        Invoke-OfficialPowerShellInstaller -Uri 'https://antigravity.google/cli/install.ps1' -Name 'Antigravity CLI' -ScriptArguments @('--skip-aliases', '--skip-path')
    }
    Add-PathEntry -Path $antigravityDirectory -Scope 'User'
    Register-AiCliPath -Path $antigravityDirectory -WasPresent $pathWasPresent
    Import-EnvironmentPath

    $antigravityPath = Find-RuntimeExecutable -Name 'agy.exe' -PreferredPaths @(
        (Join-Path $antigravityDirectory 'agy.exe')
    )
    if ((Get-Item $antigravityPath).Length -eq 0) {
        throw "The official Antigravity CLI executable at $antigravityPath is empty."
    }
    Write-Success 'Antigravity CLI was installed as agy without modifying PowerShell profiles or aliases.'
}

function Uninstall-ClaudeCode {
    Remove-Item -Path (Join-Path $env:USERPROFILE '.local\bin\claude.exe') -Force -ErrorAction SilentlyContinue
    Remove-Item -Path (Join-Path $env:USERPROFILE '.local\share\claude') -Recurse -Force -ErrorAction SilentlyContinue

    $npmCommand = Get-Command 'npm.cmd' -ErrorAction SilentlyContinue
    if ($npmCommand) {
        try {
            Invoke-NativeCommand -FilePath $npmCommand.Source -ArgumentList @('uninstall', '--global', '@anthropic-ai/claude-code')
        }
        catch {
            Write-WarningMessage ("Could not remove a legacy npm Claude Code installation: {0}" -f $_.Exception.Message)
        }
    }
    Write-Success 'Claude Code native and legacy npm installations were removed; user configuration was preserved.'
}

function Uninstall-CodexCli {
    $npmCommand = Get-Command 'npm.cmd' -ErrorAction SilentlyContinue
    if ($npmCommand) {
        Invoke-NativeCommand -FilePath $npmCommand.Source -ArgumentList @('uninstall', '--global', '@openai/codex')
    }
    else {
        Write-WarningMessage 'npm was not found; the Codex CLI package could not be removed.'
    }
    Write-Success 'The SetupVibe-managed Codex CLI npm package was removed.'
}

function Uninstall-AntigravityCli {
    $antigravityDirectory = Join-Path $env:LOCALAPPDATA 'agy\bin'
    Remove-Item -Path (Join-Path $antigravityDirectory 'agy.exe') -Force -ErrorAction SilentlyContinue
    if ((Test-Path $antigravityDirectory) -and -not (Get-ChildItem -Path $antigravityDirectory -Force | Select-Object -First 1)) {
        Remove-Item -Path $antigravityDirectory -Force
    }
    Write-Success 'Antigravity CLI was removed; user credentials and configuration were preserved.'
}

function Install-WindowsUtilities {
    New-Item -Path $script:WindowsUtilitiesDirectory -ItemType Directory -Force | Out-Null
    $installedFiles = New-Object System.Collections.Generic.List[string]
    $failedUtilities = New-Object System.Collections.Generic.List[string]
    $previousManagedFiles = @()
    if (Test-Path $script:WindowsUtilitiesStatePath -PathType Leaf) {
        try {
            $previousState = Get-Content -Path $script:WindowsUtilitiesStatePath -Raw | ConvertFrom-Json
            $previousManagedFiles = @($previousState.Files)
        }
        catch {
            Write-WarningMessage ("Could not read the previous Windows utility state: {0}" -f $_.Exception.Message)
        }
    }

    foreach ($utility in $script:WindowsUtilities) {
        $sourcePath = if ($PSScriptRoot) { Join-Path $PSScriptRoot $utility.Path } else { $null }
        $destinationPath = Join-Path $script:WindowsUtilitiesDirectory $utility.Name
        $temporaryPath = "{0}.{1}.tmp" -f $destinationPath, ([Guid]::NewGuid().ToString('N'))

        Write-Host ("[RUN] Installing Windows utility: {0}" -f $utility.Name)
        try {
            if ($sourcePath -and (Test-Path $sourcePath -PathType Leaf)) {
                Copy-Item -Path $sourcePath -Destination $temporaryPath -Force
            }
            else {
                [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
                $downloadUrl = "https://raw.githubusercontent.com/promovaweb/setupvibe/windows/{0}" -f $utility.Path
                $webClient = New-Object Net.WebClient
                try {
                    $webClient.DownloadFile($downloadUrl, $temporaryPath)
                }
                finally {
                    $webClient.Dispose()
                }
            }

            if (-not (Test-Path $temporaryPath -PathType Leaf) -or (Get-Item $temporaryPath).Length -eq 0) {
                throw "The downloaded utility '$($utility.Name)' is empty or missing."
            }
            Move-Item -Path $temporaryPath -Destination $destinationPath -Force
            $installedFiles.Add([string]$utility.Name)
            Write-Success ("Windows utility installed: {0}" -f $utility.Name)
        }
        catch {
            if (Test-Path $destinationPath -PathType Leaf) {
                $installedFiles.Add([string]$utility.Name)
            }
            $failedUtilities.Add(("{0}: {1}" -f $utility.Name, $_.Exception.Message))
            Write-WarningMessage ("Could not install Windows utility {0}: {1}" -f $utility.Name, $_.Exception.Message)
        }
        finally {
            Remove-Item -Path $temporaryPath -Force -ErrorAction SilentlyContinue
        }
    }

    foreach ($previousManagedFile in $previousManagedFiles) {
        $previousFileName = [IO.Path]::GetFileName([string]$previousManagedFile)
        if (-not [string]::IsNullOrWhiteSpace($previousFileName) -and $previousFileName -eq [string]$previousManagedFile -and $installedFiles -notcontains $previousFileName) {
            Remove-Item -Path (Join-Path $script:WindowsUtilitiesDirectory $previousFileName) -Force -ErrorAction SilentlyContinue
        }
    }
    foreach ($legacyFileName in $script:LegacyWindowsUtilityFiles) {
        Remove-Item -Path (Join-Path $script:WindowsUtilitiesDirectory $legacyFileName) -Force -ErrorAction SilentlyContinue
    }

    $state = @{ Files = @($installedFiles) }
    $state | ConvertTo-Json | Set-Content -Path $script:WindowsUtilitiesStatePath -Encoding ASCII
    Add-PathEntry -Path $script:WindowsUtilitiesDirectory -Scope 'User' -Prepend
    Import-EnvironmentPath

    if ($failedUtilities.Count -gt 0) {
        throw "One or more Windows utilities failed to install: $($failedUtilities -join '; ')"
    }
    Write-Success ("Windows utilities are available from {0}. Open a new terminal to use them globally." -f $script:WindowsUtilitiesDirectory)
}

function Uninstall-WindowsUtilities {
    $managedFiles = @($script:WindowsUtilities | ForEach-Object { $_.Name })
    if (Test-Path $script:WindowsUtilitiesStatePath -PathType Leaf) {
        try {
            $state = Get-Content -Path $script:WindowsUtilitiesStatePath -Raw | ConvertFrom-Json
            $managedFiles = @($state.Files)
        }
        catch {
            Write-WarningMessage ("Could not read the Windows utility state file; using the current managed list: {0}" -f $_.Exception.Message)
        }
    }

    foreach ($managedFile in $managedFiles) {
        $fileName = [IO.Path]::GetFileName([string]$managedFile)
        if ([string]::IsNullOrWhiteSpace($fileName) -or $fileName -ne [string]$managedFile) {
            Write-WarningMessage ("Ignored an invalid managed utility file name: {0}" -f $managedFile)
            continue
        }
        Remove-Item -Path (Join-Path $script:WindowsUtilitiesDirectory $fileName) -Force -ErrorAction SilentlyContinue
    }
    foreach ($legacyFileName in $script:LegacyWindowsUtilityFiles) {
        Remove-Item -Path (Join-Path $script:WindowsUtilitiesDirectory $legacyFileName) -Force -ErrorAction SilentlyContinue
    }

    Remove-Item -Path $script:WindowsUtilitiesStatePath -Force -ErrorAction SilentlyContinue
    if ((Test-Path $script:WindowsUtilitiesDirectory) -and -not (Get-ChildItem -Path $script:WindowsUtilitiesDirectory -Force | Select-Object -First 1)) {
        Remove-Item -Path $script:WindowsUtilitiesDirectory -Force
    }
    if ((Test-Path $script:SetupVibeUserDirectory) -and -not (Get-ChildItem -Path $script:SetupVibeUserDirectory -Force | Select-Object -First 1)) {
        Remove-Item -Path $script:SetupVibeUserDirectory -Force
    }

    Remove-PathEntry -Path $script:WindowsUtilitiesDirectory -Scope 'User'
    Import-EnvironmentPath
    Write-Success 'SetupVibe-managed Windows utilities and their user PATH entry were removed.'
}

function Remove-LegacyToolchainPaths {
    $legacyUserPaths = @(
        (Join-Path $env:USERPROFILE '.cargo\bin')
        (Join-Path $env:USERPROFILE '.local\bin')
        (Join-Path $env:APPDATA 'npm')
        (Join-Path $env:APPDATA 'Composer\vendor\bin')
    )
    foreach ($legacyPath in $legacyUserPaths) {
        Remove-PathEntry -Path $legacyPath -Scope 'User'
    }

    $legacyBinDirectory = Join-Path $env:ProgramData 'SetupVibe\bin'
    Remove-PathEntry -Path $legacyBinDirectory -Scope 'Machine'
    Remove-Item -Path $legacyBinDirectory -Recurse -Force -ErrorAction SilentlyContinue
    Import-EnvironmentPath
    Write-Success 'Legacy language-toolchain PATH entries removed.'
}

if ($env:OS -ne 'Windows_NT') {
    throw 'This installer can only run on Windows.'
}

$currentVersion = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
$currentBuild = [int]$currentVersion.CurrentBuildNumber
if ([string]$currentVersion.ProductName -match 'Server') {
    throw 'SetupVibe Windows Desktop does not support Windows Server. Use the Linux Server Edition instead.'
}
if (-not $Uninstall -and $currentBuild -lt 22621) {
    throw 'SetupVibe Windows requires Windows 11 version 22H2 (build 22621) or later.'
}
$nativeArchitecture = if ($env:PROCESSOR_ARCHITEW6432) { $env:PROCESSOR_ARCHITEW6432 } else { $env:PROCESSOR_ARCHITECTURE }
if ($nativeArchitecture -ne 'AMD64') {
    throw "SetupVibe Windows requires an x64 (AMD64) edition of Windows. Detected architecture: $nativeArchitecture."
}

if (-not (Test-Administrator)) {
    Request-Elevation
}

Import-EnvironmentPath

New-Item -Path $script:LogDirectory -ItemType Directory -Force | Out-Null
$logPath = Join-Path $script:LogDirectory ("desktop-{0:yyyyMMdd-HHmmss}.log" -f (Get-Date))
try {
    Start-Transcript -Path $logPath -Force | Out-Null
    $script:TranscriptStarted = $true
}
catch {
    Write-WarningMessage ("Could not start the transcript log: {0}" -f $_.Exception.Message)
}

Write-Host ("SetupVibe Windows Desktop (Beta) v{0}" -f $script:Version) -ForegroundColor Magenta
Write-Host ("Windows build: {0}" -f $currentBuild)

Invoke-SetupStep -Name 'Windows servicing and installer readiness' -Action {
    Invoke-WindowsInstallerPreflight -RequireWindowsUpdate:(-not $Uninstall)
}
Stop-SetupIfFailed -LogPath $logPath

if ($Uninstall) {
    Write-Section 'Uninstall mode'
    Write-Host 'Removing all utilities and configurations managed by SetupVibe Windows.'

    Invoke-SetupStep -Name 'Legacy SetupVibe PowerShell profile blocks' -Action { Uninstall-PowerShellProfile }
    Invoke-SetupStep -Name 'Claude Code' -Action { Uninstall-ClaudeCode }
    Invoke-SetupStep -Name 'Codex CLI' -Action { Uninstall-CodexCli }
    Invoke-SetupStep -Name 'Antigravity CLI' -Action { Uninstall-AntigravityCli }
    Invoke-SetupStep -Name 'AI CLI PATH entries' -Action { Uninstall-AiCliPaths }
    Invoke-SetupStep -Name 'Legacy ecosystem tools' -Action { Uninstall-LegacyEcosystemTools }
    Invoke-SetupStep -Name 'Node.js 24 LTS official MSI' -Action { Uninstall-NodeJs }
    Invoke-SetupStep -Name 'Python 3.14 official installer' -Action { Uninstall-Python }
    Invoke-SetupStep -Name 'Python and Node.js machine PATH' -Action { Uninstall-DevelopmentRuntimePaths }

    $script:WinGetPath = Find-WinGet
    if ($script:WinGetPath) {
        $packagesToRemove = @($script:WinGetPackages) + @($script:LegacyWinGetPackages)
        foreach ($package in $packagesToRemove) {
            Invoke-SetupStep -Name ("Remove WinGet: {0}" -f $package.Name) -Action {
                Uninstall-WinGetPackage -Id $package.Id -Name $package.Name
            }
        }
    }
    else {
        Write-WarningMessage 'WinGet was not found; WinGet-managed packages could not be checked.'
    }

    $script:ChocolateyPath = Find-Chocolatey
    if ($script:ChocolateyPath) {
        foreach ($package in $script:ChocolateyPackages) {
            Invoke-SetupStep -Name ("Remove Chocolatey: {0}" -f $package.Name) -Action {
                Uninstall-ChocolateyPackage -Id $package.Id -Name $package.Name
            }
        }
    }
    else {
        Write-WarningMessage 'Chocolatey was not found; Chocolatey-managed packages could not be checked.'
    }

    Invoke-SetupStep -Name 'OpenSSH Client and Server' -Action { Uninstall-OpenSsh }
    Invoke-SetupStep -Name 'SetupVibe Windows utilities' -Action { Uninstall-WindowsUtilities }
    if ($currentBuild -ge 22621) {
        Invoke-SetupStep -Name 'Windows Subsystem for Linux' -Action { Uninstall-WindowsSubsystemForLinux }
    }
    Invoke-SetupStep -Name 'Legacy toolchain PATH entries' -Action { Remove-LegacyToolchainPaths }
}
else {
    Invoke-SetupStep -Name 'OpenSSH Client and Server' -Action { Install-OpenSsh }
    Invoke-SetupStep -Name 'SetupVibe Windows utilities' -Action { Install-WindowsUtilities }
    Invoke-SetupStep -Name 'Windows Subsystem for Linux base' -Action { Install-WindowsSubsystemForLinux }
    Invoke-SetupStep -Name 'WSL development networking and optimization' -Action { Install-WslDevelopmentConfiguration }
    Invoke-SetupStep -Name 'WinGet' -Action { Install-WinGet }
    Invoke-SetupStep -Name 'Chocolatey' -Action { Install-Chocolatey }
    Invoke-SetupStep -Name 'Python 3.14 official installer' -Action { Install-Python }
    Invoke-SetupStep -Name 'Node.js 24 LTS official MSI' -Action { Install-NodeJs }

    if ($script:WinGetPath) {
        foreach ($package in $script:WinGetPackages) {
            Invoke-SetupStep -Name ("WinGet: {0}" -f $package.Name) -Action {
                Install-WinGetPackage -Id $package.Id -Name $package.Name
            }
        }
        Invoke-SetupStep -Name 'GitHub CLI command (gh)' -Action { Test-GitHubCli }
        Invoke-SetupStep -Name 'Windows Terminal command (wt)' -Action { Test-WindowsTerminal }
    }
    Invoke-SetupStep -Name 'Python and Node.js PATH for Claude and Codex' -Action { Install-DevelopmentRuntimePaths }
    Invoke-SetupStep -Name 'Claude Code native CLI' -Action { Install-ClaudeCode }
    Invoke-SetupStep -Name 'Codex CLI' -Action { Install-CodexCli }
    Invoke-SetupStep -Name 'Antigravity CLI (agy)' -Action { Install-AntigravityCli }

    if ($script:ChocolateyPath) {
        foreach ($package in $script:ChocolateyPackages) {
            Invoke-SetupStep -Name ("Chocolatey: {0}" -f $package.Name) -Action {
                Install-ChocolateyPackage -Id $package.Id -Name $package.Name
            }
        }
    }

    Import-EnvironmentPath
    Invoke-SetupStep -Name 'Original Windows PowerShell profile' -Action {
        Uninstall-PowerShellProfile
        if ($script:WinGetPath -and (Test-WinGetPackageInstalled -Id 'Starship.Starship')) {
            Uninstall-WinGetPackage -Id 'Starship.Starship' -Name 'Starship'
        }
        Write-Success 'The original Windows PowerShell profile is preserved without Starship, zoxide initialization, or ZSH.'
    }
}

Stop-SetupIfFailed -LogPath $logPath
Write-Section 'Summary'
if ($Uninstall) {
    Write-Success 'SetupVibe-managed Windows utilities and configurations were removed.'
}
else {
    Write-Success 'The native Windows utility environment with Python, Node.js, Claude Code, Codex CLI, and Antigravity CLI is configured.'
}

if ($script:RestartRequired) {
    if ($Restart) {
        Write-WarningMessage 'Restarting Windows now...'
        if ($script:TranscriptStarted) {
            Stop-Transcript | Out-Null
            $script:TranscriptStarted = $false
        }
        Restart-Computer -Force
    }
    else {
        Write-WarningMessage 'Restart Windows to finish applying the requested components.'
    }
}
else {
    Write-Success 'No restart was requested by Windows.'
}

Write-Host ("Log: {0}" -f $logPath)
if ($script:TranscriptStarted) {
    Stop-Transcript | Out-Null
}
