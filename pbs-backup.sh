#!/bin/bash

# PBS connection info
REPO="root@pam@192.168.1.86:backup"
STORAGE="pbs"

# Log file (optional)
LOGFILE="/var/log/pbs-backup.log"

# Timestamp
echo "[$(date)] Starting backup check..." >> "$LOGFILE"

# Check PBS connection
if proxmox-backup-client ping --repository "$REPO" > /dev/null 2>&1; then
    echo "[$(date)] PBS reachable. Starting vzdump..." >> "$LOGFILE"
    vzdump --all --storage "$STORAGE" --mode snapshot --compress zstd --remove 0 >> "$LOGFILE" 2>&1
    echo "[$(date)] Backup completed." >> "$LOGFILE"
else
    echo "[$(date)] PBS NOT reachable. Backup skipped." >> "$LOGFILE"
fi
