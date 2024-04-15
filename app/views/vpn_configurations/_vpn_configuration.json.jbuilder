json.extract! vpn_configuration, :id, :wg_private_key, :wg_public_key, :wg_ip_address, :wg_port, :created_at, :updated_at
json.url vpn_configuration_url(vpn_configuration, format: :json)
