<#
.SYNOPSIS
Removes a root CA certificate from a Windows trusted root store by thumbprint.

.DESCRIPTION
Finds a certificate with the supplied thumbprint in the Windows Trusted Root
Certification Authorities store for either the current user or the local
machine, then removes it.

.PARAMETER Thumbprint
Thumbprint of the certificate to remove from the trusted root store.

.PARAMETER StoreLocation
Target certificate store location. Use CurrentUser for per-user trust or
LocalMachine for system-wide trust.

.EXAMPLE
powershell -ExecutionPolicy Bypass -File .\remove-ca-cert.ps1 -Thumbprint ABCD1234

.EXAMPLE
powershell -ExecutionPolicy Bypass -File .\remove-ca-cert.ps1 -Thumbprint ABCD1234 -StoreLocation LocalMachine

.NOTES
Removing a certificate from LocalMachine\Root typically requires an elevated
PowerShell session. Use -WhatIf to preview the action.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [string]$Thumbprint,

    [ValidateSet("CurrentUser", "LocalMachine")]
    [string]$StoreLocation = "CurrentUser"
)

$ErrorActionPreference = "Stop"

$normalizedThumbprint = ($Thumbprint -replace '\s', '').ToUpperInvariant()

if ($StoreLocation -eq "LocalMachine") {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    $isAdministrator = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdministrator) {
        throw "LocalMachine store removal requires an elevated PowerShell session."
    }
}

$storePath = "Cert:\$StoreLocation\Root"
$targetCertificate = Get-ChildItem -Path $storePath | Where-Object {
    $_.Thumbprint.ToUpperInvariant() -eq $normalizedThumbprint
}

if (-not $targetCertificate) {
    throw "No certificate with thumbprint '$normalizedThumbprint' was found in $storePath."
}

if ($PSCmdlet.ShouldProcess($storePath, "Remove certificate $normalizedThumbprint")) {
    Remove-Item -Path $targetCertificate.PSPath

    Write-Host "CA certificate removed successfully."
    Write-Host "Store     : $storePath"
    Write-Host "Thumbprint: $normalizedThumbprint"
}