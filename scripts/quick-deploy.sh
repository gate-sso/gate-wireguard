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
  echo "  -r  Restart services after sync (runs bundle install + yarn install + assets:precompile first)"
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

# SSH multiplexing — reuse a single TCP connection across rsync + ssh calls
SSH_OPTS="-o ControlMaster=auto -o ControlPersist=60s -o ControlPath=/tmp/quick-deploy-ssh-%h-%p-%r"

echo "==> Syncing ${APP_NAME} to ${HOST}:${REMOTE_PATH}..."

rsync -avz --delete \
  -e "ssh ${SSH_OPTS}" \
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
ssh ${SSH_OPTS} "$HOST" "sudo chown -R ${DEPLOY_USER}:${DEPLOY_USER} ${REMOTE_PATH}"

if [ "$RESTART" = true ]; then
  echo "==> Building and restarting..."
  ssh ${SSH_OPTS} "$HOST" "cd ${REMOTE_PATH} && ${REMOTE_ENV} && bundle install --jobs 4 --retry 3 && ${NVM_INIT} && yarn install && set -a && source .env && set +a && RAILS_ENV=production bundle exec rails assets:precompile && sudo systemctl restart ${SERVICES}"
  echo "==> Done. Services restarted."
else
  echo "==> Done. Sync complete (no restart). Use -r to rebuild and restart services."
fi
