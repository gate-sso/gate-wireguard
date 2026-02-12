#!/bin/bash

# Gate WireGuard Application Setup Script
# This script sets up the Rails application environment and dependencies

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUBY_VERSION="3.3.4"  # Adjust based on your .ruby-version file
NODE_VERSION="18"     # Required for asset compilation
RAILS_ENV="${RAILS_ENV:-production}"
APP_USER=""
DB_HOST=""
DB_NAME=""
DB_USER=""
DB_PASS=""
INSTALL_MYSQL_LOCAL=false

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

# Check system compatibility
check_system() {
    log_info "Checking system compatibility..."
    
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        if [[ "$ID" != "ubuntu" ]] && [[ "$ID_LIKE" != *"debian"* ]]; then
            log_warning "This script is designed for Ubuntu/Debian systems. Proceed with caution."
        fi
    fi
    
    log_success "System check passed"
}

# Get database configuration from user
get_database_config() {
    log_info "Database Configuration"
    echo "Choose database setup option:"
    echo "1. Install MySQL locally"
    echo "2. Use existing MySQL server"
    
    while true; do
        read -p "Enter your choice (1 or 2): " db_choice
        case $db_choice in
            1)
                INSTALL_MYSQL_LOCAL=true
                log_info "Will install MySQL locally"
                
                # Get MySQL credentials for local installation
                while [[ -z "$DB_USER" ]]; do
                    read -p "Enter MySQL username to create: " DB_USER
                done
                
                while [[ -z "$DB_PASS" ]]; do
                    read -s -p "Enter MySQL password for $DB_USER: " DB_PASS
                    echo
                done
                
                read -p "Enter database name [gate_wireguard_production]: " DB_NAME
                DB_NAME="${DB_NAME:-gate_wireguard_production}"
                DB_HOST="localhost"
                break
                ;;
            2)
                INSTALL_MYSQL_LOCAL=false
                log_info "Will use existing MySQL server"
                
                # Get existing MySQL connection details
                while [[ -z "$DB_HOST" ]]; do
                    read -p "Enter MySQL server address: " DB_HOST
                done
                
                while [[ -z "$DB_USER" ]]; do
                    read -p "Enter MySQL username: " DB_USER
                done
                
                while [[ -z "$DB_PASS" ]]; do
                    read -s -p "Enter MySQL password: " DB_PASS
                    echo
                done
                
                read -p "Enter database name [gate_wireguard_production]: " DB_NAME
                DB_NAME="${DB_NAME:-gate_wireguard_production}"
                break
                ;;
            *)
                log_error "Invalid choice. Please enter 1 or 2."
                ;;
        esac
    done
    
    log_success "Database configuration collected"
}

# Get application user configuration
get_app_user_config() {
    log_info "Application User Configuration"
    
    echo "Current user: $(whoami)"
    read -p "Install Rails app as current user? (Y/n): " use_current_user
    
    if [[ $use_current_user =~ ^[Nn]$ ]]; then
        while [[ -z "$APP_USER" ]]; do
            read -p "Enter username to install Rails app as: " APP_USER
        done
        
        # Check if user exists
        if ! id "$APP_USER" &>/dev/null; then
            log_info "User $APP_USER does not exist. Creating user..."
            sudo useradd -m -s /bin/bash "$APP_USER"
            sudo usermod -aG sudo "$APP_USER"
            log_success "User $APP_USER created"
        fi
    else
        APP_USER=$(whoami)
    fi
    
    log_info "Rails app will be installed as user: $APP_USER"
}

# Install system dependencies
install_system_dependencies() {
    log_info "Installing system dependencies..."
    
    sudo apt update
    
    # Base dependencies
    local packages=(
        curl
        git
        build-essential
        libssl-dev
        libreadline-dev
        zlib1g-dev
        libyaml-dev
        libxml2-dev
        libxslt1-dev
        libcurl4-openssl-dev
        libffi-dev
        redis-server
        nodejs
        npm
        yarn
        nginx
    )
    
    # Add MySQL packages if installing locally
    if [[ "$INSTALL_MYSQL_LOCAL" == "true" ]]; then
        packages+=(mysql-server mysql-client libmysqlclient-dev)
    else
        packages+=(libmysqlclient-dev)  # Just the client library for connecting to remote MySQL
    fi
    
    sudo apt install -y "${packages[@]}"
    
    log_success "System dependencies installed"
}

