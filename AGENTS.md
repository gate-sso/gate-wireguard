# AGENTS.md

Instructions for AI agents working on deployment and operations tasks.

## Deployment

### Production Deploy (Full)

Uses Ansible via `scripts/rails-production.sh`. SSHes as root, deploys app under the specified deploy user.

```bash
scripts/rails-production.sh -h <host> -u <deploy_user> -P <puma_port> -e <env_file>
```

**Parameters:**
- `-h` — Remote host (IP or hostname)
- `-u` — Deploy user on the remote box (app lives at `/home/<deploy_user>/gate-wireguard`)
- `-P` — Puma application port
- `-e` — Path to local `.env` file (see `scripts/files/env-production-example`)

**What it does:** Backs up previous release, clones from GitHub, copies `.env`, installs gems + yarn, creates MySQL database/user, runs migrations, precompiles assets, symlinks WireGuard config, creates systemd service, restarts Puma.

**Env file:** `scripts/files/env` contains production secrets (gitignored). Use `scripts/files/env-production-example` as a template.

### Quick Deploy (Code Sync)

For rapid iteration — rsyncs local code to remote without git clone:

```bash
scripts/quick-deploy.sh -h <host> -u <deploy_user> -r
```

- Omit `-r` for code sync only (no restart)
- With `-r`: runs `bundle install`, `yarn install`, `assets:precompile`, then restarts services

### Other Scripts

- `scripts/system-setup.sh` / `scripts/system-setup.yml` — System-level setup (Ruby, Node, MySQL, Redis, WireGuard)
- `scripts/caddy-production.sh` / `scripts/caddy-production.yml` — Caddy reverse proxy setup
- `scripts/rails_setup.sh` / `scripts/rails_setup.yml` — Local development setup

### Legacy Deploy (Ansible-based, `deploy/` directory)

An older Ansible deploy at `deploy/install_gate.sh` exists but the active deploy scripts are in `scripts/`.

## Server Details

- Deploy user home: `/home/<deploy_user>`
- App path: `/home/<deploy_user>/gate-wireguard`
- Gem home: `/home/<deploy_user>/.ruby`
- Node managed via NVM at `/home/<deploy_user>/.nvm`
- Systemd service: `gate_wireguard`
- WireGuard config: symlinked from `config/wireguard` to `/etc/wireguard`
- Puma logs: `<app_path>/log/puma.log`

## Pre-deploy Checklist

1. Ensure all tests pass: `bundle exec rspec`
2. Commit and push changes to `main` branch (the playbook clones from GitHub)
3. Verify SSH access: `ssh root@<host>` must work
4. Verify env file has all required variables (see `scripts/files/env-production-example`)
