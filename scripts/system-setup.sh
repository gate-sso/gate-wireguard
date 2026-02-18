#!/bin/bash
set -e

usage() {
  echo "Usage: $0 -h <host> -u <deploy_user> -p <password>"
  echo
  echo "  -h  Remote host (IP or hostname)"
  echo "  -u  Deploy user to create on remote box"
  echo "  -p  Password for the deploy user"
  exit 1
}

while getopts "h:u:p:" opt; do
  case $opt in
    h) HOST="$OPTARG" ;;
    u) DEPLOY_USER="$OPTARG" ;;
    p) DEPLOY_PASSWORD="$OPTARG" ;;
    *) usage ;;
  esac
done

if [[ -z "$HOST" || -z "$DEPLOY_USER" || -z "$DEPLOY_PASSWORD" ]]; then
  echo "Error: All three arguments are required."
  echo
  usage
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ansible-playbook "$SCRIPT_DIR/system-setup.yml" \
  -i "$HOST," \
  -u root \
  --extra-vars "deploy_user=$DEPLOY_USER deploy_password=$DEPLOY_PASSWORD"
