# frozen_string_literal: true

class CreateDnsRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :dns_records do |t|
      t.string :host_name
      t.string :ip_address

      t.timestamps
    end
  end
end
