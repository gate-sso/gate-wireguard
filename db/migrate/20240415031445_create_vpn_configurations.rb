# frozen_string_literal: true

class CreateVpnConfigurations < ActiveRecord::Migration[7.1]
  def change
    create_table :vpn_configurations do |t|
      t.string :wg_private_key
      t.string :wg_public_key
      t.string :wg_ip_address
      t.string :wg_port

      t.timestamps
    end
  end
end
