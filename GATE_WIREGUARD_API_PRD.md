# Gate-WireGuard API — Product Requirements Document

**Version 1.0 | February 2026 | Author: Ajey Gore**

| Field | Value |
|-------|-------|
| Project | Gate-WireGuard API |
| Status | Implementation Complete |
| Stack | Rails 8.1.2 / Ruby 4.0.1 / MySQL 8.0 |
| Host | infra01.clawstation.ai (10.5.42.1) |
| Consumer | ClawStation Container Provisioner |
| Auth | Bearer token (gw_ prefixed API keys) |

---

## 1. Overview

Gate-WireGuard is a Rails application running on infra01.clawstation.ai that manages the hub-spoke WireGuard VPN (10.5.42.0/24) connecting all ClawStation infrastructure. It currently provides a web UI with Google OAuth for manual device management.

This PRD defines a new programmatic API that allows ClawStation to automatically create and remove WireGuard peers when provisioning Incus containers on baremetal hosts. The API is the last blocking dependency for fully automated container provisioning from the ClawStation web UI.

### 1.1 Problem Statement

Today, adding a new Incus container to the ClawStation host pool requires a manual step: an administrator must sign into the Gate-WireGuard web UI, create a new VPN device, download the config, and push it to the container. This breaks the automated provisioning flow and prevents scaling.

### 1.2 Solution

Add a RESTful JSON API to Gate-WireGuard that accepts Bearer-token-authenticated requests to create, list, show, and remove WireGuard peers. The API handles keypair generation, IP allocation, live WireGuard interface updates, and config persistence automatically.

### 1.3 Success Criteria

- ClawStation can create a WireGuard peer in under 5 seconds via API call
- No manual steps required between clicking "+ Small" in the UI and a fully provisioned container
- API keys are manageable via a simple admin web UI
- All existing manual VPN device management continues to work unaffected

---

## 2. Architecture

### 2.1 Network Topology

The WireGuard VPN uses a hub-spoke topology on the 10.5.42.0/24 subnet. The hub runs on infra01.clawstation.ai (10.5.42.1) alongside CoreDNS. All spokes connect to the hub.

| Node | VPN IP | Role |
|------|--------|------|
| infra01.clawstation.ai | 10.5.42.1 | Gate-WireGuard hub + CoreDNS |
| ClawStation (Box 2) | 10.5.42.2 | Web app + MySQL + Solid Queue |
| host01-cnt01 | 10.5.42.3+ | Incus container running OpenClaw |
| host01-cnt02 | 10.5.42.4+ | Incus container running OpenClaw |

Reserved IPs: .1 (Gate-WireGuard server) and .2 (ClawStation). Allocatable range: 10.5.42.3 through 10.5.42.254 (252 peers max).

### 2.2 Integration with ClawStation

ClawStation already has a client (`GateWireguardService`) that calls this API. The contract is defined and tested. The API must return JSON matching this exact shape:

**POST /api/v1/peers — Response:**

```json
{
  "id": "uuid-string",
  "name": "host01-cnt03",
  "vpn_ip": "10.5.42.5",
  "public_key": "base64-encoded-public-key",
  "config": "[Interface]\nPrivateKey = ...\nAddress = 10.5.42.5/24\n...",
  "created_at": "2026-02-20T10:00:00Z"
}
```

The `config` field contains a complete WireGuard client configuration that ClawStation writes directly into the Incus container via Ansible.

### 2.3 End-to-End Provisioning Flow

When a SuperUser clicks "+ Small" on a baremetal host page in ClawStation:

1. ClawStation enqueues `ProvisionContainerJob`
2. `ContainerProvisioner` calls `GateWireguardService.create_peer(name: "host01-cnt03")`
3. **Gate-WireGuard API** generates keypair, allocates IP, runs `wg set`, returns config
4. Ansible creates Incus container and pushes the WireGuard config into it
5. Container joins VPN, SSH becomes reachable, OpenClaw gets deployed
6. Caddy reverse proxy configured, health check passes, station goes live

---

## 3. Data Model

### 3.1 Peer

Represents a WireGuard VPN peer (spoke). Each Incus container gets one peer.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | string(36) | PK, UUID | Auto-generated UUID |
| name | string(100) | NOT NULL, UNIQUE | Container name (e.g., host01-cnt03) |
| vpn_ip | string(45) | NOT NULL, UNIQUE | Allocated VPN IP (e.g., 10.5.42.5) |
| public_key | string(255) | NOT NULL, UNIQUE | WireGuard public key |
| private_key | string(1024) | NOT NULL, ENCRYPTED | WireGuard private key (AR encryption) |
| dns | string(255) | NULLABLE | DNS server (e.g., ns01.clawstation.ai) |
| removed_at | datetime | NULLABLE, INDEXED | Soft-delete timestamp |
| created_at | datetime | NOT NULL | Record creation time |
| updated_at | datetime | NOT NULL | Last update time |

