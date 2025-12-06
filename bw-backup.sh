#!/bin/bash

# === CONFIGURATION ===
CONTAINER_NAME="vaultwarden-bitwarden-1"
DATA_DIR="/mnt/docker/vaultwarden/bw-data"
BACKUP_DIR="/mnt/docker/vaultwarden/bw-backup"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
ARCHIVE_FILE="${BACKUP_DIR}/vaultwarden_backup_${TIMESTAMP}.7z"
TEMP_COPY="${BACKUP_DIR}/bw-data"

echo "Starting Vaultwarden backup..."
mkdir -p "$BACKUP_DIR"

# === STOP CONTAINER ===
echo "Stopping Vaultwarden container to ensure clean DB copy..."
docker stop "$CONTAINER_NAME"

# === COPY DATA DIR (INCLUDING SQLITE DB) ===
echo "Copying Vaultwarden data directory..."
rm -rf "$TEMP_COPY"         # clean previous temp data
cp -r "$DATA_DIR" "$TEMP_COPY"

# === START CONTAINER AGAIN ===
echo "Restarting Vaultwarden container..."
docker start "$CONTAINER_NAME"

# === COMPRESS WITH 7-ZIP (TIMESTAMPED ARCHIVE) ===
echo "Creating timestamped archive: $ARCHIVE_FILE"
7z a -t7z "$ARCHIVE_FILE" "$TEMP_COPY" >/dev/null

# === CLEAN UP TEMP BACKUP FOLDER ===
rm -rf "$TEMP_COPY"

echo "Backup completed successfully!"
echo "Backup file created: $ARCHIVE_FILE"
