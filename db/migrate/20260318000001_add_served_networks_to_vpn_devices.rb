# frozen_string_literal: true

class AddServedNetworksToVpnDevices < ActiveRecord::Migration[8.0]
  def change
    add_column :vpn_devices, :served_networks, :text
  end
end
