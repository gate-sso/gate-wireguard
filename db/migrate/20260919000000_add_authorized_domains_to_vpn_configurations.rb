# frozen_string_literal: true

class AddAuthorizedDomainsToVpnConfigurations < ActiveRecord::Migration[8.0]
  def change
    # Comma-separated email domains whose users may sign up on first login.
    # A setting, not an env var: administrators add a domain from the VPN
    # configuration page without a redeploy.
    add_column :vpn_configurations, :authorized_domains, :string
  end
end
