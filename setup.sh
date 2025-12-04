#!/bin/bash
# Complete setup script

set -e

echo "🚀 Starting complete setup for n8n + Supabase + Traefik..."

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Create network
echo -e "${YELLOW}🌐 Creating Docker network...${NC}"
docker network create shared-network 2>/dev/null || echo "✓ Network already exists"

# 2. Generate JWT secret if not exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}🔐 Creating .env file...${NC}"
    cp .env.example .env
    JWT_SECRET=$(openssl rand -base64 32)

    # Works on both Linux and macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|JWT_SECRET=your-jwt-secret-here|JWT_SECRET=$JWT_SECRET|g" .env
    else
        sed -i "s|JWT_SECRET=your-jwt-secret-here|JWT_SECRET=$JWT_SECRET|g" .env
    fi

    echo -e "${GREEN}✅ .env created with JWT secret!${NC}"
    echo -e "${YELLOW}⚠️  IMPORTANT: Edit .env file and update:${NC}"
    echo "   - POSTGRES_PASSWORD"
    echo "   - DOMAIN_NAME (your VPS IP or domain)"
    echo "   - N8N_USER and N8N_PASSWORD"
    echo "   - SSL_EMAIL"
    echo "   - ANON_KEY and SERVICE_ROLE_KEY (for production)"
    echo ""
    read -p "Press Enter after you've updated .env file..."
fi

# 3. Create necessary directories
echo -e "${YELLOW}📁 Creating volume directories...${NC}"
mkdir -p volumes/n8n volumes/postgres volumes/storage volumes/api volumes/traefik/letsencrypt volumes/traefik/logs

# Fix permissions for Let's Encrypt
touch volumes/traefik/letsencrypt/acme.json
chmod 600 volumes/traefik/letsencrypt/acme.json

# 4. Start Traefik
echo -e "${YELLOW}🔀 Starting Traefik reverse proxy...${NC}"
docker-compose -f docker-compose.traefik.yml up -d

# 5. Start PostgreSQL
echo -e "${YELLOW}🗄️  Starting PostgreSQL...${NC}"
docker-compose -f docker-compose.postgres.yml up -d

# 6. Wait for PostgreSQL
echo -e "${YELLOW}⏳ Waiting for PostgreSQL...${NC}"
until docker exec shared-postgres pg_isready -U postgres 2>/dev/null; do
  echo -n "."
  sleep 2
done
echo -e "${GREEN}✅ PostgreSQL is ready!${NC}"

# 7. Create databases
echo -e "${YELLOW}💾 Creating databases...${NC}"
docker exec shared-postgres psql -U postgres -c "CREATE DATABASE n8n;" 2>/dev/null || echo "n8n DB exists"
docker exec shared-postgres psql -U postgres -c "CREATE DATABASE supabase;" 2>/dev/null || echo "supabase DB exists"

# 8. Create Supabase schemas
echo -e "${YELLOW}📊 Creating Supabase schemas...${NC}"
docker exec shared-postgres psql -U postgres -d supabase -c "CREATE SCHEMA IF NOT EXISTS auth;" 2>/dev/null || true
docker exec shared-postgres psql -U postgres -d supabase -c "CREATE SCHEMA IF NOT EXISTS storage;" 2>/dev/null || true
docker exec shared-postgres psql -U postgres -d supabase -c "CREATE SCHEMA IF NOT EXISTS realtime;" 2>/dev/null || true

# 9. Start Supabase
echo -e "${YELLOW}🔧 Starting Supabase services...${NC}"
docker-compose -f docker-compose.supabase.yml up -d

# 10. Start n8n
echo -e "${YELLOW}⚙️  Starting n8n...${NC}"
docker-compose -f docker-compose.n8n.yml up -d

sleep 10

echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "📋 Service Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "🌐 Access URLs (via Traefik with automatic HTTPS):"
echo "   n8n:             https://n8n.$(grep DOMAIN_NAME .env | cut -d '=' -f2)"
echo "   Supabase Studio: https://supabase.$(grep DOMAIN_NAME .env | cut -d '=' -f2)"
echo "   Supabase API:    https://api.$(grep DOMAIN_NAME .env | cut -d '=' -f2)"
echo "   Traefik Dashboard: http://$(grep DOMAIN_NAME .env | cut -d '=' -f2):8080"
echo ""
echo "📝 Next steps:"
echo "   1. Ensure DNS records point to your server:"
echo "      n8n.$(grep DOMAIN_NAME .env | cut -d '=' -f2)"
echo "      supabase.$(grep DOMAIN_NAME .env | cut -d '=' -f2)"
echo "      api.$(grep DOMAIN_NAME .env | cut -d '=' -f2)"
echo "   2. Wait a few minutes for Let's Encrypt SSL certificates"
echo "   3. Open n8n and login with your N8N_USER/N8N_PASSWORD"
