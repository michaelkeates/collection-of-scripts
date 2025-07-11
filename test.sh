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

# Create user if not exists
if id "mike" &>/dev/null; then
  echo "👤 User 'mike' already exists."
else
  adduser --disabled-password --gecos "" mike
  echo "🔐 Please set a password for 'mike' manually later if needed."
fi

# Add to sudo group
usermod -aG sudo mike
echo "✅ Added 'mike' to the sudo group."

# Run commands as mike
sudo -u mike bash -c 'echo "👋 Now running as: $(whoami)"'
sudo -u mike bash -c 'sudo apt update'
sudo -u mike bash -c 'curl -sSL https://get.docker.com | sh'
