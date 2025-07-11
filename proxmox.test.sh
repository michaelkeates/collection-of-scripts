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

# Prompt to start container
read -p "Do you want to start container $CTID now? (y/n): " START_CT
if [[ "$START_CT" =~ ^[Yy]$ ]]; then
  pct start "$CTID"
  echo "🚀 Container $CTID started."

  # Prompt to open shell inside container
  read -p "Do you want to open a shell inside container $CTID now? (y/n): " OPEN_SHELL
  if [[ "$OPEN_SHELL" =~ ^[Yy]$ ]]; then
    echo "🔑 Opening shell inside container $CTID..."
    pct enter "$CTID"
  else
    echo "⏸ Shell not opened."
  fi
else
  echo "⏸ Container $CTID not started."
fi

read -s -p "Enter root password for container: " ROOTPASS
echo
pct exec "$CTID" -- bash -c "echo 'root:$ROOTPASS' | chpasswd"
echo "✅ Root password set inside container."
