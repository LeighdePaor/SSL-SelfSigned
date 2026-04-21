# Installing Your Root CA on Android Devices

This guide shows how to trust your local root CA on Android so LAN HTTPS pages signed by your CA open without browser warnings.

## Prerequisites

- You already created your CA with `create-ca.ps1`
- Your CA certificate exists at `pki/ca/myCA.pem`
- You issued device certificates with matching DNS/IP SANs

## 1. Export the CA Certificate

Run this from the repository root:

```powershell
openssl x509 -in .\pki\ca\myCA.pem -outform der -out .\pki\ca\myCA.cer
```

This creates `pki/ca/myCA.cer` for Android import.

## 2. Copy the Certificate to the Android Device

Copy `myCA.cer` to local storage using USB, cloud storage, or local download.

## 3. Install as a CA Certificate

Android menu labels vary by vendor/version, but usually:

1. Open **Settings**.
2. Go to **Security** or **Security & privacy**.
3. Open **Encryption & credentials** (or similar).
4. Tap **Install a certificate**.
5. Choose **CA certificate**.
6. Select `myCA.cer` and confirm.

Android may require you to set a screen lock before allowing CA install.

## 4. Test in Browser

Use URLs that match cert SAN entries.

Examples:

- `https://raspberrypi.local`
- `https://192.168.1.50`
- `https://omada.local`
- `https://192.168.1.80`

## Important Android Behavior

- Android shows a "network may be monitored" message when user CAs are installed. This is expected.
- Most browsers will trust the CA after install.
- Some apps (and some WebView-based apps) do not trust user-installed CAs by default and may still show TLS errors.

## Troubleshooting

- If import fails, ensure file extension is `.cer` and export is DER format.
- If browser still warns, confirm host/IP matches SAN in the issued server cert.
- If one app fails while browser works, that app likely ignores user CAs.
- If needed, remove and reinstall the CA certificate from Android security settings.
