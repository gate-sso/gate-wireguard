require 'open3'

class WireguardConfigGenerator
  class << self
    def generate_server_config
      private_key = `wg genkey`.strip
      public_key = `echo #{private_key} | wg pubkey`.strip
      endpoint = ""

      keys = {
        private_key: private_key,
        public_key: public_key,
        endpoint: endpoint,
        port: 51820, # This is the default port for WireGuard
        range: "10.42.5.0", # This is the default range for WireGuard
        interface_name: "wg0",  # This is the default interface name for WireGuard
        keep_alive: "25", # This is the default keep alive for WireGuard
        forward_interface: "eth0", # This is the default forward interface for WireGuard
      }

      return keys

    end

    def generate_client_keys
      # Generate a unique peer configuration for the user
      private_key = `wg genkey`.strip
      public_key = `echo #{private_key} | wg pubkey`.strip

      keys = {
        private_key: private_key,
        public_key: public_key
      }
      return keys
    end

    def write_server_configuration(vpn_configuration)
      config_dir = Rails.root.join('config', 'wireguard')
      FileUtils.mkdir_p(config_dir)
      config_file = config_dir.join("#{vpn_configuration.wg_interface_name}.conf")
      File.write(config_file, generate_config(vpn_configuration))

    end

    def generate_config (vpn_configuration)
      config = "[Interface]\n"
      config += "PrivateKey = #{vpn_configuration.wg_private_key}\n"
      config += "Address = #{vpn_configuration.server_vpn_ip_address}\n"
      config += "ListenPort = #{vpn_configuration.wg_port}\n\n"

      VpnDevice.all.each do |client|
        config += generate_peer_config(client, vpn_configuration)
      end

      config
    end

    private

    def generate_peer_config(client, vpn_configuration)

      allowed_ips = vpn_configuration.network_addresses.map(&:network_address).join(", ")

      peer_config = "[Peer]\n"
      peer_config += "# User: #{client.user.name}, Device: #{client.description}\n"
      peer_config += "PublicKey = #{client.public_key}\n"
      peer_config += "AllowedIPs = #{allowed_ips}\n"
      peer_config += "# Optionally, add a PersistentKeepalive for NAT traversal\n"
      peer_config += "PersistentKeepalive = 25\n" if vpn_configuration.wg_keep_alive.present?
      peer_config += "\n"
      peer_config
    end

    def generate_client_config(client, vpn_configuration)
      allowed_ips = vpn_configuration.network_addresses.map(&:network_address).join(", ")


      config = "[Interface]\n"
      config += "PrivateKey = #{client.private_key}\n"
      config += "Address = #{client.ip_address}\n"
      config += "DNS = #{vpn_configuration.dns_servers}\n\n" if vpn_configuration.dns_servers.present?

      config += "[Peer]\n"
      config += "PublicKey = #{vpn_configuration.wg_public_key}\n"
      config += "Endpoint = #{vpn_configuration.wg_ip_address}:#{vpn_configuration.wg_port}\n"
      config += "AllowedIPs = #{allowed_ips}\n"
      config += "PersistentKeepalive = 25\n" if vpn_configuration.wg_keep_alive.present?
      config += "\n"

      config
    end
  end
end

