param(
    [string]$WorkDir = "$PSScriptRoot/openssl-src",
    [string]$InstallDir = "$PSScriptRoot/openssl-install",
    [switch]$RunTests,
    [switch]$ForceClean
)

$ErrorActionPreference = "Stop"

# User-provided tool locations
$PerlBin = "C:\Strawberry\perl\bin"
$NasmBin = "C:\Users\leigh\AppData\Local\bin\NASM"

# OpenSSL source settings
$RepoUrl = "https://github.com/openssl/openssl.git"
$TagName = "openssl-4.0.0"
$SourceDir = Join-Path $WorkDir "openssl"

Write-Host "Preparing environment..."
if (-not (Test-Path $PerlBin)) {
    throw "Perl path not found: $PerlBin"
}
if (-not (Test-Path $NasmBin)) {
    throw "NASM path not found: $NasmBin"
}

# Prepend Perl and NASM to PATH for this script process.
$env:Path = "$PerlBin;$NasmBin;$env:Path"

foreach ($cmd in @("git", "perl", "nasm")) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        throw "Required command '$cmd' was not found in PATH."
    }
}

foreach ($dir in @($WorkDir, $InstallDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }
}

if ($ForceClean -and (Test-Path $SourceDir)) {
    Write-Host "ForceClean enabled: removing existing source at $SourceDir"
    Remove-Item -Recurse -Force $SourceDir
}

if (-not (Test-Path $SourceDir)) {
    Write-Host "Cloning OpenSSL repository..."
    git clone $RepoUrl $SourceDir
} else {
    Write-Host "Using existing source tree: $SourceDir"
}

Push-Location $SourceDir
try {
    Write-Host "Fetching tags..."
    git fetch --tags --force

    Write-Host "Checking out $TagName..."
    git checkout $TagName

    # Clean source tree so repeated builds are deterministic.
    git clean -xdf

    # OpenSSL Windows build with NASM for 64-bit MSVC.
    Write-Host "Configuring OpenSSL..."
    perl Configure VC-WIN64A --prefix="$InstallDir"

    if (-not (Get-Command nmake -ErrorAction SilentlyContinue)) {
        throw "nmake was not found. Run this from a Visual Studio Developer PowerShell/Prompt (x64), or initialize VS build tools first."
    }

    Write-Host "Building OpenSSL..."
    nmake

    if ($RunTests) {
        Write-Host "Running OpenSSL tests..."
        nmake test
    }

    Write-Host "Installing OpenSSL..."
    nmake install

    Write-Host ""
    Write-Host "Build complete."
    Write-Host "Source : $SourceDir"
    Write-Host "Install: $InstallDir"
} finally {
    Pop-Location
}
