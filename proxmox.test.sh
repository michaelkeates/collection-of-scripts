#!/bin/bash

echo "🔧 Proxmox CT Creation Script"

# Prompt for CTID
read -p "Enter a unique CTID (e.g., 101): " CTID

# Prompt for hostname
read -p "Enter a hostname for the container: " HOSTNAME

# Prompt for root filesystem size (only used with volume-based storage)
read -p "Enter root filesystem size (e.g., 4G): " ROOTFS_SIZE

# Storage to use (can change this to local-lvm if you have it)
STORAGE="local"  # Change to 'local-lvm' if desired
TEMPLATE="debian-bookworm-20231124_arm64.tar.xz"
TEMPLATE_PATH="/var/lib/vz/template/cache/$TEMPLATE"
MEMORY="512"
SWAP="512"
CORES="2"

# Check if template exists
if [[ ! -f "$TEMPLATE_PATH" ]]; then
  echo "❌ Template '$TEMPLATE' not found in $TEMPLATE_PATH"
  exit 1
fi

# Detect storage type (dir or lvm)
STORAGE_TYPE=$(pvesm status --storage "$STORAGE" 2>/dev/null | awk 'NR==2 {print $2}')

if [[ -z "$STORAGE_TYPE" ]]; then
  echo "❌ Could not detect storage type for '$STORAGE'. Check with: pvesm status"
  exit 1
fi

# Adjust --rootfs option based on storage type
if [[ "$STORAGE_TYPE" == "dir" ]]; then
  ROOTFS_OPT="--rootfs ${STORAGE}"
else
  ROOTFS_OPT="--rootfs ${STORAGE}:${ROOTFS_SIZE}"
fi

# Confirm configuration
echo -e "\n📦 Creating CT with the following configuration:"
echo "CTID         : $CTID"
echo "Hostname     : $HOSTNAME"
echo "Storage      : $STORAGE ($STORAGE_TYPE)"
echo "RootFS Size  : $ROOTFS_SIZE"
echo "Memory       : ${MEMORY}MB"
echo "Cores        : $CORES"
echo "Template     : $TEMPLATE"
echo

read -p "Proceed with creation? (y/n): " CONFIRM
[[ "$CONFIRM" != "y" ]] && echo "❌ Aborted." && exit 1

# Create the container
pct create "$CTID" "$TEMPLATE_PATH" \
  --arch arm64 \
  --hostname "$HOSTNAME" \
  $ROOTFS_OPT \
  --memory "$MEMORY" \
  --swap "$SWAP" \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --cores "$CORES" \
  --unprivileged 1

# Start the container
pct start "$CTID"

echo "✅ LXC container $CTID ($HOSTNAME) created and started."