Peers are soft-deleted (`removed_at`) rather than hard-deleted. The `.active` scope filters to non-removed peers. This preserves audit history and prevents IP reuse race conditions.

### 3.2 ApiKey

Bearer tokens for API authentication. Follows the same pattern as ClawStation's ApiKey model.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | string(36) | PK, UUID | Auto-generated UUID |
| name | string(100) | NOT NULL | Human-readable label |
| token_digest | string(64) | NOT NULL, UNIQUE | SHA256 hash of raw token |
| last_used_at | datetime | NULLABLE | Updated on each authentication |
| revoked_at | datetime | NULLABLE, INDEXED | Revocation timestamp |
| created_at | datetime | NOT NULL | Record creation time |
| updated_at | datetime | NOT NULL | Last update time |

Tokens are prefixed with `gw_` and shown once at creation. Only the SHA256 digest is stored. Authentication is O(1) via unique index lookup on `token_digest`.

---

## 4. API Specification

### 4.1 Authentication

All API endpoints require a valid Bearer token in the Authorization header:

```
Authorization: Bearer gw_<token>
```

Invalid or missing tokens return 401 Unauthorized with a JSON error body. Revoked keys are rejected.

### 4.2 Endpoints

#### POST /api/v1/peers

Creates a new WireGuard peer. Generates keypair, allocates next available VPN IP, adds peer to the live WireGuard interface, and persists the configuration.

- **Request body:** `{ "peer": { "name": "host01-cnt03", "dns": "ns01.clawstation.ai" } }`
- **Success:** 201 Created with peer JSON (`id`, `name`, `vpn_ip`, `public_key`, `config`, `created_at`)
- **Error:** 422 Unprocessable Content if name is taken or subnet is exhausted

#### GET /api/v1/peers

Lists all active (non-removed) peers, ordered by creation date descending.

- **Success:** 200 OK with JSON array of peer objects

#### GET /api/v1/peers/:id

Returns a single active peer by UUID.

- **Success:** 200 OK with peer JSON
- **Error:** 404 Not Found if peer does not exist or is removed

#### DELETE /api/v1/peers/:id

Removes a peer from the live WireGuard interface and marks it as removed in the database. Persists the updated config.

- **Success:** 200 OK (empty body)
- **Error:** 404 Not Found if peer does not exist or is already removed

---

## 5. WireguardService

The core service that handles all WireGuard operations. Wraps the `wg` CLI tool.

### 5.1 Keypair Generation

Uses the system `wg genkey` and `wg pubkey` commands via `Open3.capture2`. Raises `WireguardError` if either command fails.

### 5.2 IP Allocation

Scans the 10.5.42.3–254 range, skipping reserved IPs (.1 and .2) and any IPs currently assigned to active peers. Returns the lowest available IP. Raises `WireguardError` when the subnet is fully exhausted (252 peers maximum).

### 5.3 Live Interface Updates

After creating or removing a peer, the service runs `wg set wg0` to update the running WireGuard interface immediately. This means new peers are reachable within seconds, without restarting the VPN.

### 5.4 Config Persistence

After every change, the service runs `wg-quick strip wg0` to dump the current running config (without comments or temporary state) and writes it to `/etc/wireguard/wg0.conf`. This ensures the config survives a server reboot.

### 5.5 Error Handling

All WireGuard CLI failures raise `WireguardService::WireguardError` with a descriptive message. The API controller catches these and returns 422 with the error message.

---

## 6. API Key Management

### 6.1 Web UI

A simple admin interface at `/api_keys` allows creating, viewing, and revoking API keys. Protected by the `ADMIN_TOKEN` environment variable — pass it as a query parameter (`?admin_token=xxx`) on first access, after which it's stored in the session.

In development (`ADMIN_TOKEN` blank), the UI is accessible without authentication for convenience.

### 6.2 Token Lifecycle

- **Creation:** `ApiKey.generate(name:)` produces a `gw_` prefixed token shown once
- **Storage:** Only SHA256 digest stored in database; raw token is never persisted
- **Authentication:** `ApiKey.authenticate(token)` hashes the token, looks up the digest
- **Revocation:** `ApiKey#revoke!` sets `revoked_at`; revoked keys fail authentication
- **Usage tracking:** `last_used_at` updated on each successful authentication

### 6.3 Token Format

```
gw_<44 characters of URL-safe base64>
```

---

## 7. Implementation Files

### 7.1 Models

