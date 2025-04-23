#!/bin/bash
set -e

# Stop and disable the existing zgs service
echo "[INFO] Stopping zgs service..."
sudo systemctl stop zgs || true
echo "[INFO] Disabling zgs service..."
sudo systemctl disable zgs || true
echo "[INFO] Removing zgs systemd unit file..."
sudo rm -f /etc/systemd/system/zgs.service

# Remove the old config and download the new config.toml from GitHub
echo "[INFO] Removing old config.toml and downloading the new one..."
rm -rf "$HOME/0g-storage-node/run/config.toml"
mkdir -p "$HOME/0g-storage-node/run"
curl -fsSL -o "$HOME/0g-storage-node/run/config.toml" https://raw.githubusercontent.com/bwoogmy/0g-storage-v3/main/config.toml

# Prompt the user for the miner_key and insert it into the config file
echo "[INFO] Please enter your miner_key:"
read -r miner_key
echo "[INFO] Inserting miner_key into config.toml..."
sed -i "s|miner_key = \"\"|miner_key = \"$miner_key\"|" "$HOME/0g-storage-node/run/config.toml"

# Remove the database directory
echo "[INFO] Removing the database directory..."
sudo rm -rf "$HOME/0g-storage-node/run/db/"

# Create the systemd unit file for zgs
echo "[INFO] Creating systemd unit file for zgs..."
sudo tee /etc/systemd/system/zgs.service > /dev/null <<EOF
[Unit]
Description=ZGS Node
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/0g-storage-node/run
ExecStart=$HOME/0g-storage-node/target/release/zgs_node --config $HOME/0g-storage-node/run/config.toml
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the zgs service
echo "[INFO] Reloading systemd daemon..."
sudo systemctl daemon-reload
echo "[INFO] Enabling zgs service..."
sudo systemctl enable zgs
echo "[INFO] Starting zgs service..."
sudo systemctl start zgs

# Wait for the service to initialize
echo "[INFO] Waiting for 5 seconds..."
sleep 5

# Tail the log file with the current UTC date appended
echo "[INFO] Tailing the log file..."
tail -f "$HOME/0g-storage-node/run/log/zgs.log.$(TZ=UTC date +%Y-%m-%d)"
