#!/bin/bash
set -euxo pipefail

# Create missing directories
mkdir -p ~/Dev ~/Installs ~/Pictures/Art ~/.logs ~/.atuin/bin

# Install base packages
sudo apt update
sudo apt install -y \
  fortune \
  direnv \
  fzf \
  curl \
  git \
  tmux \
  build-essential \
  unzip \
  wget \
  gnupg \
  software-properties-common

# Install Go
GO_VERSION=1.22.3
cd /tmp
wget https://go.dev/dl/go$GO_VERSION.linux-arm64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go$GO_VERSION.linux-arm64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc

# Install atuin
curl https://raw.githubusercontent.com/atuinsh/atuin/main/install.sh | bash

# Optional: stub out placeholder files if you want your .bashrc to stop complaining
touch ~/Dev/private_keys.sh
mkdir -p ~/Installs/ble.sh/out && touch ~/Installs/ble.sh/out/ble.sh

# Touch today's log file
touch ~/.logs/bash-history-$(date +%F).log


# Starship
curl -sS https://starship.rs/install.sh | sh


sudo apt install -y catimg gridsite-clients fortune
