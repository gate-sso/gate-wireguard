class CreateNetworkAddresses < ActiveRecord::Migration[7.1]
  def change
    create_table :network_addresses do |t|
      t.references :configuration, null: false, foreign_key: true
      t.string :network_address

      t.timestamps
    end
  end
end
