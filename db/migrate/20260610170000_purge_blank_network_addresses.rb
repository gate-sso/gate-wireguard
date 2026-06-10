# typed: false
# frozen_string_literal: true

class PurgeBlankNetworkAddresses < ActiveRecord::Migration[8.1]
  def up
    # Drop legacy rows where network_address is empty or whitespace-only.
    # The model now validates presence, but rows created before that were
    # let through and ended up rendering as "," in generated AllowedIPs.
    execute <<~SQL.squish
      DELETE FROM network_addresses
      WHERE network_address IS NULL OR TRIM(network_address) = ''
    SQL
  end

  def down
    # No-op — we can't reconstruct rows we intentionally purged.
  end
end
