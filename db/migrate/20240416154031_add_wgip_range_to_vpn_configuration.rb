class AddWgipRangeToVpnConfiguration < ActiveRecord::Migration[7.1]
  def change
    add_column :vpn_configurations, :wg_ip_range, :string
  end
end
