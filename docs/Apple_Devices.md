# Installing Your Root CA on Apple Devices (iPhone and iPad)

This guide shows how to trust your local root CA on Apple mobile devices so LAN HTTPS pages signed by your CA open without certificate warnings.

## Prerequisites

- You already created your CA with `create-ca.ps1`
- Your CA certificate exists at `pki/ca/myCA.pem`
- You issued device certificates with matching DNS/IP SANs

## 1. Export the CA Certificate to a Mobile-Friendly Format

Run this from the repository root:

```powershell
openssl x509 -in .\pki\ca\myCA.pem -outform der -out .\pki\ca\myCA.cer
```

This creates `pki/ca/myCA.cer` for import on Apple devices.

## 2. Transfer the Certificate to the Apple Device

Use one of these methods:

- AirDrop
- Email attachment
- iCloud Drive / Files app
- A local HTTPS/HTTP download link on your LAN

## 3. Install the Certificate Profile

On the iPhone or iPad:

1. Open `myCA.cer`.
2. Tap **Allow** if prompted to download profile.
3. Open **Settings**.
4. Go to **General** -> **VPN & Device Management** (or **Profile Downloaded** if shown).
5. Tap the downloaded profile and tap **Install**.

## 4. Enable Full Trust for the Root CA

After profile install, Apple still requires explicit trust:

1. Open **Settings** -> **General** -> **About** -> **Certificate Trust Settings**.
2. Under **Enable full trust for root certificates**, enable your CA.
3. Confirm when prompted.

## 5. Validate with Matching Hostname or IP

Open your LAN sites using names or IP addresses included in each certificate SAN.

Examples:

- `https://raspberrypi.local`
- `https://192.168.1.50`
- `https://omada.local`
- `https://192.168.1.80`

If the URL host does not match the cert SAN entries, the browser will still warn.

## Troubleshooting

- If trust options are missing, confirm the profile is installed first.
- If warnings continue, delete and reinstall the profile, then re-enable full trust.
- If only one device fails, verify date/time on that device.
- If one URL fails but another works, regenerate the server cert with the correct DNS/IP SAN values.
