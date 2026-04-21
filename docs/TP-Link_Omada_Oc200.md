# Using SSL‑SelfSigned to Generate and Install a Certificate on TP‑Link Omada OC200

This guide explains how to use the **SSL‑SelfSigned** toolkit to generate a trusted certificate for a TP‑Link **Omada OC200** hardware controller.

Once installed, your browser will show a fully trusted HTTPS connection to the controller.

---

## 1. Prerequisites

Before starting, ensure you have:

- A working installation of OpenSSL (your repo includes build instructions)
- The SSL‑SelfSigned toolkit cloned locally  
  <https://github.com/LeighdePaor/SSL-SelfSigned>
- A Root CA created using the toolkit
- The OC200 reachable via hostname or IP

---

## 2. Create Your Root CA

From the repo root:

```powershell
pwsh .vscode/create-ca.ps1
```

This generates:

```code
pki/ca/myCA.key
pki/ca/myCA.pem
```

Install **myCA.pem** into your PC’s Trusted Root store so your browser trusts all certificates issued by this CA.

---

## 3. Issue a Certificate for the OC200

Run the certificate‑issuing script:

```powershell
pwsh .vscode/issue-cert.ps1 -DeviceName "omada.local" -IPAddress "192.168.1.80"
```

This creates:

```code
pki/devices/omada.local/
    device.key
    device.crt
    device.csr
    device.cnf
```

These are the files you will upload to the OC200.

---

## 4. Upload Certificate to the OC200

1. Log in to the Omada controller.
2. Navigate to:  
   **Settings → Controller → SSL Certificate**
3. Select **Manual Upload**
4. Upload the following:

    | OC200 Field             | File from Toolkit |
    | ----------------------- | ----------------- |
    | Certificate             | `device.crt`      |
    | Private Key             | `device.key`      |
    | CA Bundle (if required) | `myCA.pem`        |

5. Save and reboot the controller if prompted.

---

## 5. Verify HTTPS

Open your controller URL:

```code
https://omada.local
```

or

```code
https://192.168.1.80
```

Your browser should now show a **trusted** HTTPS connection with no warnings.

---

## 6. Renewal

To renew the certificate:

```powershell
pwsh .vscode/issue-cert.ps1 -DeviceName "omada.local" -IPAddress "192.168.1.80"
```

Upload the new certificate and key using the same steps.

---
