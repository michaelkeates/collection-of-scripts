#!/bin/bash

echo "✅ Script is running."

# Ensure script is run as root
if [[ "$EUID" -ne 0 ]]; then
  echo "❌ Please run this script as root or with sudo."
  exit 1
fi

# Update system
apt update
apt upgrade -y

# Prompt for CTID, hostname, rootfs size
read -p "Enter CTID (numeric): " CTID
read -p "Enter hostname: " HOSTNAME
read -p "Enter rootfs size (in GB, e.g. 32): " ROOTFS_SIZE
read -p "Enter memory size (in MB, default 512): " MEMORY
MEMORY=${MEMORY:-512}
read -p "Enter swap size (in MB, default 512): " SWAP
SWAP=${SWAP:-512}

# Create LXC container
pct create "$CTID" local:vztmpl/debian-bookworm-20231124_arm64.tar.xz \
  --cores 1 \
  --features nesting=1 \
  --hostname "$HOSTNAME" \
  --memory "$MEMORY" \
  --net0 name=eth0,bridge=vmbr0,firewall=1 \
  --rootfs local:"$ROOTFS_SIZE" \
  --swap "$SWAP" \
  --unprivileged 1

echo "✅ Container $CTID ($HOSTNAME) created successfully."
