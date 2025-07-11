#!/bin/bash

echo "✅ Script is running."

# Ensure script is run as root
if [[ "$EUID" -ne 0 ]]; then
  echo "❌ Please run this script as root or with sudo."
  exit 1
fi

# Prompt for new username
read -p "👤 Enter username to create: " NEWUSER

# Update system
apt update
apt upgrade -y

# Check if user exists
if id "$NEWUSER" &>/dev/null; then
  echo "⚠️ User '$NEWUSER' already exists."
else
  # Prompt for password
  read -s -p "🔑 Enter password for $NEWUSER: " USERPASS
  echo

  # Create user without prompting for other info
  adduser --disabled-password --gecos "" "$NEWUSER"

  # Set the password
  echo "$NEWUSER:$USERPASS" | chpasswd
  echo "✅ User '$NEWUSER' created with specified password."
fi

# Add to sudo group
usermod -aG sudo "$NEWUSER"
echo "✅ Added '$NEWUSER' to the sudo group."

# Run commands as the new user
sudo -u "$NEWUSER" bash -c 'echo "👋 Now running as: $(whoami)"'
sudo -u "$NEWUSER" bash -c 'sudo apt update'
sudo -u "$NEWUSER" bash -c 'curl -sSL https://get.docker.com | sh'
sudo -u "$NEWUSER" bash -c "sudo usermod -aG docker $NEWUSER"

echo "✅ Completed. Logging out."
exit
