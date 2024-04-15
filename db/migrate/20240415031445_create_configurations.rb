class CreateConfigurations < ActiveRecord::Migration[7.1]
  def change
    create_table :configurations do |t|
      t.string :wg_private_key
      t.string :wg_public_key
      t.string :wg_ip_address
      t.string :wg_port

      t.timestamps
    end
  end
end
