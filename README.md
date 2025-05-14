# 💻 Shell Script - Vaultwarden-Installation.sh

This script was developed to automate the deployment of Vaultwarden — an open-source password manager.
It includes everything needed to get Vaultwarden up and running securely and efficiently.

🔐 What it does:

Automatically installs and configures Vaultwarden

Generates a self-signed SSL certificate

Sets up and configures a reverse proxy to serve Vaultwarden over HTTPS

Ideal for users who want a fast, secure, and repeatable way to deploy their own password vault with minimal manual setup.

⚠️ Make sure to run the script on a clean or controlled environment.
🛡️ Root privileges may be required for installing packages and setting up services.

---
# 🔐 Vaultwarden Installation Script

**Vaultwarden-Installation.sh** is a Shell script developed to fully automate the secure deployment of [Vaultwarden](https://github.com/dani-garcia/vaultwarden), an open-source password manager.

It includes:

- Docker and Vaultwarden installation
- SSL certificate generation via OpenSSL
- Reverse proxy setup with Nginx
- Admin token creation using Argon2 encryption

> ✅ Designed for quick and secure deployments in self-hosted environments.

---

## 📦 Requirements

- Ubuntu
- Root privileges
- A domain or subdomain pointing to your server (e.g., `vault.example.local`)

---

## 🚀 How to Use

### 1. **Clone this Repository**

```bash
git clone https://github.com/rihanalkamim/Install-Vaultwarden.git
```
```bash
cd Install-Vaultwarden
```

---

### 2. **Run the Script**

```bash
sudo ./Vaultwarden-Installation.sh
```

---

### 3. **Provide the Required Information**

You’ll be prompted to enter:

- Your domain (e.g., `vault.example.local`)
- Certificate fields (country, state, city, organization, etc.)
- A password to encrypt the CA private key
                        
**OBS**: This password also used of Vaultwarden token

Example:
```
Your domain (Ex: intern.domain) [*]: vault.example.local
Country Name (Ex: US) [Default: "AU"]:
State or Province (Ex: Georgia) [Default: "N/A"]:
...
```

---

## 🔧 What It Does

- 📥 Updates system and installs dependencies
- 🔐 Prompts for a secure password (used to encrypt private key)
- 🔑 Creates a self-signed Root CA and server certificate
- 🐳 Creates and launches the Vaultwarden Docker container
- 🌐 Configures Nginx as a secure HTTPS reverse proxy

---

## 📂 Files and Structure

```
/Vaultwarden
├── Cert/
│   ├── fullchain.pem
│   ├── vault.yourdomain.local.key
│   └── vault.yourdomain.local.pem
├── compose.yaml
├── vw-data/ (Docker volume)
```

---

## 🧪 After Installation

- Open your browser and go to: `https://vault.your.domain`
- Access the admin panel using the generated **ADMIN_TOKEN**

---

## ❗ Troubleshooting

- Check Nginx config: `sudo nginx -t`
- Restart Docker services: `docker-compose restart`
- Check Vaultwarden logs: `docker-compose logs vaultwarden`

---

## 🙋 Support

Questions or suggestions?  
Open an issue on GitHub or contact me at:

📧 **rihanalkamim@gmail.com**  
🔗 [github.com/rihanalkamim/Install-Vaultwarden](https://github.com/rihanalkamim/Install-Vaultwarden)



