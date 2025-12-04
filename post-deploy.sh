#!/bin/bash
# Post-deployment hook for Hostinger
# This script initializes databases after containers are up

set -e

echo "⏳ Waiting for PostgreSQL to be ready..."
sleep 10

# Wait for PostgreSQL to be healthy
until docker exec shared-postgres pg_isready -U postgres 2>/dev/null; do
  echo -n "."
  sleep 2
done

echo ""
echo "💾 Creating databases..."
docker exec shared-postgres psql -U postgres -c "CREATE DATABASE n8n;" 2>/dev/null || echo "✓ n8n DB exists"
docker exec shared-postgres psql -U postgres -c "CREATE DATABASE supabase;" 2>/dev/null || echo "✓ supabase DB exists"

echo "📊 Creating Supabase schemas..."
docker exec shared-postgres psql -U postgres -d supabase -c "CREATE SCHEMA IF NOT EXISTS auth;" 2>/dev/null || true
docker exec shared-postgres psql -U postgres -d supabase -c "CREATE SCHEMA IF NOT EXISTS storage;" 2>/dev/null || true
docker exec shared-postgres psql -U postgres -d supabase -c "CREATE SCHEMA IF NOT EXISTS realtime;" 2>/dev/null || true

echo "✅ Post-deployment complete"
echo ""
echo "🌐 Your services should now be accessible at:"
echo "   n8n:             http://your-domain:5678"
echo "   Supabase Studio: http://your-domain:3000"
echo "   Supabase API:    http://your-domain:8000"
#!/bin/bash
# Pre-deployment hook for Hostinger
# This script ensures the shared network exists before docker-compose runs

set -e

echo "🔧 Pre-deployment: Creating shared Docker network..."
docker network create shared-network 2>/dev/null && echo "✅ Network created" || echo "✅ Network already exists"

echo "📁 Creating volume directories..."
mkdir -p volumes/n8n volumes/postgres volumes/storage volumes/api

echo "✅ Pre-deployment complete"

