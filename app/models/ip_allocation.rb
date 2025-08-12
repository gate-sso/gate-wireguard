# frozen_string_literal: true

# Purpose: Model for IP Allocation. This model is used to store the IP address allocated to a VPN device.
class IpAllocation < ApplicationRecord
  # rubocop:disable Rails/UniqueValidationWithoutIndex
  validates :ip_address, presence: true, uniqueness: true
  # rubocop:enable Rails/UniqueValidationWithoutIndex
  belongs_to :vpn_device

  def self.next_available_ip
    # Start checking from .2 as .1 is reserved for the server
    (2..254).each do |i|
      ip = "#{base_ip}.#{i}"
      return ip unless IpAllocation.exists?(ip_address: ip)
    end
    nil # Return nil if no IP is available
  end

  def self.base_ip
    vpn_configuration = VpnConfiguration.first
    vpn_configuration.wg_ip_range.split('.')[0..2].join('.')
  end

  def self.allocate_ip(vpn_device)
    ip = next_available_ip
    return nil unless ip

    IpAllocation.create!(vpn_device: vpn_device, ip_address: ip)
  end

  def self.deallocate_ip(vpn_device)
    IpAllocation.where(vpn_device: vpn_device).destroy_all
  end
end
