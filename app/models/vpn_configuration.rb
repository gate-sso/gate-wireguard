# frozen_string_literal: true

# Purpose: Model for VPN configuration.
# This model is used to store the configuration details of the VPN server.
class VpnConfiguration < ApplicationRecord
  has_many :network_addresses, dependent: :destroy

  def self.get_vpn_configuration # rubocop:disable Naming/AccessorMethodName
    @vpn_configurations = VpnConfiguration.all
    if @vpn_configurations.empty?
      configure_vpn
    else
      @vpn_configurations.first
    end
  end

  def self.configure_vpn # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
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
end
