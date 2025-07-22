# frozen_string_literal: true

class AddWgForwardInterfaceToVpnConfiguration < ActiveRecord::Migration[7.1]
  def change
    add_column :vpn_configurations, :wg_forward_interface, :string
  end
end
