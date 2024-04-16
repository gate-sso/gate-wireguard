class AddDnsServerToVpnConfiguration < ActiveRecord::Migration[7.1]
  def change
    add_column :vpn_configurations, :dns_servers, :string
  end
end
