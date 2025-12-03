#!/bin/bash
set -e

echo "🚀 Starting all services..."

echo "📦 Starting PostgreSQL..."
docker-compose -f docker-compose.postgres.yml up -d

echo "⏳ Waiting for PostgreSQL..."
until docker exec shared-postgres pg_isready -U postgres 2>/dev/null; do
  sleep 2
done

echo "🔧 Starting Supabase..."
docker-compose -f docker-compose.supabase.yml up -d

echo "⚙️  Starting n8n..."
docker-compose -f docker-compose.n8n.yml up -d

echo "✅ All services started!"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
