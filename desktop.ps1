#Requires -Version 5.1

[CmdletBinding()]
param(
    [switch]$Restart,
    [switch]$Uninstall
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$script:Version = '0.41.6'
$script:InstallUrl = 'https://raw.githubusercontent.com/promovaweb/setupvibe/windows/desktop.ps1'
$script:RestartRequired = $false
$script:Failures = New-Object System.Collections.Generic.List[string]
$script:LogDirectory = Join-Path $env:ProgramData 'SetupVibe\Logs'
$script:TranscriptStarted = $false
$script:WinGetPath = $null
$script:ChocolateyPath = $null

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

function Confirm-DisableUserAccountControl {
    while ($true) {
        $response = Read-Host 'Disable User Account Control (UAC) for this computer? [Y/n]'
        if ($null -eq $response) {
            $response = ''
        }
        $response = $response.Trim().ToLowerInvariant()
        switch ($response) {
            { $_ -in @('', 'y', 'yes') } { return $true }
            { $_ -in @('n', 'no') } { return $false }
            default { Write-WarningMessage 'Enter Yes or No. Press Enter to accept the default: Yes.' }
        }
    }
}

function Disable-UserAccountControl {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    $policyPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
    $currentValue = Get-ItemPropertyValue -Path $policyPath -Name 'EnableLUA' -ErrorAction SilentlyContinue

    if ($null -ne $currentValue -and [int]$currentValue -eq 0) {
        Write-Success 'User Account Control (UAC) is already disabled.'
        return
    }

    if (-not $PSCmdlet.ShouldProcess($policyPath, 'Set EnableLUA to 0')) {
        return
    }

    New-Item -Path $policyPath -Force | Out-Null
    New-ItemProperty -Path $policyPath -Name 'EnableLUA' -PropertyType DWord -Value 0 -Force | Out-Null

    $updatedValue = Get-ItemPropertyValue -Path $policyPath -Name 'EnableLUA'
    if ([int]$updatedValue -ne 0) {
        throw 'The EnableLUA registry policy could not be set to 0.'
    }

    $script:RestartRequired = $true
    Write-WarningMessage 'User Account Control (UAC) will be disabled after Windows restarts. This reduces Windows security.'
}

function Enable-UserAccountControl {
    $policyPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
    $currentValue = Get-ItemPropertyValue -Path $policyPath -Name 'EnableLUA' -ErrorAction SilentlyContinue

    if ($null -ne $currentValue -and [int]$currentValue -eq 1) {
        Write-Success 'User Account Control (UAC) is already enabled.'
        return
    }

    New-Item -Path $policyPath -Force | Out-Null
    New-ItemProperty -Path $policyPath -Name 'EnableLUA' -PropertyType DWord -Value 1 -Force | Out-Null
    $script:RestartRequired = $true
    Write-WarningMessage 'User Account Control (UAC) will be enabled after Windows restarts.'
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
    try {
        & $Action
    }
    catch {
        $script:Failures.Add($Name)
        Write-Host ("[ERROR] {0}" -f $_.Exception.Message) -ForegroundColor Red
    }
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

function Install-OpenSshClient {
    $capabilityName = 'OpenSSH.Client~~~~0.0.1.0'
    $capability = Get-WindowsCapability -Online -Name $capabilityName
    if ($capability.State -in @('Installed', 'InstallPending')) {
        if ($capability.State -eq 'InstallPending') {
            $script:RestartRequired = $true
        }
        Write-Success 'OpenSSH Client is already installed.'
        return
    }

    $result = Add-WindowsCapability -Online -Name $capabilityName
    if ($result.RestartNeeded) {
        $script:RestartRequired = $true
    }
    Write-Success 'OpenSSH Client installed.'
}

function Uninstall-OpenSshClient {
    $capabilityName = 'OpenSSH.Client~~~~0.0.1.0'
    $capability = Get-WindowsCapability -Online -Name $capabilityName
    if ($capability.State -notin @('Installed', 'InstallPending')) {
        Write-Success 'OpenSSH Client is already absent.'
        return
    }

    $result = Remove-WindowsCapability -Online -Name $capabilityName
    if ($result.RestartNeeded) {
        $script:RestartRequired = $true
    }
    Write-Success 'OpenSSH Client removed.'
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
if ($currentBuild -lt 17763) {
    throw 'SetupVibe Windows requires Windows 10 version 1809 (build 17763) or later, or Windows 11.'
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
    Invoke-SetupStep -Name 'Legacy toolchain PATH entries' -Action { Remove-LegacyToolchainPaths }
    Invoke-SetupStep -Name 'Enable User Account Control (UAC)' -Action { Enable-UserAccountControl }
}
else {
    if (Confirm-DisableUserAccountControl) {
        Invoke-SetupStep -Name 'Disable User Account Control (UAC)' -Action { Disable-UserAccountControl }
    }
    else {
        Write-Success 'The User Account Control (UAC) policy was left unchanged by user choice.'
    }
    Invoke-SetupStep -Name 'OpenSSH Client' -Action { Install-OpenSshClient }
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

Write-Section 'Summary'
if ($script:Failures.Count -gt 0) {
    Write-Host ("Failed steps: {0}" -f ($script:Failures -join ', ')) -ForegroundColor Red
    Write-Host ("Review the log and run desktop.ps1 again: {0}" -f $logPath)
    if ($script:RestartRequired) {
        Write-WarningMessage 'Windows must be restarted before all changes can take effect.'
    }
    if ($script:TranscriptStarted) {
        Stop-Transcript | Out-Null
    }
    exit 1
}

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
