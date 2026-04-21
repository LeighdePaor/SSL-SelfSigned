# SSL-SelfSigned

This repository is a small PowerShell-based toolkit for building a local OpenSSL toolchain and using it to create a simple self-signed PKI for lab, development, and internal device testing.

It is designed for Windows and currently includes:

- A script to clone and build OpenSSL 4.0.0 from source
- A script to create the PKI folder structure
- A script to create a local root CA
- A script to issue device certificates signed by that CA
- VS Code tasks for the main OpenSSL workflow

## What This Repo Is For

Use this repo when you need to:

- Build OpenSSL locally on Windows from the official source repository
- Create a root CA for internal use
- Issue certificates for devices, services, or test endpoints
- Keep private keys and generated certificate material out of Git

This is intended for local development, homelab use, and internal environments. It is not a replacement for a production CA or managed certificate platform.

## Repository Layout

- `build-openssl-4.0.0.ps1`: Clones `https://github.com/openssl/openssl.git`, checks out `openssl-4.0.0`, and builds it on Windows
- `pki-bootstrap.ps1`: Creates the base PKI directory structure
- `create-ca.ps1`: Generates a root CA private key and self-signed certificate
- `issue-cert.ps1`: Generates and signs a device certificate
- `tasks.json`: VS Code task definitions
- `.gitignore`: Prevents generated PKI files, keys, certs, and editor config from being committed

## Prerequisites

You need the following installed on Windows:

- Git
- Visual Studio Build Tools with `nmake`
- Strawberry Perl
- NASM
- PowerShell

This repo currently assumes these paths:

- Perl: `C:\Strawberry\perl\bin`
- NASM: `C:\Users\leigh\AppData\Local\bin\NASM`

The build script prepends those paths to `PATH` for the current process.

## Building OpenSSL 4.0.0

The build script:

1. Clones the official OpenSSL repository
2. Fetches tags
3. Checks out `openssl-4.0.0`
4. Configures a 64-bit Windows build with `VC-WIN64A`
5. Runs `nmake`
6. Optionally runs tests
7. Installs the build output locally

### Option 1: Run the VS Code Task

Use the task:

- `OpenSSL: Clone + Build 4.0.0`

### Option 2: Run the Script Directly

```powershell
powershell -ExecutionPolicy Bypass -File .\build-openssl-4.0.0.ps1
```

Optional parameters:

```powershell
powershell -ExecutionPolicy Bypass -File .\build-openssl-4.0.0.ps1 -RunTests
powershell -ExecutionPolicy Bypass -File .\build-openssl-4.0.0.ps1 -ForceClean
```

Defaults:

- Source checkout: `./openssl-src/openssl`
- Install location: `./openssl-install`

Important:

- Run this from an x64 Developer PowerShell or another environment where `nmake` is available.
- If `nmake` is missing, the build script will stop with an error.

## PKI Workflow

The typical PKI flow is:

1. Create the folder structure
2. Create the root CA
3. Issue one or more device certificates
4. Install the CA certificate into your trusted root store where needed

### Step 1: Create the PKI Folder Structure

```powershell
powershell -ExecutionPolicy Bypass -File .\pki-bootstrap.ps1
```

This creates:

- `pki/ca`
- `pki/certs`
- `pki/private`
- `pki/requests`
- `pki/devices`

### Step 2: Create the Root CA

```powershell
powershell -ExecutionPolicy Bypass -File .\create-ca.ps1
```

This generates:

- `pki/ca/myCA.key`: root CA private key
- `pki/ca/myCA.pem`: root CA certificate
- `pki/ca/ca.cnf`: CA OpenSSL config used during generation

The default CA subject in the script is:

- Country: `IE`
- State: `Wexford`
- Locality: `Wexford`
- Organization: `HomeLab`
- OU: `RootCA`
- Common Name: `HomeLab Root CA`

If you need different subject values, edit `create-ca.ps1` before running it.

### Step 3: Issue a Device Certificate

