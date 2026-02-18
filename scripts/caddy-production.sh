#!/bin/bash
set -e

usage() {
  echo "Usage: $0 -h <host> -u <deploy_user> -d <domain>"
  echo
  echo "  -h  Remote host (IP or hostname)"
  echo "  -u  Deploy user (to locate puma.rb under /home/<user>/gate-wireguard/)"
  echo "  -d  Domain name for the Caddy virtual host (e.g. vpn.example.com)"
  exit 1
}

while getopts "h:u:d:" opt; do
  case $opt in
    h) HOST="$OPTARG" ;;
    u) DEPLOY_USER="$OPTARG" ;;
    d) DOMAIN="$OPTARG" ;;
    *) usage ;;
  esac
done

if [[ -z "$HOST" || -z "$DEPLOY_USER" || -z "$DOMAIN" ]]; then
  echo "Error: -h, -u, and -d are required."
  echo
  usage
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ansible-playbook "$SCRIPT_DIR/caddy-production.yml" \
  -i "$HOST," \
  -u root \
  --extra-vars "deploy_user=$DEPLOY_USER domain=$DOMAIN"
