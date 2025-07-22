# frozen_string_literal: true

class AddServerVpnIpAddressToVpnConfiguration < ActiveRecord::Migration[7.1]
  def change
    add_column :vpn_configurations, :server_vpn_ip_address, :string
  end
end
