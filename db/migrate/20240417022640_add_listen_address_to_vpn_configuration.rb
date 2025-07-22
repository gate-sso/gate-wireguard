# frozen_string_literal: true

class AddListenAddressToVpnConfiguration < ActiveRecord::Migration[7.1]
  def change
    add_column :vpn_configurations, :wg_listen_address, :string
  end
end