| File | Description |
|------|-------------|
| `app/models/peer.rb` | WireGuard peer with encrypted private_key, config generation, soft-delete |
| `app/models/api_key.rb` | Bearer token auth with gw_ prefix, SHA256 digest, revocation |
| `app/models/application_record.rb` | UUID primary keys via before_create callback |

### 7.2 Service

| File | Description |
|------|-------------|
| `app/services/wireguard_service.rb` | Keypair gen, IP allocation, wg set, config persistence |

### 7.3 Controllers

| File | Description |
|------|-------------|
| `app/controllers/api/v1/peers_controller.rb` | JSON API: create, index, show, destroy peers |
| `app/controllers/concerns/api_authentication.rb` | Bearer token auth concern |
| `app/controllers/api_keys_controller.rb` | Web UI for API key management |
| `app/controllers/health_controller.rb` | GET /health endpoint |

### 7.4 Database

| File | Description |
|------|-------------|
| `db/migrate/20260220100001_create_peers.rb` | Peers table with UUID PK, unique indexes |
| `db/migrate/20260220100002_create_api_keys.rb` | ApiKeys table with token_digest unique index |

### 7.5 Tests

| File | Coverage |
|------|----------|
| `spec/models/peer_spec.rb` | Validations, uniqueness, config generation, scopes, soft-delete |
| `spec/models/api_key_spec.rb` | Generation, authentication, revocation, usage tracking |
| `spec/services/wireguard_service_spec.rb` | Keypair gen, IP allocation, wg set stubs, persistence |
| `spec/requests/api/v1/peers_spec.rb` | Full API contract: auth, create, list, show, delete |
| `spec/requests/api_keys_spec.rb` | Admin UI access control, creation, revocation |

---

## 8. Configuration

### 8.1 Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `DB_HOST` | Yes | MySQL host (default: 127.0.0.1) |
| `WG_SERVER_PUBLIC_KEY` | Yes | WireGuard server public key for client configs |
| `WG_SERVER_ENDPOINT` | Yes | Server endpoint (default: gate.clawstation.ai:51820) |
| `WG_ALLOWED_IPS` | No | Allowed IPs in client config (default: 10.5.42.0/24) |
| `ADMIN_TOKEN` | Prod | Secret token for API key management UI access |
| `AR_ENCRYPTION_PRIMARY_KEY` | Yes | ActiveRecord encryption key (32+ chars) |
| `AR_ENCRYPTION_DETERMINISTIC_KEY` | Yes | AR deterministic encryption key |
| `AR_ENCRYPTION_KEY_DERIVATION_SALT` | Yes | AR key derivation salt |

### 8.2 ClawStation Configuration

ClawStation needs these environment variables to connect to this API:

| Variable | Example Value |
|----------|---------------|
| `GATE_WG_API_URL` | `https://gate.clawstation.ai` (or `http://10.5.42.1:3000` via VPN) |
| `GATE_WG_API_KEY` | `gw_<token created via the API key management UI>` |

---

## 9. Setup & Deployment

### 9.1 Development Setup (Lima VM)

```bash
ssh lima-default
cd ~/workspace/gate-wireguard
bundle install
bin/rails db:create db:migrate
bundle exec rspec
```

### 9.2 Database

Uses the same MySQL instance as ClawStation (root/password on 127.0.0.1:3306). Databases: `gate_wireguard_development` and `gate_wireguard_test`.

### 9.3 Production Deployment

The existing Gate-WireGuard app is already deployed on infra01.clawstation.ai via Ansible. The new API endpoints, models, and migrations need to be merged into the existing codebase and deployed with:

```bash
./deploy/install_gate.sh gate.clawstation.ai --tags update
```

---

## 10. Remaining Work & Future Enhancements

### 10.1 Immediate (Required for End-to-End)

- Run bundle install, db:migrate, and rspec in the Lima VM to verify
- Merge API code into the existing gate-wireguard codebase (which has User, VpnDevice, VpnConfiguration models)
- Create a production API key via the UI and configure `GATE_WG_API_KEY` in ClawStation
- Deploy to infra01.clawstation.ai

### 10.2 Short-Term Enhancements

- Store WireGuard peer ID on OpenClawHost for automated peer cleanup on container destruction
- Rate limiting on API endpoints via Rack::Attack
- API key scoping (read-only vs read-write) if multiple consumers emerge

### 10.3 Long-Term Vision

- Baremetal setup from ClawStation UI ("Setup Host" button runs Incus + Caddy playbooks)
- Smart container placement (prefer baremetals with most free capacity)
- Container health checks (periodic WG connectivity + OpenClaw process verification)
- Dashboard widgets showing aggregate capacity and host health across all baremetals
- Migrate existing VpnDevice model to use Peer model for unified peer management
