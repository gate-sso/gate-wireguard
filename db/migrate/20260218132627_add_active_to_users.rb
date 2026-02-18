# frozen_string_literal: true

class AddActiveToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :active, :boolean, default: false, null: false

    reversible do |dir|
      dir.up do
        User.update_all(active: true)
      end
    end
  end
end