# Install Ruby using rbenv for specific user
install_ruby() {
    log_info "Setting up Ruby environment for user $APP_USER..."
    
    if [[ "$APP_USER" != "$(whoami)" ]]; then
        # Install rbenv for different user
        sudo -u "$APP_USER" bash << 'EOF'
# Check if rbenv is already installed
if command -v rbenv &> /dev/null; then
    echo "rbenv already installed"
else
    echo "Installing rbenv..."
    curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash
    
    # Add rbenv to PATH for both bash and zsh
    if [[ -f ~/.bashrc ]]; then
        echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
        echo 'eval "$(rbenv init -)"' >> ~/.bashrc
    fi
    
    if [[ -f ~/.zshrc ]]; then
        echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.zshrc
        echo 'eval "$(rbenv init -)"' >> ~/.zshrc
    fi
fi

# Load rbenv
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# Install Ruby if not present
if rbenv versions | grep -q "$RUBY_VERSION"; then
    echo "Ruby $RUBY_VERSION already installed"
else
    echo "Installing Ruby $RUBY_VERSION..."
    rbenv install "$RUBY_VERSION"
fi

# Set global Ruby version
rbenv global "$RUBY_VERSION"
rbenv rehash
EOF
    else
        # Install for current user (existing logic)
        if command -v rbenv &> /dev/null; then
            log_info "rbenv already installed"
        else
            log_info "Installing rbenv..."
            curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash
            
            # Add rbenv to PATH
            if [[ -f ~/.bashrc ]]; then
                echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
                echo 'eval "$(rbenv init -)"' >> ~/.bashrc
            fi
            
            if [[ -f ~/.zshrc ]]; then
                echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.zshrc
                echo 'eval "$(rbenv init -)"' >> ~/.zshrc
            fi
            
            # Load rbenv
            export PATH="$HOME/.rbenv/bin:$PATH"
            eval "$(rbenv init -)"
        fi
        
        # Install Ruby if not present
        if rbenv versions | grep -q "$RUBY_VERSION"; then
            log_info "Ruby $RUBY_VERSION already installed"
        else
            log_info "Installing Ruby $RUBY_VERSION..."
            rbenv install "$RUBY_VERSION"
        fi
        
        # Set global Ruby version
        rbenv global "$RUBY_VERSION"
        rbenv rehash
    fi
    
    log_success "Ruby environment ready for user $APP_USER"
}

