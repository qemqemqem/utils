#!/bin/bash
# The 'x' parameter causes all commands to print, for debugging.
set -euxo pipefail

# Create missing directories
mkdir -p ~/Dev ~/Installs ~/Pictures/Art ~/.logs ~/.atuin/bin

# Install base packages
sudo apt update
sudo apt install -y \
  fortune fortune-mod \
  direnv \
  fzf \
  curl \
  git \
  tmux \
  build-essential \
  unzip \
  wget \
  gnupg \
  software-properties-common \
  catimg \
  gridsite-clients \
  bat \
  translate-shell \
  cargo \
  pipx \
  trash-cli \
  micro \
  golang-go \
  npm

# Install Go (latest version)
GO_VERSION=1.23.5
cd /tmp
wget https://go.dev/dl/go$GO_VERSION.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go$GO_VERSION.linux-amd64.tar.gz

# Install atuin (shell history with sync)
curl https://raw.githubusercontent.com/atuinsh/atuin/main/install.sh | bash

# Install ble.sh (Bash Line Editor - syntax highlighting, autocomplete)
cd ~/Installs
git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git
cd ble.sh
make

# Install Starship (modern prompt)
curl -sS https://starship.rs/install.sh | sh -s -- -y

# Install aider (AI coding assistant)
pipx install aider-chat

# Install Tailscale (VPN)
curl -fsSL https://tailscale.com/install.sh | sh

# Touch today's log file
touch ~/.logs/bash-history-$(date +%F).log

echo -e "\n\n\nEVERYTHING AFTER HERE IS REAL SLOW!\n\n\n"

# Install Claude Code CLI globally
sudo npm install -g @anthropic-ai/claude-code

# Install aichat (AI chat in terminal)
cargo install aichat

echo -e "\n\n✅ Installation complete!\n"
echo "Remember to:"
echo "1. Restart your shell or run: source ~/.bashrc"
echo "2. Configure atuin: atuin login"
echo "3. Configure tailscale: sudo tailscale up"
