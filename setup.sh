#!/bin/bash
# Complete setup script

set -e

echo "🚀 Starting complete setup for n8n + Supabase..."

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Create network
echo -e "${YELLOW}🌐 Creating Docker network...${NC}"
docker network create shared-network 2>/dev/null || echo "Network already exists"

# 2. Generate JWT secret if not exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}🔐 Creating .env file...${NC}"
    cp .env.example .env
    JWT_SECRET=$(openssl rand -base64 32)
    sed -i "s|JWT_SECRET=your-jwt-secret-here|JWT_SECRET=$JWT_SECRET|g" .env
    echo "✅ .env created. Please edit it with your passwords!"
fi

# 3. Start PostgreSQL
echo -e "${YELLOW}🗄️  Starting PostgreSQL...${NC}"
docker-compose -f docker-compose.postgres.yml up -d

# 4. Wait for PostgreSQL
echo -e "${YELLOW}⏳ Waiting for PostgreSQL...${NC}"
until docker exec shared-postgres pg_isready -U postgres 2>/dev/null; do
  echo -n "."
  sleep 2
done
echo -e "${GREEN}✅ PostgreSQL is ready!${NC}"

# 5. Create databases
echo -e "${YELLOW}💾 Creating databases...${NC}"
docker exec shared-postgres psql -U postgres -c "CREATE DATABASE n8n;" 2>/dev/null || echo "n8n DB exists"
docker exec shared-postgres psql -U postgres -c "CREATE DATABASE supabase;" 2>/dev/null || echo "supabase DB exists"

# 6. Create Supabase schemas
echo -e "${YELLOW}📊 Creating Supabase schemas...${NC}"
docker exec shared-postgres psql -U postgres -d supabase -c "CREATE SCHEMA IF NOT EXISTS auth;" 2>/dev/null || true
docker exec shared-postgres psql -U postgres -d supabase -c "CREATE SCHEMA IF NOT EXISTS storage;" 2>/dev/null || true
docker exec shared-postgres psql -U postgres -d supabase -c "CREATE SCHEMA IF NOT EXISTS realtime;" 2>/dev/null || true

# 7. Start Supabase
echo -e "${YELLOW}🔧 Starting Supabase services...${NC}"
docker-compose -f docker-compose.supabase.yml up -d

# 8. Start n8n
echo -e "${YELLOW}⚙️  Starting n8n...${NC}"
docker-compose -f docker-compose.n8n.yml up -d

sleep 10

echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "📋 Service Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "🌐 Access URLs:"
echo "   n8n:            https://your-domain:5678"
echo "   Supabase Studio: http://your-domain:3000"
echo "   Supabase API:    http://your-domain:8000"
