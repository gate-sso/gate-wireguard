# frozen_string_literal: true

class CreateNetworkAddresses < ActiveRecord::Migration[7.1]
  def change
    create_table :network_addresses do |t|
      t.belongs_to :vpn_configuration, null: false, foreign_key: true
      t.string :network_address
      t.timestamps
    end
  end
end
