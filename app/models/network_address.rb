# typed: true
# frozen_string_literal: true

class NetworkAddress < ApplicationRecord
  belongs_to :vpn_configuration

  # Strip surrounding whitespace before validation so " 10.20.0.0/20 " is
  # treated the same as "10.20.0.0/20" and an inadvertently empty row
  # stays empty rather than becoming " " (which `presence?` would pass).
  before_validation :strip_network_address

  # Reject blank rows outright. The admin UI previously POSTed empty values
  # when the "Config" button was hit with Turbo enabled, producing entries
  # that broke the generated AllowedIPs (",,").
  validates :network_address, presence: true

  private

  def strip_network_address
    self.network_address = network_address.to_s.strip
  end
end
