# Gate-WireGuard

## Wireguard Web UI with Google Single Sign on for wireguard management

Gate-WireGuard is self sign up oauth enabled VPN server providing WireGuard as backend for client connections. it's Web-UI and configuration management
tool for wireguard server. It automatically reloads the configuration when new devices are added, and also provides a way to manage the devices.

# Production Setup

Gate-WireGuard provides automated setup scripts for production deployment on Ubuntu/Debian systems. The setup process follows a three-stage approach: Database → WireGuard → Application.

## Quick Start

For a complete production deployment, simply run:

```bash
./setup.sh
```

This will guide you through the entire setup process with interactive prompts.

## Setup Components

### 1. Database Configuration

The setup script provides two database options:

**Option A: Install MySQL Locally**
- Automatically installs and configures MySQL server
- Creates production database and user with provided credentials
- Configures proper security settings

**Option B: Use Existing MySQL Server**
- Connects to your existing MySQL server
- Verifies connection before proceeding
- Creates production database if it doesn't exist

**Interactive Setup:**
```bash
# You'll be prompted for:
- Database choice (local/remote)
- MySQL username and password
- Database name (defaults to gate_wireguard_production)
- Server address (for remote MySQL)
```

### 2. User Management

**Application User Configuration:**
- Install as current user (default)
- Or specify a different user (creates if doesn't exist)
- Handles proper file ownership and permissions
- Sets up Ruby environment for the specified user

### 3. Production Environment Setup

**What Gets Installed:**
- ✅ MySQL database (local or remote connection verified)
- ✅ WireGuard VPN server with configuration watcher
- ✅ Ruby environment (rbenv + Ruby 3.3.4)
- ✅ Rails application in production mode
- ✅ Redis cache server
- ✅ Node.js and asset compilation tools
- ✅ Nginx web server

## Individual Component Setup

You can also run individual components:

```bash
# Database configuration only
./setup.sh --database-only

# WireGuard infrastructure only
./setup.sh --wireguard-only

# Rails application only
./setup.sh --application-only
```

## Production Configuration

### Environment Variables

The setup creates a production `.env` file with:

```bash
# Rails Environment
RAILS_ENV=production

# Database Configuration (auto-configured)
DATABASE_URL=mysql2://username:password@host/database_name

# Redis Configuration
REDIS_URL=redis://localhost:6379/0

# Secret Key Base (auto-generated)
SECRET_KEY_BASE=your_generated_secret

# Google OAuth (configure these manually)
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret



# Production Settings
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
```

### Required Manual Configuration

After setup completion, you'll need to configure:

1. **Google OAuth Credentials**
   - Create OAuth app in Google Cloud Console
   - Update `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` in `.env`

2. **SSL Certificates**
   - Configure SSL certificates for HTTPS
   - Update Nginx configuration

3. **Domain Configuration**
   - Point your domain to the server
   - Configure Nginx virtual host

## Service Management

### Starting Services

```bash
# Check service status
sudo systemctl status wg-quick@wg0              # WireGuard
sudo systemctl status wireguard-conf-watcher    # Config watcher
sudo systemctl status mysql                     # Database
sudo systemctl status redis-server              # Cache
sudo systemctl status nginx                     # Web server

# Start Rails application (production)
sudo -u [app_user] bash -c 'cd /path/to/app && bundle exec rails server -e production'
```

### Configuration Files

- **WireGuard**: `/etc/wireguard/wg0.conf`
- **Application**: `/path/to/app/.env`
- **Nginx**: `/etc/nginx/sites-available/gate-wireguard`

## Security Considerations

- Environment file permissions set to 600 (secure)
- Application runs under dedicated user (if specified)
- Database connections use dedicated credentials
- Firewall rules configured for WireGuard (port 51820)

## Troubleshooting

### Database Connection Issues
```bash
# Test MySQL connection
mysql -h host -u username -p database_name
```

### Service Status
```bash
# Check all services
sudo systemctl list-units --state=active | grep -E "(mysql|redis|nginx|wg-quick|wireguard)"
```

### Application Logs
```bash
# Rails logs
tail -f /path/to/app/log/production.log

# System logs
sudo journalctl -u wg-quick@wg0 -f
sudo journalctl -u wireguard-conf-watcher -f
```

## Post-Setup Steps

1. **Configure WireGuard Network Settings**
   - Access the web interface
   - Set up your public endpoint
   - Configure private IP ranges
   - Save and generate configuration

2. **Add VPN Devices**
   - Sign in with Google OAuth
   - Add devices through the web interface
   - Download configuration files for clients

3. **Set Up Monitoring**
   - Configure log rotation
   - Set up system monitoring
   - Configure backup strategies

---

# Development Setup

For local development, use the development setup process below:

## Development

1. Checkout gate-wireguard, and run the following commands to get it running

```bash
scripts/rails_setup.sh
```

1. Checkout gate-wireguard, and run the following commands to get it running

```bash
scripts/rails_setup.sh
```

if you need to setup docker as well, because we need compose plugin, please use following script to setup docker.

```bash
sh scripts/docker_setup.sh
```

2. Docker in only required if you do not want to install mysql on local server, else you can just install mysql server
   - to run docker, just run `docker compose up db -d` and you are good to go
3. Setup gate_wireguard_dev database in mysql for non-root users, for dev you can use root user as well.
   |

   ```sql
   create database gate_wireguard_dev;
   grant all privileges on gate_wireguard_dev to 'gate_wireguard'@% idenfied by 'gate_wireguard';
   create database gate_wireguard_test;
   grant all privileges on gate_wireguard_test to 'gate_wireguard'@% identified by 'gate_wireguard';
   ```

4. Run `rails db:create db:migrate` to create the database and run the migrations
5. If you rather want to use root user root@localhost just do the following.

   ```sudo mysql -u root -p
   ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';
       FLUSH PRIVILEGES;
   ```

6. Setup RubyLSP and watchman and then execute

```shell
bundle exec srb typecheck --lsp
```

---

### Deployment Summary

- Ruby version - 3.0.2p107
- System dependencies

  - mysql header
  - nodejs
  - install gems - rails and bundler

- Configuration

  - database configuration

- Database creation

  - mysql command as given above

- Database initialization

  - rails db:create db:migrate

- How to run the test suite

  - rspec

- Services (job queues, cache servers, search engines, etc.)

  - docker-compose up

- Deployment instructions - You can setup gate-wireguard with or without docker, with docker, it's just docker-compose, without docker, please follow the steps below
  - checkout latest tar, run ./setup_production.sh
  - run ./configure_production.sh (this will create database etc)

#### Useful commands

If you are doing local development and you need to sync the file to remote box as they change, following command can be useful for running rails server that automatically gets new files

```shell
watchmedo shell-command \
    --recursive \
    --command='echo "${watch_src_path}"' \
    /some/folder
```

If you running Ubuntu and have "ruby-full" package, and want to install gems locally, following commands are useful

```shell
echo 'export GEM_HOME=~/.ruby/' >> ~/.bashrc
echo 'export PATH="$PATH:~/.ruby/bin"' >> ~/.bashrc
source ~/.bashrc
```

You may end up getting application.css not found error. in that case please install yarn

```shell
npm install yarn
#or
npm install --global yarn
yarn add sass
yarn build:css
```

This is a know problem with Yarn, Bootstrap and Rails 7 combo.

If you want to install newer node framework, required for this repo

```shell
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
. ~/.nvm/nvm.sh
nvm install 20
```

If you are not able to get ruby to build and compile, use rvm on macos and then

```bash
brew install ruby-build
brew install openssl@1.1
export PKG_CONFIG_PATH=/usr/local/opt/openssl@1.1/lib/pkgconfig/
rvm install 3.0.2 --with-openssl-dir=/usr/local/opt/openssl@1.1
#for rbenv
RUBY_CONFIGURE_OPTS=--with-openssl-dir=/usr/local/opt/openssl@1.1
rbenv install 3.0.2
```

On Mac installing Ruby

```
rvm install ruby-3.3.4 --reconfigure --enable-yjit --with-openssl-dir=$(brew --prefix openssl@3.0)
```

Also, please read brew's post install messages to be able to install ruby 3.0.2 successfully

Getting wireguard to work inside lxc containers you need to use [proxy device](https://linuxcontainers.org/incus/docs/main/reference/devices_proxy/)W

```bash
incus config device add gate <udp51820> proxy listen=udp:0.0.0.0:51820 connect=udp:0.0.0.0:51820
incus config device add gate tcp8080 proxy listen=tcp:0.0.0.0:8080 connect=tcp:0.0.0.0:8080

```

Also, once you have wireguard setup, you need to be able to accept the traffic, and source nat it.

```bash
sudo iptables -A FORWARD -i wg0 -o eth0 -j ACCEPT
sudo iptables -t nat -A POSTROUTING -o eth0 -j SNAT --to-source <the lan interface>
sudo iptables -t nat -A POSTROUTING -o eth0@if16 -j SNAT --to-source <the lan/vpc interface>
```

We use snat because we are using a private ip address, and we need to masquerade it to the routable return address for the server.

So our traffic works like this, here is ascii diagram for VPN Client -> VPN Server -> Local Network

```
+-----------------+        +-----------------+        +-----------------+
|                 |        |                 |        |                 |
|  VPN Client     |------->|  VPN Server     |------->|  Local Network  |
|                 |        |                 |        |                 |
+-----------------+        +-----------------+        +-----------------+
        VPN Traffic       wg0    VPN Traffic  eth0       Local Traffic
```

so in this case SNAT address will be the eth0 address of the VPN Server, and the return traffic will be sent to the VPN Server, which will then forward it to the VPN Client.

#### Credits

OpenSource is not possible without people contributing to it, The following posts, resources have helped me immensely to get this going off the ground. Some credits to internet reading material for helping me with various tasks

- Ryan Bigg - [Adding bootstrap to rails](https://ryanbigg.com/2023/04/rails-7-bootstrap-css-javascript-with-esbuild)
