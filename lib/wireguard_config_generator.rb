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
        endpoint: endpoint
      }

      return keys


    end
    def generate_config(user_id)
      # Generate a unique peer configuration for the user
      private_key = `wg genkey`.strip
      public_key = `echo #{private_key} | wg pubkey`.strip
      endpoint = 'your_server_public_ip:51820'
      allowed_ips = '0.0.0.0/0, ::/0'

      # Write the configuration to a file
      config_dir = Rails.root.join('config', 'wireguard')
      FileUtils.mkdir_p(config_dir)
      config_file = config_dir.join("user_#{user_id}.conf")
      File.write(config_file, <<~CONF)
        [Interface]
        PrivateKey = #{private_key}
        Address = 10.0.0.#{rand(2..254)}/24
        DNS = 8.8.8.8, 8.8.4.4

        [Peer]
        PublicKey = #{public_key}
        Endpoint = #{endpoint}
        AllowedIPs = #{allowed_ips}
      CONF

      config_file
    end
  end
end