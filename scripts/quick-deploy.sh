#!/bin/bash
set -e

APP_NAME="gate-wireguard"
SERVICES="gate_wireguard"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  echo "Usage: $0 -h <host> -u <deploy_user> [-r]"
  echo
  echo "  -h  Remote host (IP or hostname, or SSH config alias)"
  echo "  -u  Deploy user on the remote box"
  echo "  -r  Restart services after sync (default: no restart)"
  echo
  echo "Syncs app code to remote host and optionally restarts Puma."
  echo "For asset changes, run 'assets:precompile' on the remote box after sync."
  exit 1
}

RESTART=false

while getopts "h:u:r" opt; do
  case $opt in
    h) HOST="$OPTARG" ;;
    u) DEPLOY_USER="$OPTARG" ;;
    r) RESTART=true ;;
    *) usage ;;
  esac
done

if [[ -z "$HOST" || -z "$DEPLOY_USER" ]]; then
  echo "Error: -h and -u are required."
  echo
  usage
fi

REMOTE_PATH="/home/${DEPLOY_USER}/${APP_NAME}"

echo "==> Syncing ${APP_NAME} to ${HOST}:${REMOTE_PATH}..."

rsync -avz --delete \
  --exclude '.git/' \
  --exclude 'log/' \
  --exclude 'tmp/' \
  --exclude 'storage/' \
  --exclude '.env' \
  --exclude 'config/master.key' \
  --exclude 'config/credentials.yml.enc' \
  --exclude 'node_modules/' \
  --exclude 'public/assets/' \
  "${REPO_DIR}/" "${HOST}:${REMOTE_PATH}/"

echo "==> Fixing ownership..."
ssh "$HOST" "sudo chown -R ${DEPLOY_USER}:${DEPLOY_USER} ${REMOTE_PATH}"

if [ "$RESTART" = true ]; then
  echo "==> Restarting services: ${SERVICES}..."
  for svc in $SERVICES; do
    ssh "$HOST" "sudo systemctl restart ${svc}"
    echo "    ${svc} restarted."
  done
  echo "==> Done. Services restarted."
else
  echo "==> Done. Sync complete (no restart). Use -r to restart services."
fi
