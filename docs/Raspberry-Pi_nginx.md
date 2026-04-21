# Using SSL‑SelfSigned to Generate and Install a Certificate on Raspberry Pi (Nginx)

This guide explains how to use the **SSL‑SelfSigned** toolkit to generate a trusted certificate for a Raspberry Pi running **Nginx**, such as the Pi used in the Temp/Humidity Monitor project.

---

## 1. Prerequisites

You need:

- A Raspberry Pi running Nginx
- The SSL‑SelfSigned toolkit on your workstation  
  <https://github.com/LeighdePaor/SSL-SelfSigned>
- A Root CA created using the toolkit
- SSH access to the Pi

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

Install **myCA.pem** into your PC’s Trusted Root store.

---

## 3. Issue a Certificate for the Raspberry Pi

Run:

```powershell
pwsh .vscode/issue-cert.ps1 -DeviceName "raspberrypi.local" -IPAddress "192.168.1.50"
```

This creates:

```code
pki/devices/raspberrypi.local/
    device.key
    device.crt
    device.csr
    device.cnf
```

---

## 4. Copy Certificate to the Raspberry Pi

Use SCP or WinSCP:

```powershell
scp pki/devices/raspberrypi.local/device.crt pi@192.168.1.50:/etc/ssl/certs/
scp pki/devices/raspberrypi.local/device.key pi@192.168.1.50:/etc/ssl/private/
scp pki/ca/myCA.pem pi@192.168.1.50:/etc/ssl/certs/
```

Ensure permissions:

```bash
sudo chmod 600 /etc/ssl/private/device.key
sudo chmod 644 /etc/ssl/certs/device.crt
sudo chmod 644 /etc/ssl/certs/myCA.pem
```

---

## 5. Configure Nginx to Use the Certificate

Edit your site config:

```bash
sudo nano /etc/nginx/sites-available/default
```

Update the HTTPS server block:

```nginx
server {
    listen 443 ssl;
    server_name raspberrypi.local;

    ssl_certificate     /etc/ssl/certs/device.crt;
    ssl_certificate_key /etc/ssl/private/device.key;
    ssl_trusted_certificate /etc/ssl/certs/myCA.pem;

    root /var/www/html;
    index index.html index.htm;
}
```

Save and test:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

## 6. Verify HTTPS

Visit:

```code
https://raspberrypi.local
```

Your browser should show a **trusted** HTTPS connection.

---

## 7. Renewal

To renew:

```powershell
pwsh .vscode/issue-cert.ps1 -DeviceName "raspberrypi.local" -IPAddress "192.168.1.50"
```

Copy the new files to the Pi and reload Nginx.

---

## Done

Your Raspberry Pi now serves HTTPS using a certificate issued by your own CA.
