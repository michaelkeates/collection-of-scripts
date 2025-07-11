#!/bin/bash

PBS_IP="192.168.1.86"
PBS_PORT=8007
STORAGE="backup"
LOGFILE="/var/log/pbs-backup.log"

echo "[$(date)] Checking PBS port ${PBS_PORT} on ${PBS_IP}..." >> "$LOGFILE"

if timeout 3 bash -c "echo > /dev/tcp/$PBS_IP/$PBS_PORT" 2>/dev/null; then
    echo "[$(date)] PBS is reachable. Starting vzdump..." >> "$LOGFILE"
    vzdump --all --storage "$STORAGE" --mode snapshot --compress zstd --remove 0 >> "$LOGFILE" 2>&1
    echo "[$(date)] Backup completed." >> "$LOGFILE"
else
    echo "[$(date)] PBS not reachable on port $PBS_PORT. Backup skipped." >> "$LOGFILE"
fi
