class CreateIpAllocations < ActiveRecord::Migration[7.1]
  def change
    create_table :ip_allocations do |t|
      t.belongs_to :vpn_device, null: false, foreign_key: true
      t.string :ip_address

      t.timestamps
    end
  end
end
