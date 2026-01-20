#!/bin/bash
# Backup script for PostgreSQL database

BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/stocky_db_$TIMESTAMP.sql"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "🔄 Backing up PostgreSQL database..."

# Perform backup
docker-compose exec -T postgres pg_dump -U stockyuser -d stockydb > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Backup successful: $BACKUP_FILE"
    
    # Optional: Compress the backup
    gzip "$BACKUP_FILE"
    echo "📦 Backup compressed: ${BACKUP_FILE}.gz"
else
    echo "❌ Backup failed!"
    exit 1
fi

# Optional: Delete backups older than 7 days
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +7 -delete
echo "🗑️  Old backups cleaned (older than 7 days)"
