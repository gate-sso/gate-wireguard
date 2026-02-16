#!/bin/bash
set -e

SERVER=${1:-gate.clawstation.ai}

echo "Deploying Gate-WireGuard to $SERVER..."

# Load environment variables if .env exists locally to pass them to Ansible
# This is optional, you can also pass them via -e
# if [ -f .env ]; then
#   export $(grep -v '^#' .env | xargs)
# fi

ansible-playbook ansible/deploy_production.yml -i "$SERVER," \
  -u root \
  "$@"
