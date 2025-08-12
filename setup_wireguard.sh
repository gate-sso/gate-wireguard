#!/bin/bash

# WireGuard Complete Setup Script
# This script sets up WireGuard, installs the configuration watcher service,
# and configures everything needed for the Gate WireGuard application.

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIREGUARD_DIR="/etc/wireguard"
SERVICE_NAME="wg-quick@wg0"
WATCHER_SERVICE_NAME="wireguard-conf-watcher"
WG_GROUP="wg_conf"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root for certain operations
check_sudo() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root directly. It will use sudo when needed."
        exit 1
    fi
    
    if ! sudo -n true 2>/dev/null; then
        log_info "This script requires sudo privileges. You may be prompted for your password."
    fi
}

# Check system compatibility
check_system() {
    log_info "Checking system compatibility..."
    
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        if [[ "$ID" != "ubuntu" ]] && [[ "$ID_LIKE" != *"debian"* ]]; then
            log_warning "This script is designed for Ubuntu/Debian systems. Proceed with caution."
        fi
    else
        log_warning "Cannot determine OS. Proceeding anyway..."
    fi
    
    # Check for required commands
    local required_commands=("apt" "systemctl" "iptables")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "Required command '$cmd' not found. Please install it first."
            exit 1
        fi
    done
    
    log_success "System check passed"
}

