#!/bin/bash
# Quick deployment script for Hostinger VPS or any Ubuntu VPS
# Configured for: srv1097337.hstgr.cloud

set -e

echo "🚀 VPS Deployment Script for n8n + Supabase"
echo "============================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (use: sudo ./deploy-to-vps.sh)${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 1: Installing Docker...${NC}"
if ! command -v docker &> /dev/null; then
    apt update
    apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io
    systemctl start docker
    systemctl enable docker
    echo -e "${GREEN}✅ Docker installed${NC}"
else
    echo -e "${GREEN}✅ Docker already installed${NC}"
fi

echo -e "${YELLOW}Step 2: Installing Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}✅ Docker Compose installed${NC}"
else
    echo -e "${GREEN}✅ Docker Compose already installed${NC}"
fi

echo -e "${YELLOW}Step 3: Configuring firewall...${NC}"
if command -v ufw &> /dev/null; then
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw allow 5678/tcp
    ufw allow 3000/tcp
    ufw allow 8000/tcp
    ufw --force enable
    echo -e "${GREEN}✅ Firewall configured${NC}"
else
    apt install -y ufw
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw allow 5678/tcp
    ufw allow 3000/tcp
    ufw allow 8000/tcp
    ufw --force enable
    echo -e "${GREEN}✅ Firewall installed and configured${NC}"
fi

echo -e "${YELLOW}Step 4: Getting VPS domain...${NC}"
VPS_DOMAIN="srv1097337.hstgr.cloud"
echo -e "${GREEN}✅ Your VPS domain: $VPS_DOMAIN${NC}"

echo -e "${YELLOW}Step 5: Creating Docker network...${NC}"
docker network create shared-network 2>/dev/null || echo "✓ Network already exists"
echo -e "${GREEN}✅ Docker network ready${NC}"

echo -e "${YELLOW}Step 6: Setting up environment...${NC}"
if [ ! -f .env ]; then
    cp .env.example .env

    # Generate secure passwords
    POSTGRES_PASS=$(openssl rand -base64 24)
    N8N_PASS=$(openssl rand -base64 16)
    N8N_ENCRYPTION=$(openssl rand -base64 32)
    JWT_SECRET=$(openssl rand -base64 32)

    sed -i "s|POSTGRES_PASSWORD=changeme123|POSTGRES_PASSWORD=$POSTGRES_PASS|g" .env
    sed -i "s|N8N_PASSWORD=changeme123|N8N_PASSWORD=$N8N_PASS|g" .env
    sed -i "s|N8N_ENCRYPTION_KEY=|N8N_ENCRYPTION_KEY=$N8N_ENCRYPTION|g" .env
    sed -i "s|JWT_SECRET=your-jwt-secret-here|JWT_SECRET=$JWT_SECRET|g" .env
    sed -i "s|DOMAIN_NAME=n8n.srv1097337.hstgr.cloud|DOMAIN_NAME=$VPS_DOMAIN|g" .env

    echo -e "${GREEN}✅ Environment configured with secure passwords${NC}"
    echo ""
    echo -e "${YELLOW}📝 Your credentials (SAVE THESE):${NC}"
    echo "================================================"
    echo "PostgreSQL Password: $POSTGRES_PASS"
    echo "n8n Username: admin"
    echo "n8n Password: $N8N_PASS"
    echo "================================================"
    echo ""
    echo -e "${YELLOW}⚠️  IMPORTANT: Screenshot or copy these credentials!${NC}"
    echo "They are also saved in the .env file"
    echo ""
    sleep 10
else
    echo -e "${GREEN}✅ .env file already exists${NC}"
fi

echo -e "${YELLOW}Step 7: Running setup...${NC}"
chmod +x setup.sh start-all.sh stop-all.sh backup.sh
./setup.sh

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "🌐 Access your services at:"
echo "   n8n:             http://$VPS_DOMAIN:5678"
echo "   Supabase Studio: http://$VPS_DOMAIN:3000"
echo "   Supabase API:    http://$VPS_DOMAIN:8000"
echo ""
echo "📝 Login credentials:"
echo "   Username: admin"
echo "   Password: (check .env file: N8N_PASSWORD)"
echo ""
echo "🔒 Next steps for production:"
echo "   1. Setup subdomain DNS: n8n.srv1097337.hstgr.cloud"
echo "   2. Run: sudo ./setup-ssl.sh (to enable HTTPS)"
echo "   3. See HOSTINGER_DEPLOYMENT.md for details"
echo ""
echo "🔄 Management commands:"
echo "   Start:  ./start-all.sh"
echo "   Stop:   ./stop-all.sh"
echo "   Backup: ./backup.sh"
echo ""
