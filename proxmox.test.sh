#!/bin/bash

echo "🔧 Proxmox CT Creation Script"

# Prompt for CTID
read -p "Enter a unique CTID (e.g., 101): " CTID

# Prompt for hostname
read -p "Enter a hostname for the container: " HOSTNAME

# Prompt for rootfs size
read -p "Enter root filesystem size (e.g., 4G): " ROOTFS_SIZE

# Fixed values (can be changed or also prompted for)
TEMPLATE="debian-bookworm-20231124_arm64.tar.xz"
TEMPLATE_PATH="/var/lib/vz/template/cache/$TEMPLATE"
STORAGE="local"
MEMORY="512"
SWAP="512"
CORES="2"

# Check if template exists
if [[ ! -f "$TEMPLATE_PATH" ]]; then
  echo "❌ Template '$TEMPLATE' not found in $TEMPLATE_PATH"
  exit 1
fi

# Confirm details
echo -e "\n📦 Creating CT with the following configuration:"
echo "CTID:         $CTID"
echo "Hostname:     $HOSTNAME"
echo "RootFS Size:  $ROOTFS_SIZE"
echo "Template:     $TEMPLATE"
echo "Storage:      $STORAGE"
echo "Memory:       ${MEMORY}MB"
echo "Cores:        $CORES"
echo

read -p "Proceed with creation? (y/n): " CONFIRM
[[ "$CONFIRM" != "y" ]] && echo "❌ Aborted." && exit 1

# Create the container
pct create "$CTID" "$TEMPLATE_PATH" \
  --arch arm64 \
  --hostname "$HOSTNAME" \
  --storage "$STORAGE" \
  --rootfs "${STORAGE}:${ROOTFS_SIZE}" \
  --memory "$MEMORY" \
  --swap "$SWAP" \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --cores "$CORES" \
  --unprivileged 1

# Start the container
pct start "$CTID"

echo "✅ LXC container $CTID ($HOSTNAME) created and started."