```powershell
powershell -ExecutionPolicy Bypass -File .\issue-cert.ps1 -DeviceName device.local -IPAddress 192.168.1.10
```

This generates a per-device folder under `pki/devices/<DeviceName>` with files such as:

- `device.key`
- `device.csr`
- `device.crt`
- `device.cnf`

The certificate includes both:

- DNS SAN for the device name
- IP SAN for the supplied IP address

## Export Examples

If you need a PKCS#12 bundle for import into Windows, browsers, reverse proxies, or appliances, you can export one from the generated device key and certificate.

Example:

```powershell
openssl pkcs12 -export `
  -out .\pki\devices\device.local\device.pfx `
  -inkey .\pki\devices\device.local\device.key `
  -in .\pki\devices\device.local\device.crt `
  -certfile .\pki\ca\myCA.pem
```

That command will prompt for an export password and create a `.pfx` file containing:

- The device private key
- The device certificate
- The CA certificate chain entry

You can also export DER format if a target system requires it:

```powershell
openssl x509 -outform der `
  -in .\pki\devices\device.local\device.crt `
  -out .\pki\devices\device.local\device.der
```

For verification, you can inspect the issued certificate with:

```powershell
openssl x509 -in .\pki\devices\device.local\device.crt -text -noout
```

## Security Notes

This repository handles sensitive material.

Generated files that should be treated as secret include:

- Private keys
- CSRs
- Issued certificates for internal services
- CA database and serial files
- Generated PKI config files

The `.gitignore` is configured to prevent these artifacts from being committed, including:

- Everything under `pki/`
- Generated OpenSSL build output
- Common certificate and key extensions
- VS Code workspace configuration

Even with `.gitignore`, you should avoid copying private keys into shared folders, chat tools, or tickets.

## Troubleshooting

### `nmake` not found

If the OpenSSL build script fails because `nmake` is missing, start an x64 Visual Studio Developer PowerShell or Developer Command Prompt and rerun the build. The script expects the Microsoft C/C++ build environment to already be initialized.

### `perl`, `nasm`, or `openssl` not found

The OpenSSL build script prepends these paths for the current process:

- `C:\Strawberry\perl\bin`
- `C:\Users\leigh\AppData\Local\bin\NASM`

If your tools are installed somewhere else, update `build-openssl-4.0.0.ps1`. If `openssl` is not available when running the PKI scripts, either add your OpenSSL install `bin` directory to `PATH` first or invoke the scripts from a shell where OpenSSL is already available.

### Certificates are not trusted

Creating the CA and device certs is not enough by itself. Systems will continue to reject the device certificate until the CA certificate is imported into the appropriate trusted root store.

On Windows, that usually means importing `pki/ca/myCA.pem` into the Trusted Root Certification Authorities store for the current user or local machine, depending on where the certificate will be consumed.

If a browser, client, or appliance still rejects the certificate, check:

- The CA certificate was imported into the correct trust store
- The device certificate SAN matches the hostname or IP you are connecting to
- The client received the correct leaf certificate and any required chain material

## Example End-to-End Usage

```powershell
powershell -ExecutionPolicy Bypass -File .\build-openssl-4.0.0.ps1
powershell -ExecutionPolicy Bypass -File .\pki-bootstrap.ps1
powershell -ExecutionPolicy Bypass -File .\create-ca.ps1
powershell -ExecutionPolicy Bypass -File .\issue-cert.ps1 -DeviceName router.lab.local -IPAddress 192.168.1.1
```

After that:

- Trust `pki/ca/myCA.pem` on the systems that need to trust your certificates
- Deploy the generated device certificate and private key to the target system as appropriate

## Notes About Tasks

The repository includes VS Code tasks for the OpenSSL build flow. If you want the PKI scripts wired into tasks as well, keep the task file aligned with the script locations in the repository.

## Future Improvements

Possible next steps for this repo:

- Make tool paths configurable instead of hardcoded
- Add export steps for PFX or DER outputs
- Add revocation list support
- Add per-environment CA profiles
- Add validation tasks to check certificate contents
