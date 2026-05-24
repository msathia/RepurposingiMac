#!/usr/bin/env bash
set -euo pipefail

echo "==> Removing Snap packages and blocking re-install..."
if command -v snap >/dev/null 2>&1; then
  snap list 2>/dev/null || true
  for pkg in snapd-desktop-integration bare core22 snapd; do
    sudo snap remove --purge "$pkg" 2>/dev/null || true
  done
fi

sudo systemctl stop snapd.service 2>/dev/null || true
sudo systemctl disable snapd.service 2>/dev/null || true
sudo systemctl mask snapd.service 2>/dev/null || true
sudo apt purge snapd -y 2>/dev/null || true
rm -rf ~/snap
sudo rm -rf /var/cache/snapd/

sudo mkdir -p /etc/apt/preferences.d
sudo cp deploy/apt/nosnap.pref /etc/apt/preferences.d/nosnap.pref

echo "==> Installing lightweight browser..."
sudo apt update
sudo apt install -y midori python3-venv python3-pip

echo "==> Installing Ollama..."
curl -fsSL https://ollama.com/install.sh | sh

echo "==> Setting up AI bot virtual environment..."
mkdir -p ~/ai_bot
cp -r ai_bot/* ~/ai_bot/
cd ~/ai_bot
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

echo "==> Deploying nanobot skills..."
mkdir -p ~/nanobot/skills
cp -r nanobot/skills/* ~/nanobot/skills/

echo "==> Pulling default Ollama model..."
ollama pull llama3.2:3b

echo "Post-install complete. Edit deploy/systemd/aibot.service with your token and username, then run scripts/install-service.sh"
