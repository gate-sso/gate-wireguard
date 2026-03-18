# typed: true
# frozen_string_literal: true

require 'open3'

# Reads real-time WireGuard peer status from `wg show` command.
# Returns per-device status including online/offline, transfer, and last handshake.
class WireguardStatus
  extend T::Sig

  ONLINE_THRESHOLD = 180 # seconds — WireGuard handshake is stale after 3 minutes

  sig { returns(T::Hash[String, T::Hash[Symbol, T.untyped]]) }
  def self.fetch
    output = read_wg_dump
    parse_dump(output)
  end

  sig { returns(T::Array[T::Hash[Symbol, T.untyped]]) }
  def self.device_statuses
    peers = fetch
    VpnDevice.includes(:ip_allocation, :user).find_each.map do |device|
      peer = peers[device.public_key] || {}
      {
        id: device.id,
        description: device.description,
        public_key: device.public_key,
        ip: device.ip_allocation&.ip_address,
        node: device.node?,
        user_name: device.user&.name,
        online: peer_online?(peer),
        last_handshake: peer[:latest_handshake],
        last_handshake_ago: handshake_ago(peer[:latest_handshake]),
        endpoint: peer[:endpoint],
        rx_bytes: peer[:rx_bytes] || 0,
        tx_bytes: peer[:tx_bytes] || 0
      }
    end
  end

  sig { returns(Integer) }
  def self.online_count
    peers = fetch
    now = Time.now.to_i
    peers.count { |_key, peer| peer_online?(peer) }
  end

  sig { params(peer: T::Hash[Symbol, T.untyped]).returns(T::Boolean) }
  def self.peer_online?(peer)
    return false unless peer[:latest_handshake].is_a?(Integer) && peer[:latest_handshake].positive?

    (Time.now.to_i - peer[:latest_handshake]) < ONLINE_THRESHOLD
  end

  sig { params(timestamp: T.untyped).returns(T.nilable(String)) }
  def self.handshake_ago(timestamp)
    return nil unless timestamp.is_a?(Integer) && timestamp.positive?

    seconds = Time.now.to_i - timestamp
    if seconds < 60
      "#{seconds}s ago"
    elsif seconds < 3600
      "#{seconds / 60}m ago"
    elsif seconds < 86_400
      "#{seconds / 3600}h ago"
    else
      "#{seconds / 86_400}d ago"
    end
  end

  class << self
    extend T::Sig

    private

    sig { returns(String) }
    def read_wg_dump
      interface = VpnConfiguration.first&.wg_interface_name || 'wg0'
      stdout, _stderr, _status = Open3.capture3("sudo wg show #{interface} dump")
      stdout
    rescue Errno::ENOENT
      ''
    end

    sig { params(output: String).returns(T::Hash[String, T::Hash[Symbol, T.untyped]]) }
    def parse_dump(output)
      peers = {}
      lines = output.strip.split("\n")
      # First line is the interface itself, skip it
      lines.drop(1).each do |line|
        fields = line.split("\t")
        next if fields.length < 8

        public_key = fields[0]
        peers[public_key] = {
          endpoint: fields[2] == '(none)' ? nil : fields[2],
          allowed_ips: fields[3],
          latest_handshake: fields[4].to_i,
          rx_bytes: fields[5].to_i,
          tx_bytes: fields[6].to_i,
          keepalive: fields[7].to_i
        }
      end
      peers
    end
  end
end
