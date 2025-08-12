# frozen_string_literal: true

class AddNodeToVpnDevice < ActiveRecord::Migration[7.1]
  def change
    # rubocop:disable Rails/ThreeStateBooleanColumn
    add_column :vpn_devices, :node, :boolean
    # rubocop:enable Rails/ThreeStateBooleanColumn
  end
end
