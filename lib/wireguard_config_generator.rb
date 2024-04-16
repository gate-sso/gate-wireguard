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
        port: 51820,
        range: "10.42.5.0"
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

      # Write the configuration to a file
      # config_dir = Rails.root.join('config', 'wireguard')
      # FileUtils.mkdir_p(config_dir)
      # config_file = config_dir.join("user_#{user_id}.conf")
      # File.write(config_file, <<~CONF)
      #   [Interface]
      #   PrivateKey = #{private_key}
      #   Address = 10.0.0.#{rand(2..254)}/24
      #   DNS = 8.8.8.8, 8.8.4.4
      #
      #   [Peer]
      #   PublicKey = #{public_key}
      #   Endpoint = #{endpoint}
      #   AllowedIPs = #{allowed_ips}
      # CONF
    end

    def write_configuration
      config_dir = Rails.root.join('config', 'wireguard')
      FileUtils.mkdir_p(config_dir)
      config_file = config_dir.join("user_#{user_id}.conf")
      File.write(config_file, <<~CONF)
        [Interface]
        PrivateKey = #{private_key}
        Address = 10.0.0.#{rand(2..254)}/24
        DNS =
        [Peer]
        PublicKey = #{public_key}
        Endpoint = #{endpoint}
        AllowedIPs = #{allowed_ips}
      CONF
    end
  end
end