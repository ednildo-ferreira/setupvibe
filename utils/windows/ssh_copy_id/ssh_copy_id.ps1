#Requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Position = 0)][string]$Remote,
    [Parameter()][ValidateRange(1, 65535)][int]$Port = 22,
    [Parameter()][switch]$NoConnect
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-OpenSshClientAvailable {
    $sshCommand = Get-Command 'ssh.exe' -ErrorAction SilentlyContinue
    $sshKeygenCommand = Get-Command 'ssh-keygen.exe' -ErrorAction SilentlyContinue
    if ($sshCommand -and $sshKeygenCommand) {
        return
    }

    throw 'OpenSSH Client and ssh-keygen are required. Run SetupVibe Windows to install the signed Win32-OpenSSH MSI, then open a new terminal and try again.'
}

function Test-PublicKey {
    param([Parameter(Mandatory = $true)][string]$Path)

    & $script:SshKeygenPath -l -f $Path 2>$null | Out-Null
    return $LASTEXITCODE -eq 0
}

function Find-PublicKey {
    param([Parameter(Mandatory = $true)][string]$SshDirectory)

    $preferredNames = @('id_ed25519.pub', 'id_ecdsa.pub', 'id_rsa.pub')
    foreach ($name in $preferredNames) {
        $candidate = Join-Path $SshDirectory $name
        if ((Test-Path $candidate -PathType Leaf) -and (Test-PublicKey -Path $candidate)) {
            return $candidate
        }
    }

    $otherKeys = @(Get-ChildItem -Path $SshDirectory -Filter '*.pub' -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike '*-cert.pub' } | Sort-Object Name)
    foreach ($candidate in $otherKeys) {
        if (Test-PublicKey -Path $candidate.FullName) {
            return $candidate.FullName
        }
    }
    return $null
}

function Restore-PublicKey {
    param([Parameter(Mandatory = $true)][string]$SshDirectory)

    foreach ($name in @('id_ed25519', 'id_ecdsa', 'id_rsa')) {
        $privateKeyPath = Join-Path $SshDirectory $name
        if (-not (Test-Path $privateKeyPath -PathType Leaf)) {
            continue
        }

        $publicKeyPath = "${privateKeyPath}.pub"
        Write-Host ("Rebuilding the public key for {0}..." -f $name)
        try {
            & $script:SshKeygenPath -y -f $privateKeyPath | Set-Content -Path $publicKeyPath -Encoding ASCII
            if ($LASTEXITCODE -eq 0 -and (Test-PublicKey -Path $publicKeyPath)) {
                return $publicKeyPath
            }
        }
        finally {
            if ((Test-Path $publicKeyPath) -and -not (Test-PublicKey -Path $publicKeyPath)) {
                Remove-Item -Path $publicKeyPath -Force -ErrorAction SilentlyContinue
            }
        }
    }
    return $null
}

function New-DefaultSshKey {
    param([Parameter(Mandatory = $true)][string]$SshDirectory)

    $privateKeyPath = Join-Path $SshDirectory 'id_ed25519'
    Write-Host 'No valid SSH key was found. Creating a passphrase-free Ed25519 key...' -ForegroundColor Yellow
    $arguments = @('-q', '-t', 'ed25519', '-f', ('"{0}"' -f $privateKeyPath), '-N', '""')
    $process = Start-Process -FilePath $script:SshKeygenPath -ArgumentList $arguments -NoNewWindow -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        throw 'The Ed25519 SSH key could not be created.'
    }

    $publicKeyPath = "${privateKeyPath}.pub"
    if (-not (Test-Path $publicKeyPath -PathType Leaf) -or -not (Test-PublicKey -Path $publicKeyPath)) {
        throw "The generated public key is invalid: $publicKeyPath"
    }
    return $publicKeyPath
}

function Test-RemoteTarget {
    param([Parameter(Mandatory = $true)][string]$Value)

    return $Value -match '^[A-Za-z0-9][A-Za-z0-9._-]*@(?:[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?|\[[0-9A-Fa-f:%.]+\])$'
}

try {
    Assert-OpenSshClientAvailable
    $script:SshPath = (Get-Command 'ssh.exe' -ErrorAction Stop).Source
    $script:SshKeygenPath = (Get-Command 'ssh-keygen.exe' -ErrorAction Stop).Source

    $sshDirectory = Join-Path $env:USERPROFILE '.ssh'
    New-Item -Path $sshDirectory -ItemType Directory -Force | Out-Null

    $publicKeyPath = Find-PublicKey -SshDirectory $sshDirectory
    if (-not $publicKeyPath) {
        $publicKeyPath = Restore-PublicKey -SshDirectory $sshDirectory
    }
    if (-not $publicKeyPath) {
        $publicKeyPath = New-DefaultSshKey -SshDirectory $sshDirectory
    }
    Write-Host ("Selected SSH key: {0}" -f (Split-Path -Leaf $publicKeyPath)) -ForegroundColor Green

    if ([string]::IsNullOrWhiteSpace($Remote)) {
        $Remote = Read-Host 'Enter the remote server as user@address'
    }
    if (-not (Test-RemoteTarget -Value $Remote)) {
        throw "Invalid SSH target: '$Remote'. Use the user@address format."
    }

    Write-Host ("Copying the key to {0} on port {1}. The server password may be requested..." -f $Remote, $Port)
    $remoteCommand = 'umask 077; mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys && cat > ~/.ssh/.setupvibe_key.tmp && (grep -qxFf ~/.ssh/.setupvibe_key.tmp ~/.ssh/authorized_keys || cat ~/.ssh/.setupvibe_key.tmp >> ~/.ssh/authorized_keys); status=$?; rm -f ~/.ssh/.setupvibe_key.tmp; exit $status'
    Get-Content -Path $publicKeyPath -Raw | & $script:SshPath -p $Port $Remote $remoteCommand
    if ($LASTEXITCODE -ne 0) {
        throw "The SSH key could not be copied to $Remote."
    }
    Write-Host ("The key was copied successfully to {0}." -f $Remote) -ForegroundColor Green

    if (-not $NoConnect) {
        Write-Host 'Opening the SSH session...'
        & $script:SshPath -p $Port $Remote
        if ($LASTEXITCODE -ne 0) {
            throw "The key was copied, but the interactive connection to $Remote failed."
        }
    }
}
catch {
    Write-Error $_.Exception.Message
    throw
}
