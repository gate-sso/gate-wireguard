# frozen_string_literal: true

require 'open3'
# WireGuard config generator, this expects you to have wg utility installed on the same box for generating keys
class WireguardConfigGenerator
  class << self
    def generate_server_config # rubocop:disable Metrics/MethodLength
      keys = generate_keys

      {
        private_key: keys[:private_key],
        public_key: keys[:public_key],
        endpoint: '',
        port: 51_820, # This is the default port for WireGuard
        range: '10.42.5.0', # This is the default range for WireGuard
        interface_name: 'wg0', # This is the default interface name for WireGuard
        keep_alive: '25', # This is the default keep alive for WireGuard
        forward_interface: 'eth0', # This is the default forward interface for WireGuard
        dns_servers: nil # Let admin configure DNS servers through the interface
      }
    end

    def generate_client_config(client, vpn_configuration) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      vpn_configuration.network_addresses.map(&:network_address).join(', ')
      config = "[Interface]\n"
      config += "PrivateKey = #{client.private_key}\n"
      config += "Address = #{client.ip_allocation.ip_address}/24\n"
      
      # Use configured DNS servers, or default to Google DNS if none are set
      dns_servers = vpn_configuration.dns_servers.present? ? vpn_configuration.dns_servers : '8.8.8.8, 8.8.4.4'
      config += "DNS = #{dns_servers}\n\n"

      config += "[Peer]\n"
      config += "PublicKey = #{vpn_configuration.wg_public_key}\n"
      # Use wg_fqdn if available, otherwise fall back to wg_ip_address
      endpoint = vpn_configuration.wg_fqdn.present? ? vpn_configuration.wg_fqdn : vpn_configuration.wg_ip_address
      config += "Endpoint = #{endpoint}:#{vpn_configuration.wg_port}\n"
      config += "AllowedIPs = #{vpn_configuration.server_vpn_ip_address}/32\n"
      vpn_configuration.network_addresses.each do |ip_address|
        config += "AllowedIPs = #{ip_address.network_address}\n"
      end
      config += "PersistentKeepalive = 20\n" if vpn_configuration.wg_keep_alive.present?
      config += "\n"

      config
    end

    def generate_keys
      private_key = Open3.capture2('wg genkey')[0].strip
      public_key = Open3.capture2('wg pubkey', stdin_data: private_key)[0].strip
      {
        private_key: private_key,
        public_key: public_key
      }
    end

    def write_server_configuration(vpn_configuration)
      config_dir = Rails.root.join('config', 'wireguard')
      FileUtils.mkdir_p(config_dir)
      config_file = config_dir.join("#{vpn_configuration.wg_interface_name}.conf")
      File.write(config_file, generate_config(vpn_configuration))

      private_key_file = config_dir.join('private.key')
      File.write(private_key_file, vpn_configuration.wg_private_key)

      public_key_file = config_dir.join('public.key')
      File.write(public_key_file, vpn_configuration.wg_public_key)
    end

    def generate_config(vpn_configuration)
      config = "[Interface]\n"
      config += "PrivateKey = #{vpn_configuration.wg_private_key}\n"
      config += "ListenPort = #{vpn_configuration.wg_port}\n"
      config += "Address = #{vpn_configuration.server_vpn_ip_address}/24 \n\n"

      VpnDevice.all.each do |client|
        config += generate_peer_config(client, vpn_configuration)
      end

      config
    end

    private

    def generate_peer_config(client, vpn_configuration)
      peer_config = "# User: #{client.user.name}, Device: #{client.description}\n"
      peer_config += "[Peer]\n"
      peer_config += "PublicKey = #{client.public_key}\n"
      peer_config += "AllowedIPs = #{client.ip_allocation.ip_address}/32\n"
      peer_config += "# Optionally, add a PersistentKeepalive for NAT traversal\n"
      peer_config += "PersistentKeepalive = 25\n" if vpn_configuration.wg_keep_alive.present?
      peer_config += "\n\n"
      peer_config
    end
  end
end
