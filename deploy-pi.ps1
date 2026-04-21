param(
    [Parameter(Mandatory=$true)]
    [string]$DeviceName,

    [Parameter(Mandatory=$true)]
    [string]$PiHost,          # e.g. 192.168.1.50 or raspberrypi.local

    [string]$User = "pi"
)

$root = "${$PSScriptRoot}/../pki"
$deviceDir = "${$root}/devices/${$DeviceName}"

$crt = "${$deviceDir}/device.crt"
$key = "${$deviceDir}/device.key"
$ca  = "${$root}/ca/myCA.pem"

if (!(Test-Path $crt) -or !(Test-Path $key)) {
    Write-Host "ERROR: Certificate or key not found for ${$DeviceName}"
    exit 1
}

Write-Host "Deploying certificate to Raspberry Pi (${$PiHost})..."

# Copy files
scp $crt "${$User}@${$PiHost}:/tmp/device.crt"
scp $key "${$User}@${$PiHost}:/tmp/device.key"
scp $ca  "${$User}@${$PiHost}:/tmp/myCA.pem"

# Move into place and set permissions
ssh "${$User}@${$PiHost}" "sudo mv /tmp/device.crt /etc/ssl/certs/ &&
                     sudo mv /tmp/device.key /etc/ssl/private/ &&
                     sudo mv /tmp/myCA.pem /etc/ssl/certs/ &&
                     sudo chmod 600 /etc/ssl/private/device.key &&
                     sudo chmod 644 /etc/ssl/certs/device.crt &&
                     sudo chmod 644 /etc/ssl/certs/myCA.pem &&
                     sudo nginx -t &&
                     sudo systemctl reload nginx"

Write-Host "Deployment complete!"
Write-Host "Visit: https://${$PiHost}"
