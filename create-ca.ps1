# ============================================
# HomeLab Root CA Creation Script
# Creates a full Certificate Authority automatically
# ============================================

$root = "$PSScriptRoot/../pki"
$caDir = "$root/ca"

# Create folder structure if missing
$folders = @(
    "$root",
    "$caDir"
)

foreach ($f in $folders) {
    if (-not (Test-Path $f)) {
        New-Item -ItemType Directory -Path $f | Out-Null
    }
}

Write-Host "PKI root directory: $root"
Write-Host "CA directory: $caDir"

# Paths
$caKey = "$caDir/myCA.key"
$caCert = "$caDir/myCA.pem"
$caConfig = "$caDir/ca.cnf"

# Create OpenSSL config for the CA
$caConfigContent = @"
[ req ]
default_bits       = 4096
default_md         = sha256
prompt             = no
distinguished_name = dn
x509_extensions    = v3_ca

[ dn ]
C  = IE
ST = Wexford
L  = Wexford
O  = HomeLab
OU = RootCA
CN = HomeLab Root CA

[ v3_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
"@

$caConfigContent | Out-File -Encoding ascii $caConfig

Write-Host "CA configuration file created at: $caConfig"

# Generate CA private key
Write-Host "Generating CA private key..."
openssl genrsa -out $caKey 4096

# Generate CA certificate
Write-Host "Generating CA certificate..."
openssl req -x509 -new -nodes -key $caKey -sha256 -days 3650 `
    -out $caCert -config $caConfig

Write-Host ""
Write-Host "============================================"
Write-Host " Root CA successfully created!"
Write-Host " Private Key : $caKey"
Write-Host " Certificate : $caCert"
Write-Host "============================================"
Write-Host ""
Write-Host "Next steps:"
Write-Host " - Install myCA.pem into your Trusted Root store"
Write-Host " - Use the Issue Device Certificate task to create device certs"
