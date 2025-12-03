#!/bin/bash

echo "🛑 Stopping all services..."

docker-compose -f docker-compose.n8n.yml down
docker-compose -f docker-compose.supabase.yml down
docker-compose -f docker-compose.postgres.yml down

echo "✅ All services stopped!"
