#Requires -Version 5.1

[CmdletBinding()]
param(
    [switch]$Restart
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
    @{ Id = 'PHP.PHP.8.4'; Name = 'PHP 8.4' }
    @{ Id = 'RubyInstallerTeam.RubyWithDevKit.3.3'; Name = 'Ruby 3.3 with DevKit' }
    @{ Id = 'Python.Python.3.12'; Name = 'Python 3.12' }
    @{ Id = 'astral-sh.uv'; Name = 'uv' }
    @{ Id = 'GoLang.Go'; Name = 'Go' }
    @{ Id = 'Rustlang.Rustup'; Name = 'Rustup' }
    @{ Id = 'OpenJS.NodeJS.LTS'; Name = 'Node.js LTS' }
    @{ Id = 'Oven-sh.Bun'; Name = 'Bun' }
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
    @{ Id = 'jdx.mise'; Name = 'mise' }
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

$script:NpmPackages = @(
    'pnpm'
    'npm@latest'
    'pm2'
    '@n8n/cli'
    'agentlytics'
    '@anthropic-ai/claude-code'
    '@openai/codex'
    '@githubnext/github-copilot-cli'
)

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
        (Join-Path $env:USERPROFILE '.cargo\bin')
        (Join-Path $env:USERPROFILE '.local\bin')
        (Join-Path $env:APPDATA 'npm')
        (Join-Path $env:APPDATA 'Composer\vendor\bin')
        (Join-Path $env:ProgramData 'chocolatey\bin')
    )

    $env:Path = (@($machinePath, $userPath) + $additionalPaths | Where-Object { $_ }) -join ';'
}

