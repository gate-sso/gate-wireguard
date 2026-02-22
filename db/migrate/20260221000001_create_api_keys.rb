# frozen_string_literal: true

class CreateApiKeys < ActiveRecord::Migration[8.0]
  def change
    create_table :api_keys do |t|
      t.string :name, null: false, limit: 100
      t.string :token_digest, null: false, limit: 64
      t.datetime :last_used_at
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :api_keys, :token_digest, unique: true
    add_index :api_keys, :revoked_at
  end
end