# Install Bundler and application gems
install_gems() {
    log_info "Installing Ruby gems for user $APP_USER..."
    
    local app_dir
    if [[ "$APP_USER" != "$(whoami)" ]]; then
        app_dir="/home/$APP_USER/gate-wireguard"
        
        # Copy application to app user's directory
        log_info "Copying application to $app_dir..."
        sudo mkdir -p "$app_dir"
        sudo cp -r "$SCRIPT_DIR"/* "$app_dir/"
        sudo chown -R "$APP_USER:$APP_USER" "$app_dir"
        
        # Install gems as app user
        sudo -u "$APP_USER" bash << EOF
cd "$app_dir"
export PATH="\$HOME/.rbenv/bin:\$PATH"
eval "\$(rbenv init -)"

# Install Bundler
if ! gem list bundler -i &> /dev/null; then
    gem install bundler
fi

# Install application dependencies
bundle config set --local deployment 'true'
bundle config set --local without 'development test'
bundle install
EOF
    else
        app_dir="$SCRIPT_DIR"
        cd "$app_dir"
        
        # Install Bundler
        if ! gem list bundler -i &> /dev/null; then
            gem install bundler
        fi
        
        # Install application dependencies
        if [[ "$RAILS_ENV" == "production" ]]; then
            bundle config set --local deployment 'true'
            bundle config set --local without 'development test'
        fi
        bundle install
    fi
    
    log_success "Gems installed for user $APP_USER"
}

# Test database connection
test_database_connection() {
    log_info "Testing database connection..."
    
    # Test MySQL connection
    if mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e "SELECT 1;" &>/dev/null; then
        log_success "Database connection successful"
        return 0
    else
        log_error "Database connection failed"
        return 1
    fi
}

# Setup MySQL (local installation)
setup_mysql_local() {
    log_info "Setting up local MySQL server..."
    
    # Start MySQL service
    sudo systemctl start mysql
    sudo systemctl enable mysql
    
    # Secure MySQL installation and create user
    log_info "Configuring MySQL security and creating user..."
    
    # Create user and database
    mysql -u root << EOF
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASS';
CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%';
FLUSH PRIVILEGES;
EOF
    
    if [[ $? -eq 0 ]]; then
        log_success "MySQL user and database created successfully"
    else
        log_error "Failed to create MySQL user and database"
        return 1
    fi
}

# Set up database
setup_database() {
    log_info "Setting up database..."
    
    if [[ "$INSTALL_MYSQL_LOCAL" == "true" ]]; then
        setup_mysql_local
    fi
    
    # Test connection
    if ! test_database_connection; then
        log_error "Cannot connect to database. Please check your configuration."
        return 1
    fi
    
    # Switch to app user directory
    local app_dir
    if [[ "$APP_USER" != "$(whoami)" ]]; then
        app_dir="/home/$APP_USER/gate-wireguard"
    else
        app_dir="$SCRIPT_DIR"
    fi
    
    # Create database configuration
    log_info "Creating database configuration..."
    
    # Run database operations as app user
    if [[ "$APP_USER" != "$(whoami)" ]]; then
        sudo -u "$APP_USER" bash << EOF
cd "$app_dir"
export PATH="\$HOME/.rbenv/bin:\$PATH"
eval "\$(rbenv init -)"

# Check if database exists and run migrations
if bundle exec rails db:version RAILS_ENV=$RAILS_ENV &> /dev/null; then
    echo "Database already exists, running migrations..."
    bundle exec rails db:migrate RAILS_ENV=$RAILS_ENV
else
    echo "Creating database..."
    bundle exec rails db:create RAILS_ENV=$RAILS_ENV
    bundle exec rails db:migrate RAILS_ENV=$RAILS_ENV
fi

# Load seeds for production if available
if [[ -f "db/seeds.rb" && "$RAILS_ENV" == "production" ]]; then
    echo "Loading seed data..."
    bundle exec rails db:seed RAILS_ENV=$RAILS_ENV
fi
EOF
    else
        cd "$app_dir"
        
        # Check if database exists and run migrations
        if bundle exec rails db:version RAILS_ENV=$RAILS_ENV &> /dev/null; then
            log_info "Database already exists, running migrations..."
            bundle exec rails db:migrate RAILS_ENV=$RAILS_ENV
        else
            log_info "Creating database..."
            bundle exec rails db:create RAILS_ENV=$RAILS_ENV
            bundle exec rails db:migrate RAILS_ENV=$RAILS_ENV
        fi
        
        # Load seeds for production if available
        if [[ -f "db/seeds.rb" && "$RAILS_ENV" == "production" ]]; then
            log_info "Loading seed data..."
            bundle exec rails db:seed RAILS_ENV=$RAILS_ENV
        fi
    fi
    
    log_success "Database setup complete"
}

# Set up Redis
setup_redis() {
    log_info "Setting up Redis..."
    
    sudo systemctl start redis-server
    sudo systemctl enable redis-server
    
    log_success "Redis setup complete"
}

# Install Node.js dependencies and build assets
setup_assets() {
    log_info "Setting up assets..."
    
    local app_dir
    if [[ "$APP_USER" != "$(whoami)" ]]; then
        app_dir="/home/$APP_USER/gate-wireguard"
        
        # Build assets as app user
        sudo -u "$APP_USER" bash << EOF
cd "$app_dir"

# Install Node dependencies
if [[ -f "package.json" ]]; then
    yarn install
    
    # Build CSS for production
    yarn build:css
    
    echo "Assets built successfully"
else
    echo "package.json not found, skipping asset compilation"
fi
EOF
    else
        app_dir="$SCRIPT_DIR"
        cd "$app_dir"
        
        # Install Node dependencies
        if [[ -f "package.json" ]]; then
            yarn install
            
            # Build CSS for production
            yarn build:css
            
            log_success "Assets built successfully"
        else
            log_warning "package.json not found, skipping asset compilation"
        fi
    fi
}

# Create necessary directories and files
setup_directories() {
    log_info "Setting up application directories..."
    
    local app_dir
    if [[ "$APP_USER" != "$(whoami)" ]]; then
        app_dir="/home/$APP_USER/gate-wireguard"
        
        sudo -u "$APP_USER" bash << EOF
cd "$app_dir"

# Create necessary directories
mkdir -p log tmp/pids tmp/cache tmp/sockets storage public/uploads

# Set proper permissions for production
chmod 755 log tmp storage public/uploads
EOF
    else
        app_dir="$SCRIPT_DIR"
        cd "$app_dir"
        
        # Create necessary directories
        mkdir -p log tmp/pids tmp/cache tmp/sockets storage public/uploads
        
        # Set proper permissions
        chmod 755 log tmp storage public/uploads
    fi
    
    log_success "Directories created"
}

# Set up environment configuration
setup_environment() {
    log_info "Setting up environment configuration..."
    
    local app_dir
    if [[ "$APP_USER" != "$(whoami)" ]]; then
        app_dir="/home/$APP_USER/gate-wireguard"
    else
        app_dir="$SCRIPT_DIR"
    fi
    
    local env_file="$app_dir/.env"
    
    # Create .env file if it doesn't exist
    if [[ ! -f "$env_file" ]] && [[ -f "$app_dir/.env.example" ]]; then
        cp "$app_dir/.env.example" "$env_file"
        log_info "Created .env file from .env.example"
    elif [[ ! -f "$env_file" ]]; then
        # Create production .env file
        cat > "$env_file" <<EOF
# Rails Environment
RAILS_ENV=$RAILS_ENV

# Database Configuration
DATABASE_URL=mysql2://$DB_USER:$DB_PASS@$DB_HOST/$DB_NAME

# Redis Configuration
REDIS_URL=redis://localhost:6379/0

# Secret Key Base (generate with: rails secret)
SECRET_KEY_BASE=$(cd "$app_dir" && sudo -u "$APP_USER" bash -c 'export PATH="$HOME/.rbenv/bin:$PATH"; eval "$(rbenv init -)"; bundle exec rails secret')

# Google OAuth (configure these with your OAuth app credentials)
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret



# Production specific settings
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
EOF
        log_info "Created production .env file"
    fi
    
    # Update database configuration in the .env file
    if grep -q "DATABASE_URL=" "$env_file"; then
        if [[ "$APP_USER" != "$(whoami)" ]]; then
            sudo -u "$APP_USER" sed -i "s|DATABASE_URL=.*|DATABASE_URL=mysql2://$DB_USER:$DB_PASS@$DB_HOST/$DB_NAME|" "$env_file"
        else
            sed -i "s|DATABASE_URL=.*|DATABASE_URL=mysql2://$DB_USER:$DB_PASS@$DB_HOST/$DB_NAME|" "$env_file"
        fi
    fi
    
    # Set proper ownership
    if [[ "$APP_USER" != "$(whoami)" ]]; then
        sudo chown "$APP_USER:$APP_USER" "$env_file"
        sudo chmod 600 "$env_file"  # Secure the file
    else
        chmod 600 "$env_file"
    fi
    
    log_success "Environment configuration ready"
    log_warning "Please edit $env_file with your actual configuration values"
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."
    
    local errors=0
    local app_dir
    
    if [[ "$APP_USER" != "$(whoami)" ]]; then
        app_dir="/home/$APP_USER/gate-wireguard"
    else
        app_dir="$SCRIPT_DIR"
    fi
    
    # Check Ruby version
    local ruby_check
    if [[ "$APP_USER" != "$(whoami)" ]]; then
        ruby_check=$(sudo -u "$APP_USER" bash -c 'export PATH="$HOME/.rbenv/bin:$PATH"; eval "$(rbenv init -)"; ruby --version')
    else
        ruby_check=$(ruby --version)
    fi
    
    if ! echo "$ruby_check" | grep -q "$RUBY_VERSION"; then
        log_error "Ruby $RUBY_VERSION not found"
        ((errors++))
    fi
    
    # Check if bundle works
    local bundle_check
    if [[ "$APP_USER" != "$(whoami)" ]]; then
        bundle_check=$(sudo -u "$APP_USER" bash -c "cd '$app_dir'; export PATH=\"\$HOME/.rbenv/bin:\$PATH\"; eval \"\$(rbenv init -)\"; bundle check" 2>&1)
    else
        bundle_check=$(cd "$app_dir" && bundle check 2>&1)
    fi
    
    if [[ $? -ne 0 ]]; then
        log_error "Bundle check failed: $bundle_check"
        ((errors++))
    fi
    
    # Check database connection
    if ! test_database_connection; then
        log_error "Database connection failed"
        ((errors++))
    fi
    
    # Check Redis connection (if installed locally)
    if systemctl is-active --quiet redis-server; then
        if ! redis-cli ping &> /dev/null; then
            log_error "Redis connection failed"
            ((errors++))
        fi
    fi
    
    if [[ $errors -eq 0 ]]; then
        log_success "All checks passed!"
        return 0
    else
        log_error "$errors error(s) found during verification"
        return 1
    fi
}

# Show final status and instructions
show_status() {
    local app_dir
    if [[ "$APP_USER" != "$(whoami)" ]]; then
        app_dir="/home/$APP_USER/gate-wireguard"
    else
        app_dir="$SCRIPT_DIR"
    fi
    
    echo
    log_info "=== Gate WireGuard Application Setup Complete ==="
    echo
    echo "Application directory: $app_dir"
    echo "Application user: $APP_USER"
    echo "Rails environment: $RAILS_ENV"
    echo "Database: $DB_NAME on $DB_HOST"
    
    local ruby_version
    if [[ "$APP_USER" != "$(whoami)" ]]; then
        ruby_version=$(sudo -u "$APP_USER" bash -c 'export PATH="$HOME/.rbenv/bin:$PATH"; eval "$(rbenv init -)"; ruby --version')
    else
        ruby_version=$(ruby --version)
    fi
    echo "Ruby version: $ruby_version"
    
    local rails_version
    if [[ "$APP_USER" != "$(whoami)" ]]; then
        rails_version=$(sudo -u "$APP_USER" bash -c "cd '$app_dir'; export PATH=\"\$HOME/.rbenv/bin:\$PATH\"; eval \"\$(rbenv init -)\"; bundle exec rails --version")
    else
        rails_version=$(cd "$app_dir" && bundle exec rails --version)
    fi
    echo "Rails version: $rails_version"
    echo
    echo "Services status:"
    if [[ "$INSTALL_MYSQL_LOCAL" == "true" ]]; then
        echo "  MySQL: $(systemctl is-active mysql)"
    else
        echo "  MySQL: remote ($DB_HOST)"
    fi
    echo "  Redis: $(systemctl is-active redis-server)"
    echo
    
    if [[ "$RAILS_ENV" == "production" ]]; then
        echo "To start the application in production:"
        echo "  sudo -u $APP_USER bash -c 'cd $app_dir && bundle exec rails server -e production'"
        echo
        echo "For production deployment with systemd:"
        echo "  Create a systemd service file for the Rails application"
        echo "  Configure Nginx as reverse proxy"
    else
        echo "To start the application:"
        echo "  cd $app_dir"
        echo "  bundle exec rails server"
        echo
        echo "To run in development with file watching:"
        echo "  bundle exec bin/dev"
    fi
    
    echo
    echo "Useful commands:"
    echo "  sudo -u $APP_USER bash -c 'cd $app_dir && bundle exec rails console'  - Open Rails console"
    echo "  sudo -u $APP_USER bash -c 'cd $app_dir && bundle exec rails db:migrate' - Run migrations"
    if [[ "$RAILS_ENV" != "production" ]]; then
        echo "  sudo -u $APP_USER bash -c 'cd $app_dir && bundle exec rspec' - Run tests"
    fi
    echo "  sudo -u $APP_USER bash -c 'cd $app_dir && yarn build:css' - Rebuild CSS"
    echo
    log_warning "Don't forget to:"
    echo "1. Configure your $app_dir/.env file with correct values"
    echo "2. Set up Google OAuth credentials"
    if [[ "$INSTALL_MYSQL_LOCAL" != "true" ]]; then
        echo "3. Ensure your remote MySQL server is accessible"
    fi
    echo "4. Configure Nginx for production deployment"
    echo "5. Set up SSL certificates for HTTPS"
}

# Main execution
main() {
    echo "=== Gate WireGuard Application Setup Script ==="
    echo "This script will set up the Rails application environment and dependencies."
    echo
    
    # Get configuration from user
    get_database_config
    get_app_user_config
    
    # Ask for confirmation
    echo
    echo "Configuration Summary:"
    echo "  Rails Environment: $RAILS_ENV"
    echo "  Application User: $APP_USER"
    echo "  Database: $DB_NAME on $DB_HOST"
    echo "  MySQL Installation: $(if [[ "$INSTALL_MYSQL_LOCAL" == "true" ]]; then echo "Local"; else echo "Remote"; fi)"
    echo
    read -p "Do you want to proceed with the setup? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Setup cancelled by user"
        exit 0
    fi
    
    # Setup steps
    check_system
    install_system_dependencies
    install_ruby
    install_gems
    setup_directories
    setup_environment
    setup_database
    setup_redis
    setup_assets
    
    # Verification
    if verify_installation; then
        show_status
        log_success "Application setup completed successfully!"
    else
        log_error "Setup completed with errors. Please check the output above."
        exit 1
    fi
}

# Help function
show_help() {
    echo "Gate WireGuard Application Setup Script"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --help, -h       Show this help message"
    echo
    echo "This script will:"
    echo "  1. Install system dependencies (Ruby, Node.js, MySQL, Redis)"
    echo "  2. Set up Ruby environment with rbenv"
    echo "  3. Install Ruby gems"
    echo "  4. Set up database"
    echo "  5. Configure Redis"
    echo "  6. Build assets"
    echo "  7. Create necessary directories"
    echo "  8. Set up environment configuration"
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
