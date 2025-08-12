# frozen_string_literal: true

class AddServerFqdnToVpnConfigurations < ActiveRecord::Migration[8.0]
  def change
    add_column :vpn_configurations, :server_fqdn, :string
  end
end
