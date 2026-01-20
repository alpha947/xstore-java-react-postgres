#!/bin/bash
# Restore script for PostgreSQL database

if [ $# -eq 0 ]; then
    echo "Usage: ./restore-db.sh <backup-file>"
    echo "Example: ./restore-db.sh backups/stocky_db_20240120_120000.sql"
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
    # Try with .gz extension
    if [ -f "${BACKUP_FILE}.gz" ]; then
        BACKUP_FILE="${BACKUP_FILE}.gz"
    else
        echo "❌ Backup file not found: $BACKUP_FILE"
        exit 1
    fi
fi

echo "🔄 Restoring database from $BACKUP_FILE..."

# Decompress if needed
if [[ $BACKUP_FILE == *.gz ]]; then
    TEMP_FILE="${BACKUP_FILE%.gz}"
    gunzip -c "$BACKUP_FILE" > "$TEMP_FILE"
    BACKUP_FILE="$TEMP_FILE"
    CLEANUP=true
fi

# Restore database
docker-compose exec -T postgres psql -U stockyuser -d stockydb < "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Database restore successful!"
    
    if [ "$CLEANUP" = true ]; then
        rm "$BACKUP_FILE"
    fi
else
    echo "❌ Database restore failed!"
    exit 1
fi
