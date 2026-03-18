# typed: true
# frozen_string_literal: true

require 'ipaddr'

# This model takes care of VPN Devices
class VpnDevice < ApplicationRecord
  extend T::Sig

  belongs_to :user
  has_one :ip_allocation, dependent: nil

  before_destroy :release_ip_allocation

  validate :validate_served_networks

  sig { returns(T::Array[String]) }
  def served_networks_list
    networks = served_networks
    return [] if networks.blank?

    networks.split(',').map(&:strip).compact_blank
  end

  sig { void }
  def setup_device_with_keys
    @keys = WireguardConfigGenerator.generate_keys
    self.public_key = @keys[:public_key]
    self.private_key = @keys[:private_key]
  end

  sig { returns(String) }
  def generate_qr_code
    raise 'QR codes are not supported for infrastructure nodes' if node?

    qr = RQRCode::QRCode.new(WireguardConfigGenerator.generate_client_config(self, VpnConfiguration.first))
    qr.as_svg(
      offset: 0,
      color: '000',
      shape_rendering: 'crispEdges',
      module_size: 2,
      level: 1
    )
  end

  private

  sig { void }
  def release_ip_allocation
    IpAllocation.deallocate_ip(self)
  end

  sig { void }
  def validate_served_networks
    return if served_networks.blank?
    return unless served_networks_changed?
    return unless node?

    vpn_config = VpnConfiguration.first
    vpn_range = vpn_config ? IPAddr.new(vpn_config.wg_ip_range) : nil

    served_networks_list.each do |cidr|
      validate_network_vpn_overlap(cidr, vpn_range, vpn_config)
      validate_network_node_overlap(cidr)
    rescue IPAddr::InvalidAddressError
      errors.add(:served_networks, "contains an invalid CIDR address: #{cidr}")
    end
  end

  sig { params(cidr: String, vpn_range: T.nilable(IPAddr), vpn_config: T.untyped).void }
  def validate_network_vpn_overlap(cidr, vpn_range, vpn_config)
    network = IPAddr.new(cidr)
    return unless vpn_range && (vpn_range.include?(network) || network.include?(vpn_range))

    errors.add(:served_networks, "cannot overlap with the VPN subnet (#{vpn_config.wg_ip_range})")
  end

  sig { params(cidr: String).void }
  def validate_network_node_overlap(cidr)
    network = IPAddr.new(cidr)
    other_nodes = VpnDevice.where(node: true).where.not(id: id)

    other_nodes.find_each do |other_node|
      conflict = other_node.served_networks_list.find do |other_cidr|
        other_net = IPAddr.new(other_cidr)
        network.include?(other_net) || other_net.include?(network)
      rescue IPAddr::InvalidAddressError
        false
      end
      if conflict
        errors.add(:served_networks,
                   "#{cidr} overlaps with #{conflict} already served by node '#{other_node.description}'")
        break
      end
    end
  end
end
