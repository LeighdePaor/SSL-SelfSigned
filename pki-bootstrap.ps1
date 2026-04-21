$root = "$PSScriptRoot/../pki"

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
