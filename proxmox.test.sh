#!/bin/bash

echo "✅ Script is running."

# Ensure script is run as root
if [[ "$EUID" -ne 0 ]]; then
  echo "❌ Please run this script as root or with sudo."
  exit 1
fi

update_host() {
  apt update
  apt upgrade -y
}

prompt_container_details() {
  read -p "Enter CTID (numeric): " CTID
  read -p "Enter hostname: " HOSTNAME
  read -p "Enter number of CPU cores to assign (default 1): " CORES
  CORES=${CORES:-1}
  read -p "Enter rootfs size (in GB, e.g. 32): " ROOTFS_SIZE
  read -p "Enter memory size (in MB, default 512): " MEMORY
  MEMORY=${MEMORY:-512}
  read -p "Enter swap size (in MB, default 512): " SWAP
  SWAP=${SWAP:-512}
  read -s -p "Enter root password for container: " ROOTPASS
  echo
}

create_container() {
  pct create "$CTID" local:vztmpl/debian-bookworm-20231124_arm64.tar.xz \
    --cores "$CORES" \
    --features nesting=1 \
    --hostname "$HOSTNAME" \
    --memory "$MEMORY" \
    --net0 name=eth0,bridge=vmbr0,firewall=1 \
    --rootfs local:"$ROOTFS_SIZE" \
    --swap "$SWAP" \
    --unprivileged 1

  echo "✅ Container $CTID ($HOSTNAME) created successfully."
}

add_mount_points() {
  MOUNT_INDEX=0
  while true; do
    read -p "Do you want to add a mount point? (y/n): " ADD_MOUNT
    if [[ "$ADD_MOUNT" =~ ^[Yy]$ ]]; then
      read -p "Enter host directory to mount (e.g. /mnt/data): " HOST_MOUNT
      read -p "Enter container mount path (e.g. /mnt/data): " CT_MOUNT

      if [[ -d "$HOST_MOUNT" ]]; then
        echo "🔗 Adding mount point mp$MOUNT_INDEX..."
        pct set "$CTID" -mp$MOUNT_INDEX "$HOST_MOUNT",mp="$CT_MOUNT"
        echo "✅ Mount point added: $HOST_MOUNT → $CT_MOUNT (mp$MOUNT_INDEX)"
        ((MOUNT_INDEX++))
      else
        echo "❌ Host directory does not exist: $HOST_MOUNT"
      fi
    else
      break
    fi
  done
}

start_and_configure_container() {
  read -p "Do you want to start container $CTID ($HOSTNAME) now? (y/n): " START_CT
  if [[ "$START_CT" =~ ^[Yy]$ ]]; then
    pct start "$CTID"
    echo "🚀 Container $CTID started."
    sleep 4

    echo "🔐 Setting root password inside the container..."
    pct exec "$CTID" -- bash -c "echo 'root:$ROOTPASS' | chpasswd"
    sleep 4

    echo "🔐 Enabling dhclient..."
    pct exec "$CTID" -- bash -c "dhclient"
    sleep 4

    echo "📦 Running apt update & upgrade inside the container..."
    pct exec "$CTID" -- bash -c "apt update && apt upgrade -y"

    create_user_inside_container

    read -p "Do you want to install Docker inside the container? (y/n): " INSTALL_DOCKER
    if [[ "$INSTALL_DOCKER" =~ ^[Yy]$ ]]; then
      install_docker
    else
      echo "🐳 Skipping Docker installation."
    fi

    read -p "Do you want to install Samba inside the container? (y/n): " INSTALL_SAMBA
    if [[ "$INSTALL_SAMBA" =~ ^[Yy]$ ]]; then
      install_samba
    else
      echo "Skipping Samba installation."
    fi

    offer_shell_access
  else
    echo "⏸ Container $CTID not started."
  fi
}

create_user_inside_container() {
  read -p "👤 Enter username to create inside container: " NEWUSER
  read -s -p "🔑 Enter password for $NEWUSER: " USERPASS
  echo

  echo "👤 Creating user '$NEWUSER' inside container $CTID ($HOSTNAME)..."
  pct exec "$CTID" -- bash -c "
    if id \"$NEWUSER\" &>/dev/null; then
      echo '⚠️ User \"$NEWUSER\" already exists.'
    else
      adduser --disabled-password --gecos \"\" \"$NEWUSER\"
      echo \"$NEWUSER:$USERPASS\" | chpasswd
      usermod -aG sudo \"$NEWUSER\"
      echo '✅ User \"$NEWUSER\" created and added to sudo group.'
    fi
  "
}

install_docker() {
  echo "🐳 Installing Docker inside container as root..."
  pct exec "$CTID" -- bash -c "apt install -y curl"
  pct exec "$CTID" -- bash -c "curl -fsSL https://get.docker.com | sh"

  echo "👥 Adding $NEWUSER to docker group..."
  pct exec "$CTID" -- bash -c "usermod -aG docker $NEWUSER"

  echo "✅ Docker installed and $NEWUSER added to docker group."
}

install_samba() {
  echo "Installing Samba inside container as root..."
  pct exec "$CTID" -- bash -c "apt update && apt install -y samba curl"

  echo "Backing up smb.conf (only if no .bak exists)..."
  pct exec "$CTID" -- bash -c "[ -f /etc/samba/smb.conf.bak ] || cp /etc/samba/smb.conf /etc/samba/smb.conf.bak"

  echo "Replacing smb.conf from GitHub..."
  pct exec "$CTID" -- bash -c "curl -fsSL https://raw.githubusercontent.com/michaelkeates/collection-of-scripts/main/smb.conf -o /etc/samba/smb.conf"

  echo "👥 Setting $NEWUSER password for Samba..."
  pct exec "$CTID" -- bash -c "smbpasswd -a $NEWUSER"

  echo "Enable Samba services..."
  pct exec "$CTID" -- bash -c "systemctl enable smbd"
  sleep 4
  pct exec "$CTID" -- bash -c "systemctl enable nmbd"
  sleep 4

  echo "Restart Samba services..."
  pct exec "$CTID" -- bash -c "systemctl restart smbd"
  sleep 4
  pct exec "$CTID" -- bash -c "systemctl restart nmbd"
  sleep 4

  echo "Install wsdd for Windows discovery..."
  pct exec "$CTID" -- bash -c "apt update && apt install -y wsdd wsdd-server"

  echo "Allow services through firewall..."
  pct exec "$CTID" -- bash -c "ufw allow OpenSSH"
  pct exec "$CTID" -- bash -c "ufw allow Samba"
  pct exec "$CTID" -- bash -c "ufw allow 3702/udp"
  pct exec "$CTID" -- bash -c "ufw allow 5357/tcp"
  pct exec "$CTID" -- bash -c "ufw allow 5358/tcp"

  echo "Check ufw status..."
  pct exec "$CTID" -- bash -c "ufw status"

  echo "✅ Samba installed."
}

offer_shell_access() {
  read -p "Do you want to open a shell inside container $CTID ($HOSTNAME) now? (y/n): " OPEN_SHELL
  if [[ "$OPEN_SHELL" =~ ^[Yy]$ ]]; then
    pct enter "$CTID"
  else
    echo "⏸ Shell not opened."
  fi
}

# Run script logic in sequence
update_host
prompt_container_details
create_container
add_mount_points
start_and_configure_container
