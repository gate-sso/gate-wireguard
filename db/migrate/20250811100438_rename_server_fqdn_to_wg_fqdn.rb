# frozen_string_literal: true

class RenameServerFqdnToWgFqdn < ActiveRecord::Migration[8.0]
  def change
    rename_column :vpn_configurations, :server_fqdn, :wg_fqdn
  end
end
