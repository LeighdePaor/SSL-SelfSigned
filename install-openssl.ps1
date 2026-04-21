<#
.SYNOPSIS
Adds or removes the local OpenSSL build bin folder from PATH.

.DESCRIPTION
Updates PATH for CurrentUser or LocalMachine so the OpenSSL executable built
into ./openssl-install/bin is available from new terminals.

.PARAMETER InstallDir
OpenSSL install directory that contains the bin folder.

.PARAMETER Scope
Where PATH should be updated: CurrentUser or LocalMachine.

.PARAMETER Uninstall
Removes the bin folder from PATH instead of adding it.

.EXAMPLE
powershell -ExecutionPolicy Bypass -File .\install-openssl.ps1

.EXAMPLE
powershell -ExecutionPolicy Bypass -File .\install-openssl.ps1 -Scope LocalMachine

.EXAMPLE
powershell -ExecutionPolicy Bypass -File .\install-openssl.ps1 -Uninstall
#>
param(
    [string]$InstallDir = "$PSScriptRoot/openssl-install",
    [ValidateSet('CurrentUser', 'LocalMachine')]
    [string]$Scope = 'CurrentUser',
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Normalize-PathEntry {
    param([string]$Entry)

    if ([string]::IsNullOrWhiteSpace($Entry)) {
        return $null
    }

    $expanded = [Environment]::ExpandEnvironmentVariables($Entry.Trim().Trim('"'))
    try {
        return [IO.Path]::GetFullPath($expanded).TrimEnd('\\')
    } catch {
        return $expanded.TrimEnd('\\')
    }
}

$target = if ($Scope -eq 'LocalMachine') {
    [System.EnvironmentVariableTarget]::Machine
} else {
    [System.EnvironmentVariableTarget]::User
}
$binDir = Join-Path (Resolve-Path $InstallDir).Path 'bin'
$opensslExe = Join-Path $binDir 'openssl.exe'

if (-not (Test-Path $binDir)) {
    throw "OpenSSL bin directory not found: $binDir"
}

if (-not (Test-Path $opensslExe)) {
    throw "OpenSSL executable not found: $opensslExe. Build and install OpenSSL first."
}

if ($Scope -eq 'LocalMachine' -and -not (Test-IsAdministrator)) {
    throw 'LocalMachine PATH update requires an elevated PowerShell session (Run as Administrator).'
}

$existingPath = [System.Environment]::GetEnvironmentVariable('Path', $target)
if ([string]::IsNullOrWhiteSpace($existingPath)) {
    $segments = @()
} else {
    $segments = $existingPath -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
}

$normalizedBin = Normalize-PathEntry $binDir
$filtered = @(
    $segments | Where-Object {
        (Normalize-PathEntry $_) -ine $normalizedBin
    }
)

if ($Uninstall) {
    if ($filtered.Count -eq $segments.Count) {
        Write-Host "No PATH entry to remove for: $normalizedBin"
    } else {
        [System.Environment]::SetEnvironmentVariable('Path', ($filtered -join ';'), $target)
        Write-Host "Removed from $Scope PATH: $normalizedBin"
    }
} else {
    if ($filtered.Count -ne $segments.Count) {
        Write-Host "Already present in $Scope PATH: $normalizedBin"
    } else {
        $updated = @($segments + $normalizedBin)
        [System.Environment]::SetEnvironmentVariable('Path', ($updated -join ';'), $target)
        Write-Host "Added to $Scope PATH: $normalizedBin"
    }
}

# Also refresh current process PATH so this shell can use openssl immediately.
$sessionSegments = $env:Path -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
$sessionFiltered = @(
    $sessionSegments | Where-Object {
        (Normalize-PathEntry $_) -ine $normalizedBin
    }
)

if ($Uninstall) {
    $env:Path = $sessionFiltered -join ';'
} else {
    $env:Path = (@($sessionFiltered + $normalizedBin)) -join ';'
}

Write-Host "OpenSSL executable: $opensslExe"
Write-Host 'Open a new terminal for other processes to pick up PATH changes.'