# Check if WireGuard is already installed
check_wireguard_installed() {
    if command -v wg &> /dev/null && command -v wg-quick &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Install WireGuard using package manager (fallback if Ansible not available)
install_wireguard_manual() {
    log_info "Installing WireGuard manually..."
    
    # Update package list
    sudo apt update
    
    # Install WireGuard and required packages
    sudo apt install -y wireguard linux-headers-generic inotify-tools ufw
    
    # Create WireGuard directory
    sudo mkdir -p "$WIREGUARD_DIR"
    sudo chmod 755 "$WIREGUARD_DIR"
    
    log_success "WireGuard installed manually"
}

# Install WireGuard using Ansible if available
install_wireguard_ansible() {
    log_info "Installing WireGuard using Ansible..."
    
    if ! command -v ansible-playbook &> /dev/null; then
        log_warning "Ansible not found. Installing..."
        sudo apt update
        sudo apt install -y ansible
    fi
    
    # Run the Ansible playbook
    cd "$SCRIPT_DIR"
    if [[ -f "scripts/wireguard.yml" ]]; then
        ansible-playbook scripts/wireguard.yml
    elif [[ -f "wireguard.yml" ]]; then
        ansible-playbook wireguard.yml
    else
        log_error "Ansible playbook not found. Falling back to manual installation."
        install_wireguard_manual
        return
    fi
    
    log_success "WireGuard installed using Ansible"
}

# Generate WireGuard keys if they don't exist
generate_keys() {
    log_info "Checking/generating WireGuard keys..."
    
    if [[ ! -f "$WIREGUARD_DIR/private.key" ]]; then
        log_info "Generating private key..."
        sudo wg genkey | sudo tee "$WIREGUARD_DIR/private.key" > /dev/null
        sudo chmod 600 "$WIREGUARD_DIR/private.key"
    fi
    
    if [[ ! -f "$WIREGUARD_DIR/public.key" ]]; then
        log_info "Generating public key..."
        sudo cat "$WIREGUARD_DIR/private.key" | wg pubkey | sudo tee "$WIREGUARD_DIR/public.key" > /dev/null
        sudo chmod 644 "$WIREGUARD_DIR/public.key"
    fi
    
    log_success "WireGuard keys ready"
}

# Create basic WireGuard configuration
create_basic_config() {
    log_info "Creating basic WireGuard configuration..."
    
    if [[ ! -f "$WIREGUARD_DIR/wg0.conf" ]]; then
        local private_key
        private_key=$(sudo cat "$WIREGUARD_DIR/private.key")
        
        # Create a basic configuration
        sudo tee "$WIREGUARD_DIR/wg0.conf" > /dev/null <<EOF
[Interface]
PrivateKey = $private_key
Address = 10.42.5.254/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -s 10.42.5.0/24 -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -s 10.42.5.0/24 -o eth0 -j MASQUERADE

# Clients will be added by the Gate WireGuard application
EOF
        log_info "Created basic WireGuard configuration"
    else
        log_info "WireGuard configuration already exists"
    fi
}

# Set up file permissions and group
setup_permissions() {
    log_info "Setting up file permissions and group..."
    
    # Create wg_conf group if it doesn't exist
    if ! getent group "$WG_GROUP" &> /dev/null; then
        sudo groupadd "$WG_GROUP"
        log_info "Created group: $WG_GROUP"
    fi
    
    # Add current user to the group
    sudo usermod -aG "$WG_GROUP" "$(whoami)"
    
    # Set proper ownership and permissions
    sudo chown root:"$WG_GROUP" "$WIREGUARD_DIR/wg0.conf"
    sudo chmod 664 "$WIREGUARD_DIR/wg0.conf"
    
    log_success "File permissions configured"
}

# Install the configuration watcher service
install_watcher_service() {
    log_info "Installing WireGuard configuration watcher service..."
    
    # Copy the watcher script
    sudo cp "$SCRIPT_DIR/scripts/wg-service/wg_conf_watcher.sh" "$WIREGUARD_DIR/"
    sudo chmod +x "$WIREGUARD_DIR/wg_conf_watcher.sh"
    
    # Install inotify-tools if not present
    if ! command -v inotifywait &> /dev/null; then
        log_info "Installing inotify-tools..."
        sudo apt update
        sudo apt install -y inotify-tools
    fi
    
    # Copy and install the systemd service
    sudo cp "$SCRIPT_DIR/scripts/wg-service/wireguard-conf-watcher.service" "/etc/systemd/system/"
    
    # Reload systemd and enable the service
    sudo systemctl daemon-reload
    sudo systemctl enable "$WATCHER_SERVICE_NAME.service"
    
    log_success "Watcher service installed"
}

# Configure firewall
configure_firewall() {
    log_info "Configuring firewall..."
    
    # Enable UFW if not already enabled
    if ! sudo ufw status | grep -q "Status: active"; then
        log_info "Enabling UFW firewall..."
        sudo ufw --force enable
    fi
    
    # Allow WireGuard port
    sudo ufw allow 51820/udp comment 'WireGuard'
    
    # Allow SSH (important for remote access)
    sudo ufw allow ssh
    
    log_success "Firewall configured"
}

# Start services
start_services() {
    log_info "Starting WireGuard services..."
    
    # Enable and start WireGuard
    sudo systemctl enable "$SERVICE_NAME"
    if sudo systemctl is-active --quiet "$SERVICE_NAME"; then
        log_info "Restarting WireGuard service..."
        sudo systemctl restart "$SERVICE_NAME"
    else
        log_info "Starting WireGuard service..."
        sudo systemctl start "$SERVICE_NAME"
    fi
    
    # Start the watcher service
    if sudo systemctl is-active --quiet "$WATCHER_SERVICE_NAME"; then
        log_info "Restarting watcher service..."
        sudo systemctl restart "$WATCHER_SERVICE_NAME"
    else
        log_info "Starting watcher service..."
        sudo systemctl start "$WATCHER_SERVICE_NAME"
    fi
    
    log_success "Services started"
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."
    
    local errors=0
    
    # Check WireGuard installation
    if ! command -v wg &> /dev/null; then
        log_error "WireGuard command not found"
        ((errors++))
    fi
    
    # Check if WireGuard service is running
    if ! sudo systemctl is-active --quiet "$SERVICE_NAME"; then
        log_error "WireGuard service is not running"
        ((errors++))
    fi
    
    # Check if watcher service is running
    if ! sudo systemctl is-active --quiet "$WATCHER_SERVICE_NAME"; then
        log_error "Watcher service is not running"
        ((errors++))
    fi
    
    # Check if configuration file exists
    if [[ ! -f "$WIREGUARD_DIR/wg0.conf" ]]; then
        log_error "WireGuard configuration file not found"
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        log_success "All checks passed!"
        return 0
    else
        log_error "$errors error(s) found during verification"
        return 1
    fi
}

# Display status and next steps
show_status() {
    echo
    log_info "=== WireGuard Setup Complete ==="
    echo
    echo "Services status:"
    echo "  WireGuard: $(sudo systemctl is-active $SERVICE_NAME)"
    echo "  Watcher:   $(sudo systemctl is-active $WATCHER_SERVICE_NAME)"
    echo
    echo "Configuration file: $WIREGUARD_DIR/wg0.conf"
    echo "Public key: $(sudo cat $WIREGUARD_DIR/public.key 2>/dev/null || echo 'Not found')"
    echo
    echo "Next steps:"
    echo "1. Configure your Rails application database settings"
    echo "2. Run 'bundle install' to install Ruby dependencies"
    echo "3. Run 'rails db:create db:migrate' to set up the database"
    echo "4. Start your Rails application"
    echo "5. The WireGuard configuration will be managed by your Rails app"
    echo
    echo "Useful commands:"
    echo "  sudo wg show                     - Show WireGuard status"
    echo "  sudo systemctl status $SERVICE_NAME  - Check WireGuard service"
    echo "  sudo systemctl status $WATCHER_SERVICE_NAME  - Check watcher service"
    echo "  sudo journalctl -u $WATCHER_SERVICE_NAME -f  - Follow watcher logs"
    echo
    log_warning "Note: You may need to log out and back in for group membership to take effect."
}

# Main execution
main() {
    echo "=== WireGuard Complete Setup Script ==="
    echo "This script will install and configure WireGuard with file watching capabilities."
    echo
    
    # Checks
    check_sudo
    check_system
    
    # Ask for confirmation
    read -p "Do you want to proceed with the installation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled by user"
        exit 0
    fi
    
    # Installation steps
    if check_wireguard_installed; then
        log_success "WireGuard is already installed"
    else
        log_info "WireGuard not found. Installing..."
        # Try Ansible first, fall back to manual if needed
        if command -v ansible-playbook &> /dev/null || [[ "$1" == "--use-ansible" ]]; then
            install_wireguard_ansible
        else
            install_wireguard_manual
        fi
    fi
    
    # Configuration steps
    generate_keys
    create_basic_config
    setup_permissions
    install_watcher_service
    configure_firewall
    start_services
    
    # Verification
    if verify_installation; then
        show_status
        log_success "WireGuard setup completed successfully!"
    else
        log_error "Setup completed with errors. Please check the output above."
        exit 1
    fi
}

# Help function
show_help() {
    echo "WireGuard Complete Setup Script"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --use-ansible    Force use of Ansible for installation"
    echo "  --help, -h       Show this help message"
    echo
    echo "This script will:"
    echo "  1. Install WireGuard and required dependencies"
    echo "  2. Generate WireGuard keys"
    echo "  3. Create basic configuration"
    echo "  4. Set up file permissions and groups"
    echo "  5. Install configuration file watcher service"
    echo "  6. Configure firewall rules"
    echo "  7. Start and enable all services"
    echo
}

# Parse command line arguments
case "${1:-}" in
    --help|-h)
        show_help
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
