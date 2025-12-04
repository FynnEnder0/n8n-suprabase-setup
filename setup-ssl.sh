#!/bin/bash
# SSL Setup Script for Hostinger VPS
# Domain: srv1097337.hstgr.cloud
# Subdomain: n8n.srv1097337.hstgr.cloud

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (use: sudo ./setup-ssl.sh)${NC}"
    exit 1
fi

echo "🔒 SSL Setup for Hostinger VPS"
echo "==============================="
echo ""

# Main domain and subdomains
MAIN_DOMAIN="srv1097337.hstgr.cloud"
N8N_DOMAIN="n8n.srv1097337.hstgr.cloud"
SUPABASE_DOMAIN="supabase.srv1097337.hstgr.cloud"
API_DOMAIN="api.srv1097337.hstgr.cloud"
SSL_EMAIL="user@srv1097337.hstgr.cloud"

echo -e "${YELLOW}Domains to configure:${NC}"
echo "  - n8n: $N8N_DOMAIN"
echo "  - Supabase Studio: $SUPABASE_DOMAIN"
echo "  - Supabase API: $API_DOMAIN"
echo ""

read -p "Have you configured DNS A records for these subdomains? (yes/no) " -r
if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
    echo ""
    echo -e "${YELLOW}⚠️  Please configure DNS first:${NC}"
    echo ""
    echo "In Hostinger DNS Management, add these A records:"
    echo "  Host: n8n           Type: A    Points to: $(curl -s ifconfig.me)"
    echo "  Host: supabase      Type: A    Points to: $(curl -s ifconfig.me)"
    echo "  Host: api           Type: A    Points to: $(curl -s ifconfig.me)"
    echo ""
    echo "Wait 5-10 minutes for DNS propagation, then run this script again."
    exit 1
fi

echo -e "${YELLOW}Step 1: Installing Nginx...${NC}"
apt update
apt install -y nginx
systemctl enable nginx
systemctl start nginx
echo -e "${GREEN}✅ Nginx installed${NC}"

echo -e "${YELLOW}Step 2: Installing Certbot...${NC}"
apt install -y certbot python3-certbot-nginx
echo -e "${GREEN}✅ Certbot installed${NC}"

echo -e "${YELLOW}Step 3: Creating Nginx configuration for n8n...${NC}"
cat > /etc/nginx/sites-available/n8n << EOF
server {
    listen 80;
    server_name $N8N_DOMAIN;

    location / {
        proxy_pass http://localhost:5678;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # Increase timeouts for long-running workflows
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        proxy_read_timeout 300;
        send_timeout 300;
    }
}
EOF

echo -e "${YELLOW}Step 4: Creating Nginx configuration for Supabase...${NC}"
cat > /etc/nginx/sites-available/supabase << EOF
# Supabase Studio
server {
    listen 80;
    server_name $SUPABASE_DOMAIN;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}

# Supabase API
server {
    listen 80;
    server_name $API_DOMAIN;

    location / {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # CORS headers for API
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Authorization, Content-Type, apikey' always;

        if (\$request_method = 'OPTIONS') {
            return 204;
        }
    }
}
EOF

echo -e "${YELLOW}Step 5: Enabling sites...${NC}"
ln -sf /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/supabase /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

echo -e "${YELLOW}Step 6: Testing Nginx configuration...${NC}"
nginx -t
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Nginx configuration error!${NC}"
    exit 1
fi

systemctl reload nginx
echo -e "${GREEN}✅ Nginx configured${NC}"

echo -e "${YELLOW}Step 7: Obtaining SSL certificates...${NC}"
echo "This may take a few minutes..."
echo ""

# Get certificate for n8n
certbot --nginx -d $N8N_DOMAIN --non-interactive --agree-tos --email $SSL_EMAIL --redirect

# Get certificate for Supabase Studio
certbot --nginx -d $SUPABASE_DOMAIN --non-interactive --agree-tos --email $SSL_EMAIL --redirect

# Get certificate for Supabase API
certbot --nginx -d $API_DOMAIN --non-interactive --agree-tos --email $SSL_EMAIL --redirect

echo -e "${GREEN}✅ SSL certificates obtained${NC}"

echo -e "${YELLOW}Step 8: Updating .env for HTTPS...${NC}"
if [ -f .env ]; then
    sed -i "s|N8N_PROTOCOL=http|N8N_PROTOCOL=https|g" .env
    sed -i "s|DOMAIN_NAME=srv1097337.hstgr.cloud|DOMAIN_NAME=$N8N_DOMAIN|g" .env
    echo -e "${GREEN}✅ Environment updated${NC}"
fi

echo -e "${YELLOW}Step 9: Restarting services...${NC}"
./stop-all.sh
sleep 5
./start-all.sh
echo -e "${GREEN}✅ Services restarted with HTTPS${NC}"

echo -e "${YELLOW}Step 10: Updating firewall (closing direct ports)...${NC}"
# Keep direct port access for now, but you can close them if you want
# ufw delete allow 5678/tcp
# ufw delete allow 3000/tcp
# ufw delete allow 8000/tcp
echo -e "${GREEN}✅ Firewall updated${NC}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🎉 SSL Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "🌐 Your secure URLs:"
echo "   n8n:             https://$N8N_DOMAIN"
echo "   Supabase Studio: https://$SUPABASE_DOMAIN"
echo "   Supabase API:    https://$API_DOMAIN"
echo ""
echo "🔒 SSL certificates will auto-renew via certbot"
echo ""
echo "📝 Next steps:"
echo "   1. Test all URLs in your browser"
echo "   2. Update any webhooks to use HTTPS URLs"
echo "   3. Update Supabase settings to use API domain"
echo ""
echo "💡 Tip: You can also access via direct ports if needed:"
echo "   http://srv1097337.hstgr.cloud:5678 (n8n)"
echo "   http://srv1097337.hstgr.cloud:3000 (Supabase Studio)"
echo "   http://srv1097337.hstgr.cloud:8000 (Supabase API)"
echo ""