function Add-UserPathEntry {
    param([Parameter(Mandatory = $true)][string]$Path)

    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $entries = @($userPath -split ';' | Where-Object { $_ })
    $normalizedPath = $Path.TrimEnd('\')
    $existingEntry = $entries | Where-Object {
        ([Environment]::ExpandEnvironmentVariables($_)).TrimEnd('\') -eq $normalizedPath
    }
    if ($existingEntry) {
        return
    }

    $newPath = (@($entries) + $Path) -join ';'
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
}

function Initialize-UserPath {
    $requiredPaths = @(
        (Join-Path $env:USERPROFILE '.cargo\bin')
        (Join-Path $env:USERPROFILE '.local\bin')
        (Join-Path $env:APPDATA 'npm')
        (Join-Path $env:APPDATA 'Composer\vendor\bin')
    )

    foreach ($pathEntry in $requiredPaths) {
        Add-UserPathEntry -Path $pathEntry
    }
    Import-EnvironmentPath
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

function Install-Chocolatey {
    $chocoPath = $null
    $chocoCommand = Get-Command 'choco.exe' -ErrorAction SilentlyContinue
    if ($chocoCommand) {
        $chocoPath = $chocoCommand.Source
    }
    if (-not $chocoPath) {
        $defaultChocoPath = Join-Path $env:ProgramData 'chocolatey\bin\choco.exe'
        if (Test-Path $defaultChocoPath) {
            $chocoPath = $defaultChocoPath
        }
    }

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

function Install-Composer {
    $existingComposer = Get-Command 'composer' -ErrorAction SilentlyContinue
    if ($existingComposer) {
        Invoke-NativeCommand -FilePath $existingComposer.Source -ArgumentList @('self-update', '--no-interaction')
        Write-Success 'Composer is already installed and up to date.'
        return
    }

    $phpPath = Find-Executable -Name 'php.exe'
    $binDirectory = Join-Path $env:ProgramData 'SetupVibe\bin'
    $installerPath = Join-Path ([IO.Path]::GetTempPath()) 'SetupVibe-ComposerSetup.php'
    New-Item -Path $binDirectory -ItemType Directory -Force | Out-Null

    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $webClient = New-Object Net.WebClient
    try {
        $expectedHash = $webClient.DownloadString('https://composer.github.io/installer.sig').Trim().ToLowerInvariant()
        $webClient.DownloadFile('https://getcomposer.org/installer', $installerPath)
        $actualHash = (Get-FileHash -Path $installerPath -Algorithm SHA384).Hash.ToLowerInvariant()
        if ($actualHash -ne $expectedHash) {
            throw 'Composer installer signature verification failed.'
        }

        Invoke-NativeCommand -FilePath $phpPath -ArgumentList @($installerPath, "--install-dir=$binDirectory", '--filename=composer.phar')
    }
    finally {
        Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue
        $webClient.Dispose()
    }

    $composerCommand = Join-Path $binDirectory 'composer.cmd'
    $commandContent = "@echo off`r`nphp.exe `"%~dp0composer.phar`" %*`r`n"
    [IO.File]::WriteAllText($composerCommand, $commandContent, [Text.Encoding]::ASCII)

    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    if (($machinePath -split ';') -notcontains $binDirectory) {
        [Environment]::SetEnvironmentVariable('Path', "${machinePath};${binDirectory}", 'Machine')
    }
    Import-EnvironmentPath
    Write-Success 'Composer installed from the verified official installer.'
}

function Install-PhpToolchain {
    $composerPath = Find-Executable -Name 'composer'
    Invoke-NativeCommand -FilePath $composerPath -ArgumentList @('global', 'require', 'laravel/installer', '--no-interaction')
    Write-Success 'Laravel Installer installed.'
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
    $profileContent = @(
        $profileMarker
        "Invoke-Expression (& { (& '$starshipPath' init powershell | Out-String) })"
        "Invoke-Expression (& { (& '$zoxidePath' init powershell | Out-String) })"
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

function Install-RubyToolchain {
    $gemPath = Find-Executable -Name 'gem'
    Invoke-NativeCommand -FilePath $gemPath -ArgumentList @('install', 'bundler', 'rails', '--no-document')
    Write-Success 'Bundler and Rails installed.'
}

function Install-NodeToolchain {
    $npmPath = Find-Executable -Name 'npm.cmd'
    foreach ($package in $script:NpmPackages) {
        try {
            Invoke-NativeCommand -FilePath $npmPath -ArgumentList @('install', '--global', $package)
            Write-Success ("npm package {0} installed." -f $package)
        }
        catch {
            $script:Failures.Add("npm: $package")
            Write-Host ("[ERROR] npm package {0}: {1}" -f $package, $_.Exception.Message) -ForegroundColor Red
        }
    }
}

function Install-PythonToolchain {
    $uvPath = Find-Executable -Name 'uv.exe'
    $uvTools = @(& $uvPath tool list 2>$null)
    if (($uvTools -join "`n") -match '(?m)^specify-cli\s') {
        Invoke-NativeCommand -FilePath $uvPath -ArgumentList @('tool', 'upgrade', 'specify-cli')
        Write-Success 'Spec-Kit upgraded.'
    }
    else {
        Invoke-NativeCommand -FilePath $uvPath -ArgumentList @('tool', 'install', 'specify-cli')
        Write-Success 'Spec-Kit installed.'
    }
}

function Install-RustToolchain {
    $rustupPath = Find-Executable -Name 'rustup.exe'
    Invoke-NativeCommand -FilePath $rustupPath -ArgumentList @('update', 'stable')
    Invoke-NativeCommand -FilePath $rustupPath -ArgumentList @('default', 'stable')
    Find-Executable -Name 'cargo.exe' | Out-Null
    Write-Success 'The stable Rust toolchain and Cargo are installed.'
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

Initialize-UserPath

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
Invoke-SetupStep -Name 'Composer' -Action { Install-Composer }
Invoke-SetupStep -Name 'PHP tools: Laravel Installer' -Action { Install-PhpToolchain }
Invoke-SetupStep -Name 'Ruby tools: Bundler and Rails' -Action { Install-RubyToolchain }
Invoke-SetupStep -Name 'Node.js and AI CLI tools' -Action { Install-NodeToolchain }
Invoke-SetupStep -Name 'Python tools: Spec-Kit' -Action { Install-PythonToolchain }
Invoke-SetupStep -Name 'Rust toolchain' -Action { Install-RustToolchain }
Invoke-SetupStep -Name 'PowerShell profile: Starship and zoxide' -Action { Install-PowerShellProfile }

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

Write-Success 'The native Windows development environment is configured.'

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
