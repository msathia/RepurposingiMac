#!/usr/bin/env bash
set -euo pipefail

USERNAME="${1:-$(whoami)}"
TOKEN="${2:-}"

if [[ -z "$TOKEN" ]]; then
  echo "Usage: $0 [username] TELEGRAM_TOKEN"
  exit 1
fi

SERVICE_FILE="/etc/systemd/system/aibot.service"
TMP=$(mktemp)
sed "s|/home/sathia|/home/${USERNAME}|g; s|User=sathia|User=${USERNAME}|g; s|YOUR_TELEGRAM_TOKEN_HERE|${TOKEN}|g" \
  deploy/systemd/aibot.service > "$TMP"
sudo cp "$TMP" "$SERVICE_FILE"
rm "$TMP"

sudo systemctl daemon-reload
sudo systemctl enable aibot.service
sudo systemctl start aibot.service

echo "aibot.service installed and started. Monitor with: journalctl -u aibot -f"
