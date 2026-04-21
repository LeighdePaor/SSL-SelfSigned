param(
    [string]$DeviceName = "device.local",
    [string]$IPAddress = "192.168.1.10"
)

$root = "$PSScriptRoot/../pki"
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
