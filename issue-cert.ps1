<#
.SYNOPSIS
Issues a device certificate signed by the local root CA.

.DESCRIPTION
Creates a device-specific OpenSSL configuration, generates a private key and
certificate signing request, and signs the certificate with the local root CA.

.PARAMETER DeviceName
DNS name used for the device certificate common name and DNS SAN entry.

.PARAMETER IPAddress
IP address included in the certificate SAN extension.

.EXAMPLE
powershell -ExecutionPolicy Bypass -File .\issue-cert.ps1 -DeviceName device.local -IPAddress 192.168.1.10

.NOTES
This script expects the root CA key and certificate to already exist under the
repository-local pki folder and requires openssl to be available in PATH.
#>
param(
    [string]$DeviceName = "device.local",
    [string]$IPAddress = "192.168.1.10"
)

$root = Join-Path $PSScriptRoot "pki"
$caKey = "$root/ca/myCA.key"
$caCert = "$root/ca/myCA.pem"

$deviceDir = "$root/devices/$DeviceName"
New-Item -ItemType Directory -Force -Path $deviceDir | Out-Null

$cnf = @"
[req]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[dn]
C = IE
ST = Wexford
L = Wexford
O = HomeLab
CN = $DeviceName

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DeviceName
IP.1 = $IPAddress
"@

$cnfPath = "$deviceDir/device.cnf"
$cnf | Out-File -Encoding ascii $cnfPath

openssl genrsa -out "$deviceDir/device.key" 2048
openssl req -new -key "$deviceDir/device.key" -out "$deviceDir/device.csr" -config $cnfPath

openssl x509 -req -in "$deviceDir/device.csr" -CA $caCert -CAkey $caKey `
    -CAcreateserial -out "$deviceDir/device.crt" -days 825 -sha256 `
    -extfile $cnfPath -extensions req_ext

Write-Host "Certificate issued for $DeviceName"
Write-Host "Location: $deviceDir"
