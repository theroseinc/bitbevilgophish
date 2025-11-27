#!/bin/bash
# Frameless BITB - One-Liner Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/waelmas/frameless-bitb/main/install.sh | sudo bash

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║     Frameless BITB - Automated Installer                     ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Install git if not present
if ! command -v git &> /dev/null; then
    echo -e "${GREEN}Installing Git...${NC}"
    apt update -qq
    apt install -y git &>/dev/null
fi

# Clone repository
INSTALL_DIR="/tmp/frameless-bitb-$$"
echo -e "${GREEN}Downloading Frameless BITB...${NC}"
git clone https://github.com/waelmas/frameless-bitb.git "$INSTALL_DIR" &>/dev/null

# Run setup script
cd "$INSTALL_DIR"
echo -e "${GREEN}Starting installation...${NC}"
echo ""
bash setup-gcloud.sh

# Cleanup
cd /
rm -rf "$INSTALL_DIR"

echo -e "${GREEN}Installation complete!${NC}"
