class AddNodeToVpnDevice < ActiveRecord::Migration[7.1]
  def change
    add_column :vpn_devices, :node, :boolean
  end
end
