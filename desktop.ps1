#Requires -Version 5.1

[CmdletBinding()]
param(
    [switch]$Restart,
    [switch]$Uninstall,
    [ValidateRange(1, 120)][int]$InstallerWaitMinutes = 20
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'Continue'

$script:Version = '0.41.6'
$script:InstallUrl = 'https://raw.githubusercontent.com/promovaweb/setupvibe/windows/desktop.ps1'
$script:RestartRequired = $false
$script:Failures = New-Object System.Collections.Generic.List[string]
$script:LogDirectory = Join-Path $env:ProgramData 'SetupVibe\Logs'
$script:TranscriptStarted = $false
$script:WinGetPath = $null
$script:ChocolateyPath = $null
$script:WslVmCreatorId = '{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}'
$script:WslFeatureStatePath = Join-Path $env:ProgramData 'SetupVibe\wsl-feature-state.json'
$script:WslFirewallStatePath = Join-Path $env:ProgramData 'SetupVibe\wsl-firewall-inbound.txt'
$script:SetupVibeUserDirectory = Join-Path $env:USERPROFILE '.setupvibe'
$script:WindowsUtilitiesDirectory = Join-Path $script:SetupVibeUserDirectory 'bin'
$script:WindowsUtilitiesStatePath = Join-Path $script:SetupVibeUserDirectory 'windows-utilities.json'

$script:WindowsUtilities = @(
    @{ Path = 'utils/windows/ssh_copy_id/ssh_copy_id.ps1'; Name = 'ssh_copy_id.ps1' }
    @{ Path = 'utils/windows/ssh_copy_id/ssh_copy_id.cmd'; Name = 'ssh_copy_id.cmd' }
)
$script:LegacyWindowsUtilityFiles = @('ssh_copy_id.bat')

$script:WinGetPackages = @(
    @{ Id = 'Git.Git'; Name = 'Git' }
    @{ Id = '7zip.7zip'; Name = '7-Zip' }
    @{ Id = 'JernejSimoncic.Wget'; Name = 'Wget' }
    @{ Id = 'Gyan.FFmpeg'; Name = 'FFmpeg' }
    @{ Id = 'ImageMagick.ImageMagick'; Name = 'ImageMagick' }
    @{ Id = 'GitHub.cli'; Name = 'GitHub CLI' }
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
    @{ Id = 'Starship.Starship'; Name = 'Starship' }
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
    @{ Id = 'OpenJS.NodeJS.LTS'; Name = 'Node.js LTS' }
    @{ Id = 'Oven-sh.Bun'; Name = 'Bun' }
    @{ Id = 'jdx.mise'; Name = 'mise' }
)

$script:LegacyNpmPackages = @('pnpm', 'pm2', '@n8n/cli', 'agentlytics', '@anthropic-ai/claude-code', '@openai/codex', '@githubnext/github-copilot-cli', 'npm')

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
    $powerShellArguments += @('-InstallerWaitMinutes', [string]$InstallerWaitMinutes)

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
    if ($script:RestartRequired) {
        Write-WarningMessage 'Windows must be restarted before all changes can take effect.'
    }
    if ($script:TranscriptStarted) {
        Stop-Transcript | Out-Null
        $script:TranscriptStarted = $false
    }
    exit 1
}

