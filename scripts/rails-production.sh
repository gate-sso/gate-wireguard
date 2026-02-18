#!/bin/bash
set -e

usage() {
  echo "Usage: $0 -h <host> -u <deploy_user> -p <password> -P <port> -e <env_file>"
  echo
  echo "  -h  Remote host (IP or hostname)"
  echo "  -u  Deploy user to create on remote box"
  echo "  -p  Password for the deploy user"
  echo "  -P  Application port (Puma)"
  echo "  -e  Path to local .env file to deploy (see files/env-production-example)"
  exit 1
}

while getopts "h:u:p:P:e:" opt; do
  case $opt in
    h) HOST="$OPTARG" ;;
    u) DEPLOY_USER="$OPTARG" ;;
    p) DEPLOY_PASSWORD="$OPTARG" ;;
    P) APP_PORT="$OPTARG" ;;
    e) ENV_FILE="$OPTARG" ;;
    *) usage ;;
  esac
done

if [[ -z "$HOST" || -z "$DEPLOY_USER" || -z "$DEPLOY_PASSWORD" || -z "$APP_PORT" || -z "$ENV_FILE" ]]; then
  echo "Error: All five arguments are required."
  echo
  usage
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: env file '$ENV_FILE' not found."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ansible-playbook "$SCRIPT_DIR/rails-production.yml" \
  -i "$HOST," \
  -u root \
  --extra-vars "deploy_user=$DEPLOY_USER deploy_password=$DEPLOY_PASSWORD puma_port=$APP_PORT env_file=$ENV_FILE"
