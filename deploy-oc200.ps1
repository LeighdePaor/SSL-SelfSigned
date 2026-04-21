param(
    [Parameter(Mandatory=$true)]
    [string]$DeviceName,

    [Parameter(Mandatory=$true)]
    [string]$ControllerURL   # e.g. https://192.168.1.80 or https://omada.local
)

$root = "${$PSScriptRoot}/../pki"
$deviceDir = "${$root}/devices/${$DeviceName}"
$deployDir = "${$root}/deploy-oc200"

if (!(Test-Path $deviceDir)) {
    Write-Host "ERROR: Device folder not found: ${$deviceDir}"
    exit 1
}

# Create deployment folder
if (!(Test-Path $deployDir)) {
    New-Item -ItemType Directory -Path $deployDir | Out-Null
}

Copy-Item "${$deviceDir}/device.crt" $deployDir -Force
Copy-Item "${$deviceDir}/device.key" $deployDir -Force
Copy-Item "${$root}/ca/myCA.pem"     $deployDir -Force

Write-Host "Files prepared for OC200 upload:"
Write-Host " - ${$deployDir}/device.crt"
Write-Host " - ${$deployDir}/device.key"
Write-Host " - ${$deployDir}/myCA.pem"
Write-Host ""

# Open the OC200 SSL upload page
$sslPage = "${$ControllerURL}/#/settings/controller/ssl"
Write-Host "Opening OC200 SSL Certificate page..."
Start-Process $sslPage

Write-Host ""
Write-Host "=============================================="
Write-Host " Manual Step Required"
Write-Host " Upload the following files:"
Write-Host "   Certificate: device.crt"
Write-Host "   Private Key: device.key"
Write-Host "   CA Bundle:   myCA.pem"
Write-Host " Location: ${$deployDir}"
Write-Host "=============================================="
