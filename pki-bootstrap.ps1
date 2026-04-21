<#
.SYNOPSIS
Creates the directory structure for the local PKI.

.DESCRIPTION
Creates the standard folder layout used by the repository scripts for CA
materials, device certificates, requests, and private assets.

.EXAMPLE
powershell -ExecutionPolicy Bypass -File .\pki-bootstrap.ps1

.NOTES
The PKI structure is created under the repository-local pki folder.
#>

$root = Join-Path $PSScriptRoot "pki"

$folders = @(
    "$root/ca",
    "$root/certs",
    "$root/private",
    "$root/requests",
    "$root/devices"
)

foreach ($f in $folders) {
    if (-not (Test-Path $f)) {
        New-Item -ItemType Directory -Path $f | Out-Null
    }
}

Write-Host "PKI folder structure created at: $root"
