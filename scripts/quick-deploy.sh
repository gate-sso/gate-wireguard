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
  echo "  -r  Restart services after sync (runs bundle install + assets:precompile first)"
  echo
  echo "Syncs app code to remote host and optionally rebuilds + restarts."
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
GEM_HOME="/home/${DEPLOY_USER}/.ruby"
NVM_INIT="export NVM_DIR=/home/${DEPLOY_USER}/.nvm && . \$NVM_DIR/nvm.sh"
REMOTE_ENV="export GEM_HOME=${GEM_HOME} && export PATH=${GEM_HOME}/bin:/usr/local/bin:\$PATH"

echo "==> Syncing ${APP_NAME} to ${HOST}:${REMOTE_PATH}..."

rsync -avz --delete \
  --exclude '.git/' \
  --exclude 'log/' \
  --exclude 'tmp/' \
  --exclude 'storage/' \
  --exclude 'vendor/' \
  --exclude '.env' \
  --exclude 'config/master.key' \
  --exclude 'config/credentials.yml.enc' \
  --exclude 'config/wireguard' \
  --exclude 'node_modules/' \
  --exclude 'public/assets/' \
  "${REPO_DIR}/" "${HOST}:${REMOTE_PATH}/"

echo "==> Fixing ownership..."
ssh "$HOST" "sudo chown -R ${DEPLOY_USER}:${DEPLOY_USER} ${REMOTE_PATH}"

if [ "$RESTART" = true ]; then
  echo "==> Running bundle install..."
  ssh "$HOST" "cd ${REMOTE_PATH} && ${REMOTE_ENV} && bundle install"

  echo "==> Running yarn install..."
  ssh "$HOST" "cd ${REMOTE_PATH} && ${NVM_INIT} && yarn install"

  echo "==> Precompiling assets..."
  ssh "$HOST" "cd ${REMOTE_PATH} && ${NVM_INIT} && ${REMOTE_ENV} && set -a && source .env && set +a && RAILS_ENV=production bundle exec rails assets:precompile"

  echo "==> Restarting services: ${SERVICES}..."
  for svc in $SERVICES; do
    ssh "$HOST" "sudo systemctl restart ${svc}"
    echo "    ${svc} restarted."
  done
  echo "==> Done. Services restarted."
else
  echo "==> Done. Sync complete (no restart). Use -r to rebuild and restart services."
fi
