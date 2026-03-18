# typed: true
# frozen_string_literal: true

require 'ipaddr'

# Purpose: Model for VPN configuration.
# This model is used to store the configuration details of the VPN server.
class VpnConfiguration < ApplicationRecord
  extend T::Sig

  has_many :network_addresses, dependent: :destroy

  validate :validate_range_shrinkage

  sig { returns(Integer) }
  def cidr_prefix
    range = wg_ip_range
    return 24 if range.blank?

    if range.include?('/')
      range.split('/').last.to_i
    else
      24
    end
  end

  sig { returns(T.nilable(String)) }
  def network_address_base
    range = wg_ip_range
    return range if range.blank?

    range.split('/').first
  end

  sig { returns(VpnConfiguration) }
  def self.get_vpn_configuration # rubocop:disable Naming/AccessorMethodName
    @vpn_configurations = VpnConfiguration.all
    if @vpn_configurations.empty?
      configure_vpn
    else
      T.must(@vpn_configurations.first)
    end
  end

  sig { returns(VpnConfiguration) }
  def self.configure_vpn
    @vpn_configuration = VpnConfiguration.new
    keys = WireguardConfigGenerator.generate_server_config
    @vpn_configuration.wg_private_key = keys[:private_key]
    @vpn_configuration.wg_public_key = keys[:public_key]
    @vpn_configuration.wg_port = keys[:port]
    @vpn_configuration.wg_ip_range = keys[:range]
    @vpn_configuration.dns_servers = keys[:dns_servers]
    @vpn_configuration.wg_interface_name = keys[:interface_name]
    @vpn_configuration.wg_keep_alive = keys[:keep_alive]
    @vpn_configuration.wg_forward_interface = keys[:forward_interface]
    @vpn_configuration.save!
    @network_address = NetworkAddress.new
    @network_address.vpn_configuration_id = @vpn_configuration.id
    @network_address.save!
    @vpn_configuration
  end

  private

  sig { void }
  def validate_range_shrinkage
    return if wg_ip_range.blank?
    return unless wg_ip_range_changed?

    new_range = IPAddr.new(wg_ip_range)
    validate_allocation_bounds(new_range)
    validate_node_overlap(new_range)
  rescue IPAddr::InvalidAddressError
    errors.add(:wg_ip_range, 'is an invalid CIDR address')
  end

  sig { params(new_range: IPAddr).void }
  def validate_allocation_bounds(new_range)
    # We must check ALL allocations (including unallocated/recycled ones)
    # because IpAllocation.next_fresh_ip relies on the total count as a high-water mark.
    T.unsafe(IpAllocation).find_each do |allocation|
      unless new_range.include?(IPAddr.new(allocation.ip_address))
        errors.add(:wg_ip_range,
                   "cannot shrink: allocation #{allocation.ip_address} would be outside the new range")
      end
    end
  end

  sig { params(new_range: IPAddr).void }
  def validate_node_overlap(new_range)
    VpnDevice.where(node: true).find_each do |node|
      node.served_networks_list.each do |cidr|
        served_net = IPAddr.new(cidr)
        if new_range.include?(served_net) || served_net.include?(new_range)
          errors.add(:wg_ip_range,
                     "overlaps with #{cidr} served by node '#{node.description}'")
        end
      rescue IPAddr::InvalidAddressError
        next
      end
    end
  end
end
