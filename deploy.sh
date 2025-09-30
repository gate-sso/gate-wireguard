#!/bin/bash
# Production Deployment Script for Gate-WireGuard
# Run this script as root or with sudo

set -e  # Exit on any error

echo "🚀 Starting Gate-WireGuard Production Deployment..."

# Set production environment
export RAILS_ENV=production

# 1. Update system packages
echo "📦 Updating system packages..."
apt-get update && apt-get upgrade -y

# 2. Install required packages if not already installed
echo "🔧 Installing required packages..."
apt-get install -y \
  ruby ruby-dev \
  nodejs npm \
  mysql-server \
  redis-server \
  nginx \
  certbot python3-certbot-nginx \
  wireguard \
  build-essential \
  git

# 3. Install bundler and yarn
echo "💎 Installing bundler and yarn..."
gem install bundler
npm install -g yarn

# 4. Navigate to application directory
cd /home/ajey/workspace/gate-wireguard

# 5. Install Ruby dependencies
echo "📚 Installing Ruby dependencies..."
bundle config set --local deployment 'true'
bundle config set --local without 'development test'
bundle install

# 6. Install JavaScript dependencies
echo "🎨 Installing JavaScript dependencies..."
yarn install --production

# 7. Setup production database
echo "🗄️ Setting up production database..."
# Create production database
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS gate_wireguard_production;"
mysql -u root -p -e "GRANT ALL PRIVILEGES ON gate_wireguard_production.* TO 'gate_user'@'localhost';"
mysql -u root -p -e "FLUSH PRIVILEGES;"

# 8. Setup environment variables
echo "🔐 Setting up environment variables..."
if [ ! -f .env.production ]; then
    cat > .env.production << EOF
RAILS_ENV=production
SECRET_KEY_BASE=$(bundle exec rails secret)
DATABASE_URL=mysql2://gate_user:your_password@localhost/gate_wireguard_production
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
REDIS_URL=redis://localhost:6379/0
EOF
    echo "⚠️  Please edit .env.production with your actual credentials!"
fi

# 9. Database migration
echo "🏗️ Running database migrations..."
bundle exec rails db:create db:migrate

# 10. Precompile assets
echo "🎨 Precompiling assets..."
bundle exec rails assets:precompile

# 11. Setup systemd service for Rails app
echo "⚙️ Setting up systemd service..."
cat > /etc/systemd/system/gate-wireguard.service << EOF
[Unit]
Description=Gate WireGuard VPN Management
After=network.target mysql.service redis.service

[Service]
Type=simple
User=ajey
WorkingDirectory=/home/ajey/workspace/gate-wireguard
Environment=RAILS_ENV=production
EnvironmentFile=/home/ajey/workspace/gate-wireguard/.env.production
ExecStart=/usr/local/bin/bundle exec puma -C config/puma.rb
Restart=always
RestartSec=1

[Install]
WantedBy=multi-user.target
EOF

# 12. Setup Nginx configuration
echo "🌐 Setting up Nginx..."
cat > /etc/nginx/sites-available/gate-wireguard << EOF
upstream gate_wireguard {
  server 127.0.0.1:3000;
}

server {
  listen 80;
  server_name your-domain.com;  # Replace with your domain
  
  root /home/ajey/workspace/gate-wireguard/public;
  
  # Serve static assets directly
  location ^~ /assets/ {
    expires 1y;
    add_header Cache-Control public;
    add_header ETag "";
    break;
  }
  
  location / {
    proxy_pass http://gate_wireguard;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }
}
EOF

# Enable the site
ln -sf /etc/nginx/sites-available/gate-wireguard /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# 13. Setup SSL with Let's Encrypt (optional but recommended)
echo "🔒 SSL setup available with: certbot --nginx -d your-domain.com"

# 14. Setup log rotation
echo "📝 Setting up log rotation..."
cat > /etc/logrotate.d/gate-wireguard << EOF
/home/ajey/workspace/gate-wireguard/log/*.log {
  daily
  missingok
  rotate 52
  compress
  delaycompress
  notifempty
  create 644 ajey ajey
  postrotate
    systemctl reload gate-wireguard
  endscript
}
EOF

# 15. Set proper permissions
echo "🔐 Setting permissions..."
chown -R ajey:ajey /home/ajey/workspace/gate-wireguard
chmod +x /home/ajey/workspace/gate-wireguard/bin/*

# 16. Start services
echo "🚀 Starting services..."
systemctl daemon-reload
systemctl enable gate-wireguard
systemctl start gate-wireguard
systemctl enable nginx
systemctl start nginx
systemctl enable redis-server
systemctl start redis-server

echo "✅ Deployment completed!"
echo ""
echo "📋 Next steps:"
echo "1. Edit .env.production with your actual credentials"
echo "2. Update Google OAuth settings with your domain"
echo "3. Run: systemctl restart gate-wireguard"
echo "4. Setup SSL: certbot --nginx -d your-domain.com"
echo "5. Configure WireGuard server settings in the admin panel"
echo ""
echo "🌐 Your app should be running at: http://your-server-ip"
echo "📊 Check status: systemctl status gate-wireguard"
echo "📝 View logs: journalctl -u gate-wireguard -f"
EOF