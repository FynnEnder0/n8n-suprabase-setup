#!/bin/bash

BACKUP_DIR="backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

echo "💾 Creating backups..."

echo "📦 PostgreSQL backup..."
docker exec shared-postgres pg_dumpall -U postgres > "$BACKUP_DIR/postgres_$DATE.sql"

echo "⚙️  n8n backup..."
tar -czf "$BACKUP_DIR/n8n_$DATE.tar.gz" volumes/n8n/ 2>/dev/null || true

echo "🗄️  Storage backup..."
tar -czf "$BACKUP_DIR/storage_$DATE.tar.gz" volumes/storage/ 2>/dev/null || true

echo "✅ Backup completed: $BACKUP_DIR/"
ls -lh $BACKUP_DIR/
