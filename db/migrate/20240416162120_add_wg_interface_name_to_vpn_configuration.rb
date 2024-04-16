class AddWgInterfaceNameToVpnConfiguration < ActiveRecord::Migration[7.1]
  def change
    add_column :vpn_configurations, :wg_interface_name, :string
  end
end
