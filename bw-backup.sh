#!/bin/bash

# === LOAD PASSWORD FROM .env ===
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="/mnt/docker/vaultwarden/.env"

if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    echo "ERROR: .env file not found at $ENV_FILE"
    exit 1
fi

if [ -z "$BACKUP_PASSWORD" ]; then
    echo "ERROR: BACKUP_PASSWORD is not set in .env"
    exit 1
fi

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
echo "Stopping Vaultwarden container..."
docker stop "$CONTAINER_NAME"

# === COPY DATA DIRECTORY ===
echo "Copying Vaultwarden data..."
rm -rf "$TEMP_COPY"
cp -r "$DATA_DIR" "$TEMP_COPY"

# === START CONTAINER ===
echo "Restarting Vaultwarden container..."
docker start "$CONTAINER_NAME"

# === CREATE PASSWORD-PROTECTED ARCHIVE ===
echo "Compressing with password protection..."
7z a -t7z "$ARCHIVE_FILE" "$TEMP_COPY" -p"$BACKUP_PASSWORD" -mhe=on >/dev/null

# -pPASSWORD → sets archive password  
# -mhe=on    → encrypts file names as well (more secure)

# === CLEAN UP ===
rm -rf "$TEMP_COPY"

echo "Backup completed!"
echo "Archive created: $ARCHIVE_FILE"
