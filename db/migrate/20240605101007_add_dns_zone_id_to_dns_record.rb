class AddDnsZoneIdToDnsRecord < ActiveRecord::Migration[7.1]
  def change
    add_column :dns_records, :dns_zone_id, :bigint
  end
end
