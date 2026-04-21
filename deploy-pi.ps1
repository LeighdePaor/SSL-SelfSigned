param(
    [Parameter(Mandatory=$true)]
    [string]$DeviceName,

    [Parameter(Mandatory=$true)]
    [string]$PiHost,          # e.g. 192.168.1.50 or raspberrypi.local

    [string]$User = "pi"
)

$root = Join-Path $PSScriptRoot "pki"
$deviceDir = Join-Path (Join-Path $root "devices") $DeviceName

$crt = Join-Path $deviceDir "device.crt"
$key = Join-Path $deviceDir "device.key"
$ca  = Join-Path (Join-Path $root "ca") "myCA.pem"

if (!(Test-Path $crt) -or !(Test-Path $key) -or !(Test-Path $ca)) {
    Write-Host "ERROR: Certificate, key, or CA file not found for $DeviceName"
    Write-Host "Checked paths:"
    Write-Host "  CRT: $crt"
    Write-Host "  KEY: $key"
    Write-Host "  CA : $ca"
    exit 1
}

Write-Host "Deploying certificate to Raspberry Pi ($PiHost)..."

# Copy files
scp $crt "${User}@${PiHost}:/tmp/device.crt"
if ($LASTEXITCODE -ne 0) { throw "Failed to copy device certificate to $PiHost" }

scp $key "${User}@${PiHost}:/tmp/device.key"
if ($LASTEXITCODE -ne 0) { throw "Failed to copy device key to $PiHost" }

scp $ca  "${User}@${PiHost}:/tmp/myCA.pem"
if ($LASTEXITCODE -ne 0) { throw "Failed to copy CA certificate to $PiHost" }

# Move into place and set permissions
ssh "$User@$PiHost" "sudo mv /tmp/device.crt /etc/ssl/certs/ &&
                     sudo mv /tmp/device.key /etc/ssl/private/ &&
                     sudo mv /tmp/myCA.pem /etc/ssl/certs/ &&
                     sudo chmod 600 /etc/ssl/private/device.key &&
                     sudo chmod 644 /etc/ssl/certs/device.crt &&
                     sudo chmod 644 /etc/ssl/certs/myCA.pem &&
                     sudo nginx -t &&
                     sudo systemctl reload nginx"
if ($LASTEXITCODE -ne 0) { throw "Remote install/reload steps failed on $PiHost" }

Write-Host "Deployment complete!"
Write-Host "Visit: https://$PiHost"
