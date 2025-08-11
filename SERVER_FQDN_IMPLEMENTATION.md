# WireGuard FQDN Feature Implementation

## Overview
Added a new `wg_fqdn` field to the VPN configuration to allow administrators to specify a Fully Qualified Domain Name for the VPN server.

## Changes Made

### 1. Database Migration
- Created migration: `20250811093355_add_server_fqdn_to_vpn_configurations.rb`
- Created migration: `20250811100438_rename_server_fqdn_to_wg_fqdn.rb`
- Adds `wg_fqdn` string column to `vpn_configurations` table

### 2. Controller Updates
**File:** `app/controllers/admin_controller.rb`
- Added `wg_fqdn` to the permitted parameters in `vpn_configuration_params` method
- The field can now be submitted and processed through the form

### 3. View Updates
**File:** `app/views/admin/vpn_configurations.html.erb`
- Added new form field for "Server FQDN" positioned before DNS servers
- Field includes appropriate label and placeholder text (`vpn.example.com`)
- Uses Bootstrap styling consistent with other form fields

### 4. WireGuard Configuration Generator Updates
**File:** `lib/wireguard_config_generator.rb`
- Updated `generate_server_config` method to include default DNS servers
- Modified `generate_client_config` method to prefer `wg_fqdn` over `wg_ip_address` for endpoint configuration
- Client configurations will use IP addresses as endpoints
- `WireguardConfigGenerator` gracefully handles missing `wg_fqdn` values

## Testing

The implementation includes comprehensive tests:
- Model tests for `VpnConfiguration` validation
- Controller tests for admin parameter handling and device downloads
- Feature tests for full workflow integration

Run tests with:
```bash
bundle exec rspec
```

## Configuration Priority

When generating WireGuard configurations, the system uses this priority order for endpoints:
1. `wg_fqdn` (if present and not blank)
2. `wg_ip_address` (fallback to IP)

## DNS Configuration

The system provides smart DNS defaults:
- Primary: Cloudflare (1.1.1.1)
- Secondary: Google (8.8.8.8)
- Configurable per VPN configuration

## File Download Naming

Downloaded configurations use intelligent naming:
1. FQDN-based: `example.com.conf` (if `wg_fqdn` is set)
2. IP-based: `10.0.0.1.conf` (if only IP is available)
3. Default: `wireguard.conf` (fallback)

## Usage

### For Administrators:
1. Navigate to the VPN Configuration page
2. Enter the server's FQDN in the "Server FQDN" field (e.g., `vpn.example.com`)
3. Save the configuration

### For Client Configurations:
- If `wg_fqdn` is set, client configurations will use the FQDN as the endpoint
- If `wg_fqdn` is empty, client configurations will fall back to using the IP address
- This allows for more flexible and maintainable VPN configurations

## Benefits

1. **Flexibility**: Administrators can use domain names instead of IP addresses
2. **Maintainability**: Easier to update server location without reconfiguring all clients
3. **Professional Setup**: More suitable for production environments
4. **DNS Resolution**: Allows for dynamic IP resolution through DNS

## Database Migration Required

To apply these changes, run:
```bash
bundle exec rails db:migrate
```

This will add the `wg_fqdn` column to the `vpn_configurations` table.

## Backward Compatibility

The implementation is fully backward compatible:
- Existing configurations without `wg_fqdn` will continue to work
- Client configurations will fall back to IP address if FQDN is not set
- No existing functionality is affected
