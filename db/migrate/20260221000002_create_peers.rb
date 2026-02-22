# frozen_string_literal: true

class CreatePeers < ActiveRecord::Migration[8.0]
  def change
    create_table :peers do |t|
      t.string :name, null: false, limit: 100
      t.string :vpn_ip, null: false, limit: 45
      t.string :public_key, null: false, limit: 255
      t.text :private_key, null: false
      t.string :dns, limit: 255
      t.datetime :removed_at

      t.timestamps
    end

    add_index :peers, :name, unique: true
    add_index :peers, :vpn_ip, unique: true
    add_index :peers, :public_key, unique: true
    add_index :peers, :removed_at
  end
end
