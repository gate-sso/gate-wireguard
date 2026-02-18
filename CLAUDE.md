# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Gate-WireGuard is a Rails 8.0.2 web application for managing WireGuard VPN servers with Google OAuth self-signup. Users create VPN devices, get allocated IPs, and download/scan WireGuard configs. Admins configure server settings, manage users, and perform backups.

**Stack:** Ruby 3.3.4, Rails 8.0.2, MySQL, Redis, Bootstrap 5.3.3, Stimulus.js, Hotwire Turbo

## Commands

### Development

```bash
# Start MySQL and Redis containers (MySQL on 3306, Redis on 16379->6379)
docker compose up db redis -d

# Database setup
rails db:create db:migrate

# Start dev server (Rails + CSS watcher)
foreman start -f Procfile.dev

# CSS only
yarn build:css          # compile once
yarn watch:css          # watch mode
```

### Testing

```bash
bundle exec rspec                                        # all tests
bundle exec rspec spec/models/vpn_configuration_spec.rb  # single file
bundle exec rspec spec/models/ spec/requests/            # directories
RAILS_ENV=test rails db:create db:migrate                # test DB setup
```

### Linting

```bash
bundle exec rubocop        # check
bundle exec rubocop -A     # auto-correct
```

RuboCop config: max line length 120, method length 20, ABC size 30. ERB views and `lib/` are excluded from linting. Also uses `rubocop-rspec` and `rubocop-rspec_rails` plugins.

### Type Checking (Sorbet)

```bash
bundle exec srb typecheck --lsp    # requires watchman installed on system
```

## Architecture

### Authentication Flow

Google OAuth2 via OmniAuth. `SessionsController#create` handles the callback, stores user in session. `ApplicationController` provides `current_user` and `require_login` filter. Admin access is controlled by `user.admin?` flag.

### Core Domain Model

```
User --has_many--> VpnDevice --has_one--> IpAllocation
User --has_many--> DnsRecord
VpnConfiguration (singleton) --has_many--> NetworkAddress
```

- **VpnConfiguration**: single server config record — endpoint, keys, IP range, DNS, interface settings
- **VpnDevice**: user device with WireGuard keypair and allocated IP; generates QR codes via `rqrcode`
- **IpAllocation**: automatic IP assignment from the configured range
- **DnsRecord**: per-user DNS entries stored in Redis via `dns_redis.rb` initializer

### Config Generation

`lib/wireguard_config_generator.rb` generates both server and client WireGuard configs. Controllers use `after_action :update_wireguard_config` to regenerate the server config file whenever devices or VPN settings change. Key generation requires the `wg` CLI tool installed on the host (uses `wg genkey` and `wg pubkey` via `Open3`). Generated server configs are written to `config/wireguard/`.

### Key Controllers

- **AdminController** — dashboard, user management, VPN server configuration, network address routes
- **VpnDevicesController** — device CRUD, config download, QR display; scoped to current user (admins see all)
- **DnsRecordsController** — DNS record CRUD with Redis zone sync
- **Admin::BackupsController** — backup/restore system

### Frontend

Bootstrap 5.3.3 with custom SCSS (`app/assets/stylesheets/`), compiled via `cssbundling-rails`. Stimulus controllers in `app/javascript/controllers/`. Dark mode support with localStorage persistence. Two layouts: `admin.html.erb` (authenticated) and `application.html.erb` (public/login).

### Environment Variables

See `.env.sample` for required vars: `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GATE_REDIS_HOST`, `GATE_REDIS_PORT`, `GATE_DNS_ZONE`. Production additionally needs `GATE_DATABASE`, `GATE_DATABASE_USER`, `GATE_DATABASE_PASSWORD`.

### Deployment

Production deploys use Ansible via `./deploy/install_gate.sh <hostname>`. See `deploy/` directory and `README.md` for full options including `--tags update` (code-only update), `--tags ssl` (fix SSL), and `--configure` (re-configure settings). Server config with secrets is stored in `deploy/servers/<host>.yml` (gitignored).
