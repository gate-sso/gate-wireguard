class AddUserIdToDnsRecord < ActiveRecord::Migration[7.1]
  def change
    add_column :dns_records, :user_id, :bigint
  end
end
