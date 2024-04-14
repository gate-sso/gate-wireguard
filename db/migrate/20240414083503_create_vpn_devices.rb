class CreateVpnDevices < ActiveRecord::Migration[7.1]
  def change
    create_table :vpn_devices do |t|
      t.belongs_to :user, null: false, foreign_key: true
      t.string :description
      t.string :private_key
      t.string :public_key

      t.timestamps
    end
  end
end
