#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVERS_DIR="$SCRIPT_DIR/servers"

usage() {
  cat <<EOF
Usage: $(basename "$0") <server> [options]

Deploy Gate-WireGuard to a remote Ubuntu server via Ansible.

Arguments:
  server              Hostname or IP of the target server (SSH as root)

Options:
  --configure         Re-prompt for configuration (edit existing settings)
  --tags TAGS         Run only specific Ansible tags (e.g., update, ssl, db)
  --diff              Show changes without applying (passed to ansible)
  --check             Dry-run mode (passed to ansible)
  -h, --help          Show this help message

Examples:
  $(basename "$0") vpn.example.com                  # Full install
  $(basename "$0") vpn.example.com --tags update    # Quick code update
  $(basename "$0") vpn.example.com --configure      # Re-configure
  $(basename "$0") vpn.example.com --tags ssl        # Fix SSL after DNS
  $(basename "$0") vpn.example.com --diff --check   # Preview changes
EOF
  exit 0
}

if [[ $# -lt 1 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
  usage
fi

SERVER="$1"
shift

CONFIGURE=false
ANSIBLE_EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --configure)
      CONFIGURE=true
      shift
      ;;
    *)
      ANSIBLE_EXTRA_ARGS+=("$1")
      shift
      ;;
  esac
done

# Check dependencies
if ! command -v ansible-playbook &>/dev/null; then
  echo "Error: ansible-playbook not found. Install Ansible first:"
  echo "  brew install ansible    # macOS"
  echo "  pip install ansible     # pip"
  exit 1
fi

# Check SSH connectivity
echo "Checking SSH connectivity to root@${SERVER}..."
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "root@${SERVER}" true 2>/dev/null; then
  echo "Error: Cannot SSH to root@${SERVER}"
  echo "Ensure you can run: ssh root@${SERVER}"
  exit 1
fi
echo "SSH connection OK."

# Load or create server config
mkdir -p "$SERVERS_DIR"
VARS_FILE="$SERVERS_DIR/${SERVER}.yml"

prompt_var() {
  local var_name="$1"
  local prompt_text="$2"
  local default_value="${3:-}"
  local is_secret="${4:-false}"
  local required="${5:-true}"

  if [[ -n "$default_value" ]]; then
    prompt_text="${prompt_text} [${default_value}]"
  fi

  if [[ "$is_secret" == "true" ]]; then
    read -rsp "${prompt_text}: " value
    echo
  else
    read -rp "${prompt_text}: " value
  fi

  if [[ -z "$value" ]]; then
    value="$default_value"
  fi

  if [[ "$required" == "true" ]] && [[ -z "$value" ]]; then
    echo "Error: ${var_name} is required."
    exit 1
  fi

  eval "$var_name=\"\$value\""
}

load_existing_value() {
  local key="$1"
  local file="$2"
  if [[ -f "$file" ]]; then
    grep "^${key}:" "$file" 2>/dev/null | sed "s/^${key}: *//" | sed 's/^"//' | sed 's/"$//' || true
  fi
}

if [[ ! -f "$VARS_FILE" ]] || [[ "$CONFIGURE" == "true" ]]; then
  echo ""
  echo "=== Gate-WireGuard Configuration for ${SERVER} ==="
  echo ""

  # Load existing values as defaults if reconfiguring
  existing_domain=$(load_existing_value "domain" "$VARS_FILE")
  existing_google_id=$(load_existing_value "google_client_id" "$VARS_FILE")
  existing_google_secret=$(load_existing_value "google_client_secret" "$VARS_FILE")
  existing_hosted_domains=$(load_existing_value "hosted_domains" "$VARS_FILE")
  existing_dns_zone=$(load_existing_value "gate_dns_zone" "$VARS_FILE")
  existing_db_password=$(load_existing_value "gate_database_password" "$VARS_FILE")
  existing_git_repo=$(load_existing_value "git_repo" "$VARS_FILE")
  existing_git_branch=$(load_existing_value "git_branch" "$VARS_FILE")
  existing_secret_key=$(load_existing_value "secret_key_base" "$VARS_FILE")

  # Detect defaults
  default_repo=$(git -C "$SCRIPT_DIR/.." remote get-url origin 2>/dev/null || echo "")

  prompt_var domain "Domain name (e.g., vpn.example.com)" "${existing_domain:-}"
  prompt_var google_client_id "Google OAuth Client ID" "${existing_google_id:-}"
  prompt_var google_client_secret "Google OAuth Client Secret" "${existing_google_secret:-}" true
  prompt_var hosted_domains "Hosted domains (comma-separated, or blank for any)" "${existing_hosted_domains:-}" false false
  prompt_var gate_dns_zone "DNS zone for Gate DNS records" "${existing_dns_zone:-}"
  prompt_var gate_database_password "MySQL password for gate user" "${existing_db_password:-}" true
  prompt_var git_repo "Git repository URL" "${existing_git_repo:-$default_repo}"
  prompt_var git_branch "Git branch to deploy" "${existing_git_branch:-main}"

  # Generate or keep secret key base
  if [[ -n "${existing_secret_key:-}" ]]; then
    secret_key_base="$existing_secret_key"
  else
    secret_key_base=$(openssl rand -hex 64)
  fi

  # Write vars file (variables are set dynamically by prompt_var via eval)
  # shellcheck disable=SC2154
  cat > "$VARS_FILE" <<YAML
---
domain: "${domain}"
google_client_id: "${google_client_id}"
google_client_secret: "${google_client_secret}"
hosted_domains: "${hosted_domains}"
gate_dns_zone: "${gate_dns_zone}"
gate_database: "gate_wireguard_production"
gate_database_user: "gate_wireguard"
gate_database_password: "${gate_database_password}"
gate_redis_host: "127.0.0.1"
gate_redis_port: "6379"
git_repo: "${git_repo}"
git_branch: "${git_branch}"
secret_key_base: "${secret_key_base}"
YAML

  chmod 600 "$VARS_FILE"
  echo ""
  echo "Configuration saved to ${VARS_FILE}"
  echo ""
fi

echo "Running Ansible playbook against ${SERVER}..."
exec ansible-playbook \
  -i "${SERVER}," \
  -u root \
  -e "@${VARS_FILE}" \
  "${ANSIBLE_EXTRA_ARGS[@]}" \
  "$SCRIPT_DIR/playbook.yml"
