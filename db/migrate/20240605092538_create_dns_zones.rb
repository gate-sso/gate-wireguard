class CreateDnsZones < ActiveRecord::Migration[7.1]
  def change
    create_table :dns_zones do |t|
      t.string :name

      t.timestamps
    end
  end
end
