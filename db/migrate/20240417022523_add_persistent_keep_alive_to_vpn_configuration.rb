# frozen_string_literal: true

class AddPersistentKeepAliveToVpnConfiguration < ActiveRecord::Migration[7.1]
  def change
    add_column :vpn_configurations, :wg_keep_alive, :string
  end
end
