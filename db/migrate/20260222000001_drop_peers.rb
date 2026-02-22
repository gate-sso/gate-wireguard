# frozen_string_literal: true

class DropPeers < ActiveRecord::Migration[8.1]
  def change
    drop_table :peers do |t|
      t.string :name, null: false, limit: 100
      t.string :vpn_ip, null: false, limit: 45
      t.string :public_key, null: false
      t.text :private_key, null: false
      t.string :dns
      t.datetime :removed_at
      t.timestamps
    end
  end
end
