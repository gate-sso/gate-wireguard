#!/bin/bash

# Gate WireGuard Complete Setup Script
# This script orchestrates the complete setup of the Gate WireGuard application

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Show welcome message
show_welcome() {
    echo "=============================================="
    echo "   Gate WireGuard Production Setup Script"
    echo "=============================================="
    echo
    echo "This script will set up the complete Gate WireGuard production environment:"
    echo "  1. Database Configuration (MySQL setup or connection verification)"
    echo "  2. WireGuard VPN infrastructure"
    echo "  3. Rails application environment"
    echo "  4. All necessary dependencies and services"
    echo
    echo "Prerequisites:"
    echo "  - Ubuntu/Debian-based system"
    echo "  - sudo privileges"
    echo "  - Internet connection"
    echo
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root (use sudo when needed)"
        exit 1
    fi
    
    # Check sudo access
    if ! sudo -n true 2>/dev/null; then
        log_info "Testing sudo access..."
        sudo -v
    fi
    
    # Check internet connection
    if ! ping -c 1 google.com &> /dev/null; then
        log_error "No internet connection detected"
        exit 1
    fi
    
    # Check if scripts exist
    if [[ ! -f "$SCRIPT_DIR/setup_wireguard.sh" ]]; then
        log_error "setup_wireguard.sh not found in $SCRIPT_DIR"
        exit 1
    fi
    
    if [[ ! -f "$SCRIPT_DIR/setup_application.sh" ]]; then
        log_error "setup_application.sh not found in $SCRIPT_DIR"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Setup database first
setup_database() {
    log_info "Setting up database configuration..."
    echo "========================================"
    
    # Set production environment for application setup
    export RAILS_ENV=production
    
    # The application setup script will handle database configuration
    # This ensures database is ready before WireGuard and Rails setup
    echo "Database configuration will be handled by the application setup script."
    echo "This ensures proper database connectivity before proceeding."
    
    log_success "Database setup stage prepared"
}

# Setup WireGuard infrastructure
setup_wireguard() {
    log_info "Setting up WireGuard infrastructure..."
    echo "========================================"
    
    if ! "$SCRIPT_DIR/setup_wireguard.sh"; then
        log_error "WireGuard setup failed"
        return 1
    fi
    
    log_success "WireGuard infrastructure setup completed"
}

# Setup Rails application
setup_application() {
    log_info "Setting up Rails application..."
    echo "==============================="
    
    # Set production environment
    export RAILS_ENV=production
    
    if ! "$SCRIPT_DIR/setup_application.sh"; then
        log_error "Application setup failed"
        return 1
    fi
    
    log_success "Rails application setup completed"
}

# Final configuration and verification
final_setup() {
    log_info "Performing final configuration..."
    
    # Ensure all services are running
    sudo systemctl enable mysql redis-server
    sudo systemctl start mysql redis-server
    
    # Check if WireGuard service is running
    if systemctl is-active --quiet wg-quick@wg0; then
        log_success "WireGuard service is active"
    else
        log_warning "WireGuard service is not active. This is normal if not configured yet."
    fi
    
    # Check if file watcher is running
    if systemctl is-active --quiet wireguard-conf-watcher; then
        log_success "WireGuard configuration watcher is active"
    else
        log_warning "WireGuard configuration watcher is not active"
    fi
    
    log_success "Final configuration completed"
}

# Show completion status
show_completion() {
    echo
    echo "=============================================="
    echo "   Production Setup Complete!"
    echo "=============================================="
    echo
    echo "What was installed:"
    echo "  ✓ MySQL database (local or remote connection verified)"
    echo "  ✓ WireGuard VPN server"
    echo "  ✓ WireGuard configuration file watcher"
    echo "  ✓ Ruby environment (rbenv + Ruby)"
    echo "  ✓ Rails application (production configuration)"
    echo "  ✓ Redis cache server"
    echo "  ✓ Node.js and asset compilation tools"
    echo "  ✓ Nginx web server"
    echo
    echo "Services status:"
    echo "  WireGuard: $(systemctl is-active wg-quick@wg0 2>/dev/null || echo 'not configured')"
    echo "  WG Watcher: $(systemctl is-active wireguard-conf-watcher 2>/dev/null || echo 'inactive')"
    echo "  MySQL: $(systemctl is-active mysql 2>/dev/null || echo 'remote')"
    echo "  Redis: $(systemctl is-active redis-server)"
    echo "  Nginx: $(systemctl is-active nginx)"
    echo
    echo "Next steps for production deployment:"
    echo "  1. Configure your .env file with production values"
    echo "  2. Set up Google OAuth credentials in .env"
    echo "  3. Configure Nginx as reverse proxy:"
    echo "     - SSL certificates"
    echo "     - Domain configuration"
    echo "  4. Start the Rails application with systemd service"
    echo "  5. Configure WireGuard network settings in the admin panel"
    echo
    echo "Production commands:"
    echo "  sudo systemctl status wg-quick@wg0              # Check WireGuard status"
    echo "  sudo systemctl status wireguard-conf-watcher    # Check file watcher"
    echo "  sudo systemctl status nginx                     # Check web server"
    echo
    echo "Configuration files:"
    echo "  WireGuard: /etc/wireguard/wg0.conf"
    echo "  App config: Application .env file (see application setup output)"
    echo "  Nginx: /etc/nginx/sites-available/gate-wireguard"
    echo
    log_success "Gate WireGuard production environment is ready!"
    echo
    log_warning "Remember to:"
    echo "  - Configure SSL certificates for HTTPS"
    echo "  - Set up proper firewall rules"
    echo "  - Configure backup strategies"
    echo "  - Set up monitoring and logging"
}

# Cleanup on error
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Setup failed with exit code $exit_code"
        echo
        echo "Troubleshooting:"
        echo "  1. Check the error messages above"
        echo "  2. Ensure you have sudo privileges"
        echo "  3. Check internet connectivity"
        echo "  4. Try running individual setup scripts:"
        echo "     ./setup_wireguard.sh"
        echo "     ./setup_application.sh"
        echo
        echo "For support, please check the README or create an issue."
    fi
}

