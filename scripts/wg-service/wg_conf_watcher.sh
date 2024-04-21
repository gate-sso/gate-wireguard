#!/bin/bash

INTERFACE_NAME="wg0"

CONFIG_FILE="/etc/wireguard/$INTERFACE_NAME.conf"
SERVICE_NAME="wg-quick@$INTERFACE_NAME"

# Wait for changes to the specified file
inotifywait -m -e modify "$CONFIG_FILE" |
while read -r directory events filename; do
  echo "Detected changes in $CONFIG_FILE, reloading $SERVICE_NAME..."
  systemctl reload $SERVICE_NAME
done