function Wait-WindowsInstallerAvailability {
    param([Parameter(Mandatory = $true)][ValidateRange(1, 120)][int]$TimeoutMinutes)

    $installerProcessNames = @('dism', 'dismhost', 'TiWorker', 'msiexec', 'winget', 'choco')
    $stopwatch = [Diagnostics.Stopwatch]::StartNew()
    $nextHeartbeat = 0

    while ($true) {
        $activeProcesses = @(Get-Process -Name $installerProcessNames -ErrorAction SilentlyContinue | Sort-Object ProcessName, Id)
        if ($activeProcesses.Count -eq 0) {
            $stopwatch.Stop()
            Write-Success 'No competing Windows servicing or package-installer process is active.'
            return
        }

        $processSummary = ($activeProcesses | ForEach-Object { "{0} (PID {1})" -f $_.ProcessName, $_.Id }) -join ', '
        if ($stopwatch.Elapsed.TotalSeconds -ge $nextHeartbeat) {
            Write-Host ("[WAIT] Waiting for installer processes: {0}. Elapsed: {1:N0}s; limit: {2} minute(s)." -f $processSummary, $stopwatch.Elapsed.TotalSeconds, $TimeoutMinutes) -ForegroundColor DarkGray
            $nextHeartbeat += 15
        }

        if ($stopwatch.Elapsed.TotalMinutes -ge $TimeoutMinutes) {
            throw "Installer processes did not finish within $TimeoutMinutes minute(s): $processSummary. SetupVibe did not terminate them because forcibly ending Windows servicing can corrupt the component store. Restart Windows, then run the setup again."
        }
        Start-Sleep -Seconds 5
    }
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

function Invoke-WindowsInstallerPreflight {
    param(
        [Parameter(Mandatory = $true)][ValidateRange(1, 120)][int]$TimeoutMinutes,
        [Parameter()][switch]$RequireWindowsUpdate
    )

    Wait-WindowsInstallerAvailability -TimeoutMinutes $TimeoutMinutes

    $restartReasons = @(Get-PendingWindowsRestartReasons)
    if ($restartReasons.Count -gt 0) {
        $script:RestartRequired = $true
        throw "Windows has a pending restart requested by: $($restartReasons -join ', '). Restart Windows before running SetupVibe so component and package operations begin from a consistent state."
    }

    Ensure-WindowsServiceReady -Name 'TrustedInstaller'
    if ($RequireWindowsUpdate) {
        Ensure-WindowsServiceReady -Name 'wuauserv'
        Ensure-WindowsServiceReady -Name 'bits'

        $useWsus = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Name 'UseWUServer' -ErrorAction SilentlyContinue
        $blockPublicWindowsUpdate = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name 'DoNotConnectToWindowsUpdateInternetLocations' -ErrorAction SilentlyContinue
        if ([int]$useWsus -eq 1 -or [int]$blockPublicWindowsUpdate -eq 1) {
            Write-WarningMessage 'Windows Update is controlled by WSUS or domain policy. Features on Demand such as OpenSSH can fail if the corporate update source does not provide optional content.'
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

function Invoke-WindowsCapabilityDismOperation {
    param(
        [Parameter(Mandatory = $true)][ValidateSet('Add', 'Remove')][string]$Action,
        [Parameter(Mandatory = $true)][string]$CapabilityName,
        [Parameter(Mandatory = $true)][string]$DisplayName
    )

    $dismPath = Join-Path $env:SystemRoot 'System32\dism.exe'
    $safeDisplayName = $DisplayName -replace '[^A-Za-z0-9.-]', '-'
    $dismLogPath = Join-Path $script:LogDirectory ("dism-{0}-{1:yyyyMMdd-HHmmss}.log" -f $safeDisplayName, (Get-Date))
    $arguments = @(
        '/Online'
        ("/{0}-Capability" -f $Action)
        ("/CapabilityName:{0}" -f $CapabilityName)
        '/NoRestart'
        ("/LogPath:{0}" -f $dismLogPath)
    )
    $operation = if ($Action -eq 'Add') { 'installation' } else { 'removal' }

    Write-Host ("[RUN] Starting {0} for {1}. DISM will display its native percentage below." -f $operation, $DisplayName)
    Write-Host ("[INFO] DISM log: {0}" -f $dismLogPath) -ForegroundColor DarkGray
    Write-WarningMessage 'Windows Update may take several minutes to locate the capability. Keep this window open.'

    $process = Start-Process -FilePath $dismPath -ArgumentList $arguments -NoNewWindow -PassThru
    $stopwatch = [Diagnostics.Stopwatch]::StartNew()
    $nextHeartbeat = 15
    while (-not $process.HasExited) {
        Start-Sleep -Seconds 2
        $process.Refresh()
        if ($stopwatch.Elapsed.TotalSeconds -ge $nextHeartbeat) {
            Write-Host ("[WAIT] {0} {1} is still running ({2:N0}s elapsed)." -f $DisplayName, $operation, $stopwatch.Elapsed.TotalSeconds) -ForegroundColor DarkGray
            $nextHeartbeat += 15
        }
    }
    $process.WaitForExit()
    $stopwatch.Stop()

    if ($process.ExitCode -notin @(0, 3010)) {
        throw "DISM failed to complete the $DisplayName $operation with exit code $($process.ExitCode). Review $dismLogPath. If this is a Features on Demand error, verify Windows Update or WSUS optional-content policy."
    }
    if ($process.ExitCode -eq 3010) {
        $script:RestartRequired = $true
    }
}

function Install-OpenSshClient {
    $capabilityName = 'OpenSSH.Client~~~~0.0.1.0'
    Write-Host '[RUN] Checking the current OpenSSH Client capability state...'
    $capability = Get-WindowsCapability -Online -Name $capabilityName
    Write-Host ("[INFO] OpenSSH Client state: {0}" -f $capability.State) -ForegroundColor DarkGray
    if ($capability.State -in @('Installed', 'InstallPending')) {
        if ($capability.State -eq 'InstallPending') {
            $script:RestartRequired = $true
        }
        Write-Success 'OpenSSH Client is already installed.'
        return
    }

    Invoke-WindowsCapabilityDismOperation -Action 'Add' -CapabilityName $capabilityName -DisplayName 'OpenSSH Client'
    $capability = Get-WindowsCapability -Online -Name $capabilityName
    if ($capability.State -notin @('Installed', 'InstallPending')) {
        throw "OpenSSH Client installation returned without reaching an installed state. Current state: $($capability.State)."
    }
    if ($capability.State -eq 'InstallPending') {
        $script:RestartRequired = $true
    }
    Write-Success 'OpenSSH Client installed.'
}

function Uninstall-OpenSshClient {
    $capabilityName = 'OpenSSH.Client~~~~0.0.1.0'
    Write-Host '[RUN] Checking the current OpenSSH Client capability state...'
    $capability = Get-WindowsCapability -Online -Name $capabilityName
    Write-Host ("[INFO] OpenSSH Client state: {0}" -f $capability.State) -ForegroundColor DarkGray
    if ($capability.State -notin @('Installed', 'InstallPending')) {
        Write-Success 'OpenSSH Client is already absent.'
        return
    }

    Invoke-WindowsCapabilityDismOperation -Action 'Remove' -CapabilityName $capabilityName -DisplayName 'OpenSSH Client'
    $capability = Get-WindowsCapability -Online -Name $capabilityName
    if ($capability.State -in @('Installed', 'InstallPending')) {
        throw "OpenSSH Client removal returned without leaving the installed state. Current state: $($capability.State)."
    }
    if ($capability.State -eq 'UninstallPending') {
        $script:RestartRequired = $true
    }
    Write-Success 'OpenSSH Client removed.'
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

function Install-PowerShellProfile {
    $starshipPath = Find-Executable -Name 'starship.exe'
    $zoxidePath = Find-Executable -Name 'zoxide.exe'
    $configDirectory = Join-Path $env:USERPROFILE '.config'
    $starshipConfig = Join-Path $configDirectory 'starship.toml'
    New-Item -Path $configDirectory -ItemType Directory -Force | Out-Null
    Invoke-NativeCommand -FilePath $starshipPath -ArgumentList @('preset', 'gruvbox-rainbow', '-o', $starshipConfig)

    $documentsDirectory = [Environment]::GetFolderPath('MyDocuments')
    $profilePaths = @(
        (Join-Path $documentsDirectory 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1')
        (Join-Path $documentsDirectory 'PowerShell\Microsoft.PowerShell_profile.ps1')
    )
    $profileMarker = '# SetupVibe shell initialization'
    $profileEndMarker = '# End SetupVibe shell initialization'
    $profileContent = @(
        $profileMarker
        "Invoke-Expression (& { (& '$starshipPath' init powershell | Out-String) })"
        "Invoke-Expression (& { (& '$zoxidePath' init powershell | Out-String) })"
        $profileEndMarker
    ) -join "`r`n"

    foreach ($profilePath in $profilePaths) {
        $profileDirectory = Split-Path -Parent $profilePath
        New-Item -Path $profileDirectory -ItemType Directory -Force | Out-Null
        if (-not (Test-Path $profilePath) -or -not (Select-String -Path $profilePath -SimpleMatch $profileMarker -Quiet)) {
            Add-Content -Path $profilePath -Value "`r`n$profileContent`r`n" -Encoding UTF8
        }
    }
    Write-Success 'Starship and zoxide configured for Windows PowerShell and PowerShell 7.'
}

function Uninstall-PowerShellProfile {
    $documentsDirectory = [Environment]::GetFolderPath('MyDocuments')
    $profilePaths = @(
        (Join-Path $documentsDirectory 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1')
        (Join-Path $documentsDirectory 'PowerShell\Microsoft.PowerShell_profile.ps1')
    )
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
        [Parameter(Mandatory = $true)][ValidateSet('User', 'Machine')][string]$Scope
    )

    $currentPath = [Environment]::GetEnvironmentVariable('Path', $Scope)
    $normalizedPath = $Path.TrimEnd('\')
    $pathExists = @($currentPath -split ';' | Where-Object {
        $_ -and ([Environment]::ExpandEnvironmentVariables($_)).TrimEnd('\') -eq $normalizedPath
    }).Count -gt 0
    if ($pathExists) {
        return
    }

    $updatedPath = @($currentPath -split ';' | Where-Object { $_ }) + $Path
    [Environment]::SetEnvironmentVariable('Path', ($updatedPath -join ';'), $Scope)
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
    Add-PathEntry -Path $script:WindowsUtilitiesDirectory -Scope 'User'
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
if (-not [Environment]::Is64BitOperatingSystem) {
    throw 'SetupVibe Windows requires a 64-bit edition of Windows.'
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
Write-Host ("Installer wait limit: {0} minute(s)" -f $InstallerWaitMinutes)

Invoke-SetupStep -Name 'Windows servicing and installer readiness' -Action {
    Invoke-WindowsInstallerPreflight -TimeoutMinutes $InstallerWaitMinutes -RequireWindowsUpdate:(-not $Uninstall)
}
Stop-SetupIfFailed -LogPath $logPath

if ($Uninstall) {
    Write-Section 'Uninstall mode'
    Write-Host 'Removing all utilities and configurations managed by SetupVibe Windows.'

    Invoke-SetupStep -Name 'Legacy ecosystem tools' -Action { Uninstall-LegacyEcosystemTools }
    Invoke-SetupStep -Name 'PowerShell profile: Starship and zoxide' -Action { Uninstall-PowerShellProfile }

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

    Invoke-SetupStep -Name 'OpenSSH Client' -Action { Uninstall-OpenSshClient }
    Invoke-SetupStep -Name 'SetupVibe Windows utilities' -Action { Uninstall-WindowsUtilities }
    if ($currentBuild -ge 22621) {
        Invoke-SetupStep -Name 'Windows Subsystem for Linux' -Action { Uninstall-WindowsSubsystemForLinux }
    }
    Invoke-SetupStep -Name 'Legacy toolchain PATH entries' -Action { Remove-LegacyToolchainPaths }
}
else {
    Invoke-SetupStep -Name 'OpenSSH Client' -Action { Install-OpenSshClient }
    Invoke-SetupStep -Name 'SetupVibe Windows utilities' -Action { Install-WindowsUtilities }
    Invoke-SetupStep -Name 'Windows Subsystem for Linux base' -Action { Install-WindowsSubsystemForLinux }
    Invoke-SetupStep -Name 'WSL development networking and optimization' -Action { Install-WslDevelopmentConfiguration }
    Invoke-SetupStep -Name 'WinGet' -Action { Install-WinGet }
    Invoke-SetupStep -Name 'Chocolatey' -Action { Install-Chocolatey }

    if ($script:WinGetPath) {
        foreach ($package in $script:WinGetPackages) {
            Invoke-SetupStep -Name ("WinGet: {0}" -f $package.Name) -Action {
                Install-WinGetPackage -Id $package.Id -Name $package.Name
            }
        }
    }

    if ($script:ChocolateyPath) {
        foreach ($package in $script:ChocolateyPackages) {
            Invoke-SetupStep -Name ("Chocolatey: {0}" -f $package.Name) -Action {
                Install-ChocolateyPackage -Id $package.Id -Name $package.Name
            }
        }
    }

    Import-EnvironmentPath
    Invoke-SetupStep -Name 'PowerShell profile: Starship and zoxide' -Action { Install-PowerShellProfile }
}

Stop-SetupIfFailed -LogPath $logPath
Write-Section 'Summary'
if ($Uninstall) {
    Write-Success 'SetupVibe-managed Windows utilities and configurations were removed.'
}
else {
    Write-Success 'The native Windows utility environment is configured.'
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