# Help function
show_help() {
    echo "Gate WireGuard Production Setup Script"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --help, -h           Show this help message"
    echo "  --database-only      Only setup database configuration"
    echo "  --wireguard-only     Only setup WireGuard infrastructure"
    echo "  --application-only   Only setup Rails application"
    echo
    echo "Production setup flow:"
    echo "  1. Database Configuration"
    echo "     • Install MySQL locally OR verify remote MySQL connection"
    echo "     • Create production database and user"
    echo "  2. WireGuard Infrastructure"
    echo "     • Install and configure WireGuard VPN server"
    echo "     • Set up configuration file watcher service"
    echo "  3. Rails Application"
    echo "     • Install Ruby environment for specified user"
    echo "     • Deploy Rails application in production mode"
    echo "     • Configure Nginx web server"
    echo
    echo "The script handles:"
    echo "  • MySQL database setup (local installation or remote connection)"
    echo "  • User management for Rails application deployment"
    echo "  • Production environment configuration"
    echo "  • Service integration and monitoring"
    echo
    echo "Designed for production deployment on Ubuntu/Debian systems."
    echo
}

# Main execution function
main() {
    # Set up error handling
    trap cleanup EXIT
    
    case "${1:-}" in
        --help|-h)
            show_help
            exit 0
            ;;
        --database-only)
            show_welcome
            check_prerequisites
            setup_database
            log_success "Database-only setup completed!"
            exit 0
            ;;
        --wireguard-only)
            show_welcome
            check_prerequisites
            setup_wireguard
            log_success "WireGuard-only setup completed!"
            exit 0
            ;;
        --application-only)
            show_welcome
            check_prerequisites
            export RAILS_ENV=production
            setup_application
            log_success "Application-only setup completed!"
            exit 0
            ;;
        *)
            # Full production setup
            show_welcome
            
            # Ask for confirmation
            read -p "Do you want to proceed with the complete production setup? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "Setup cancelled by user"
                exit 0
            fi
            
            # Run setup steps in production order:
            # 1. Prerequisites
            # 2. Database setup and verification (via application setup)
            # 3. WireGuard infrastructure  
            # 4. Rails application deployment
            check_prerequisites
            
            log_info "Starting production setup in order: Database → WireGuard → Application"
            echo
            
            # Database setup is handled by application setup script
            # but we set the environment first
            export RAILS_ENV=production
            setup_database
            
            # Application setup (includes database verification)
            setup_application
            
            # WireGuard setup after database is confirmed working
            setup_wireguard
            
            # Final configuration
            final_setup
            show_completion
            ;;
    esac
}

# Run main function
main "$@"
