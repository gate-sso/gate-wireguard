class RenameConfigurationToVpnConfiguration < ActiveRecord::Migration[7.1]
  def change
    rename_table :configurations, :vpn_configurations
  end
end
