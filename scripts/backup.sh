#!/bin/bash
# Daily backup for n8n ONLY. Writes exclusively to /opt/n8n/backups.
# Does not touch any other project's data or backups.
# Deploy to /opt/n8n/backup.sh (chmod 700, root). Cron: /etc/cron.d/n8n-backup
set -euo pipefail
BK=/opt/n8n/backups
TS=$(date +%Y%m%d-%H%M%S)
mkdir -p "$BK"
# 1) n8n Postgres database (custom format, compressed) via peer-auth postgres user
runuser -u postgres -- pg_dump -Fc n8n > "$BK/n8n-db-$TS.dump"
# 2) n8n data dir (.n8n) + encryption key (.env) so a restore is self-contained
tar -czf "$BK/n8n-data-$TS.tar.gz" -C /opt/n8n data .env 2>/dev/null
# 3) retention: keep 14 days
find "$BK" -maxdepth 1 -name 'n8n-db-*.dump'      -mtime +14 -delete
find "$BK" -maxdepth 1 -name 'n8n-data-*.tar.gz'  -mtime +14 -delete
echo "$(date -Is) backup ok: n8n-db-$TS.dump + n8n-data-$TS.tar.gz" >> "$BK/backup.log"
