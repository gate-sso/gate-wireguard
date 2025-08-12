# frozen_string_literal: true

class AddAdminToUsers < ActiveRecord::Migration[7.1]
  def change
    # rubocop:disable Rails/ThreeStateBooleanColumn
    add_column :users, :admin, :boolean
    # rubocop:enable Rails/ThreeStateBooleanColumn
  end
end
