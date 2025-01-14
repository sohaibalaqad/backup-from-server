#!/bin/bash

# Configuration
BACKUP_DIR="/home/backups"
WEB_DIR="/data/www/new.massarpal.org"
DB_NAME="massar"
LOG_FILE="$BACKUP_DIR/backup_log.txt"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# Email Configuration
EMAIL="your_email@example.com"
EMAIL_SUBJECT="Backups resulte - $TIMESTAMP"
log_summary=""

# Create required directories if not exists
mkdir -p "$BACKUP_DIR/daily" "$BACKUP_DIR/weekly" "$BACKUP_DIR/monthly"

# Secure directory permissions
chmod 700 "$BACKUP_DIR"


# Backup web server files (rsync for efficiency)
rsync -a --delete --exclude='cache/' --exclude='tmp/' "$WEB_DIR" "$BACKUP_DIR/daily/web_backup_$TIMESTAMP" > /dev/null 2>&1
if [ $? -eq 0 ]; then
   message="$TIMESTAMP: Web files backup successful"
else
  message="$TIMESTAMP: Web files backup failed"
fi
echo "$message" >> "$LOG_FILE"
log_summary+="$message\n"


# Backup database securely using .my.cnf
mysqldump --defaults-file=~/.my.cnf "$DB_NAME" | gzip > "$BACKUP_DIR/daily/db_backup_$TIMESTAMP.sql.gz"
if [ $? -eq 0 ]; then
  message="$TIMESTAMP: Database backup successful"
else
  message="$TIMESTAMP: Database backup failed"
fi
echo "$message" >> "$LOG_FILE"
log_summary+="$message\n"


# Rotate backups
# Keep last 7 daily backups
find "$BACKUP_DIR/daily" -type f -mtime +7 -exec rm -f {} \;
message="$TIMESTAMP: Old daily backups rotated"
echo "$message" >> "$LOG_FILE"
log_summary+="$message\n"


# Weekly backup every Friday
if [ "$(date +%u)" -eq 5 ]; then
  cp -al "$BACKUP_DIR/daily/web_backup_$TIMESTAMP" "$BACKUP_DIR/weekly/"
  cp -al "$BACKUP_DIR/daily/db_backup_$TIMESTAMP.sql.gz" "$BACKUP_DIR/weekly/"
  message="$TIMESTAMP: Weekly backup created"
  echo "$message" >> "$LOG_FILE"
  log_summary+="$message\n"
fi


# Monthly backup on the 1st of each month
if [ "$(date +%d)" -eq 1 ]; then
  cp -al "$BACKUP_DIR/daily/web_backup_$TIMESTAMP" "$BACKUP_DIR/monthly/"
  cp -al "$BACKUP_DIR/daily/db_backup_$TIMESTAMP.sql.gz" "$BACKUP_DIR/monthly/"
  message="$TIMESTAMP: Monthly backup created"
  echo "$message" >> "$LOG_FILE"
  log_summary+="$message\n"
fi


# Send email with the summary
echo -e "$log_summary" | mail -s "$EMAIL_SUBJECT" "$EMAIL"

exit 0