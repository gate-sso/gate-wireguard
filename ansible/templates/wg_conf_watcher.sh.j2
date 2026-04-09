#!/bin/bash
# WireGuard configuration watcher
# Reloads wg-quick@wg0 whenever /etc/wireguard/wg0.conf changes.
#
# Watches the parent DIRECTORY rather than the file itself, because:
#   1. Editors and some deploy tools replace the file via temp-file+rename
#      (atomic swap), which creates a new inode. An inotifywait bound to
#      the old file's inode would be orphaned and silently stop firing.
#   2. Backup/restore or a fresh Ansible deploy can rm+create the file,
#      same problem.
#
# Directory-level watch + filename filter catches all of these cases:
#   - close_write: in-place writes (Ruby File.write opens+truncates+writes+close)
#   - moved_to:    atomic rename (tempfile → wg0.conf)
#   - create:      rm + create

set -u

INTERFACE_NAME="wg0"
WATCH_DIR="/etc/wireguard"
CONFIG_FILE="${WATCH_DIR}/${INTERFACE_NAME}.conf"
SERVICE_NAME="wg-quick@${INTERFACE_NAME}"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') [wg-watcher] $*"
}

reload_wg() {
  log "Reloading ${SERVICE_NAME}..."
  if ! systemctl reload "$SERVICE_NAME" 2>/dev/null; then
    log "Reload failed, attempting restart..."
    systemctl restart "$SERVICE_NAME" || log "Error: Failed to restart ${SERVICE_NAME}"
  fi
  log "Reload complete."
}

# Wait for config file to exist (the admin configures it via the web UI on first run).
while [ ! -f "$CONFIG_FILE" ]; do
  log "Waiting for ${CONFIG_FILE} to be created..."
  sleep 10
done

log "Watching ${WATCH_DIR}/${INTERFACE_NAME}.conf for changes..."

# Ensure WireGuard interface is up at startup. If the file was modified while
# the watcher was down, a reload here brings us back in sync.
if ! systemctl is-active --quiet "$SERVICE_NAME"; then
  log "Starting ${SERVICE_NAME}..."
  systemctl start "$SERVICE_NAME" || log "Warning: Failed to start ${SERVICE_NAME}"
else
  reload_wg
fi

inotifywait -m -e close_write,moved_to,create "$WATCH_DIR" |
  while read -r directory events filename; do
    [ "$filename" = "${INTERFACE_NAME}.conf" ] || continue
    log "Detected ${events} on ${filename}"
    reload_wg
  done
