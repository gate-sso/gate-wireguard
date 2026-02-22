# frozen_string_literal: true

require 'open3'

class WireguardService
  class WireguardError < StandardError; end

  VPN_SUBNET = '10.5.42'
  RESERVED_IPS = [1, 2].freeze
  WG_INTERFACE = 'wg0'
  WG_CONFIG_PATH = '/etc/wireguard/wg0.conf'

  class << self
    def create_peer!(name:, dns: nil)
      keypair = generate_keypair
      vpn_ip = allocate_ip!

      peer = Peer.create!(
        name: name,
        vpn_ip: vpn_ip,
        public_key: keypair[:public_key],
        private_key: keypair[:private_key],
        dns: dns
      )

      add_peer_to_wireguard(peer)
      persist_config!

      peer
    rescue ActiveRecord::RecordInvalid => e
      raise WireguardError, "Failed to create peer: #{e.message}"
    end

    def remove_peer!(peer)
      remove_peer_from_wireguard(peer)
      persist_config!
      peer.remove!
    end

    def generate_keypair
      private_key, status = Open3.capture2('wg', 'genkey')
      raise WireguardError, 'Failed to generate private key' unless status.success?

      private_key = private_key.strip

      public_key, status = Open3.capture2('wg', 'pubkey', stdin_data: private_key)
      raise WireguardError, 'Failed to derive public key' unless status.success?

      { private_key: private_key, public_key: public_key.strip }
    end

    def allocate_ip!
      used_ips = Peer.active.pluck(:vpn_ip).map { |ip| ip.split('.').last.to_i }
      all_reserved = RESERVED_IPS + used_ips

      next_octet = (3..254).find { |n| !all_reserved.include?(n) }
      raise WireguardError, "No available VPN IPs in #{VPN_SUBNET}.0/24 subnet" if next_octet.nil?

      "#{VPN_SUBNET}.#{next_octet}"
    end

    private

    def add_peer_to_wireguard(peer)
      cmd = ['wg', 'set', WG_INTERFACE, 'peer', peer.public_key, 'allowed-ips', "#{peer.vpn_ip}/32"]

      _output, status = Open3.capture2e(*cmd)
      raise WireguardError, "Failed to add peer to WireGuard: wg set returned #{status.exitstatus}" unless status.success?
    end

    def remove_peer_from_wireguard(peer)
      cmd = ['wg', 'set', WG_INTERFACE, 'peer', peer.public_key, 'remove']

      _output, status = Open3.capture2e(*cmd)
      return if status.success?

      raise WireguardError, "Failed to remove peer from WireGuard: wg set returned #{status.exitstatus}"
    end

    def persist_config!
      cmd = "wg-quick strip #{WG_INTERFACE} > #{WG_CONFIG_PATH}.tmp && mv #{WG_CONFIG_PATH}.tmp #{WG_CONFIG_PATH}"

      _output, status = Open3.capture2e('bash', '-c', cmd)
      raise WireguardError, 'Failed to persist WireGuard config' unless status.success?
    end
  end
end
