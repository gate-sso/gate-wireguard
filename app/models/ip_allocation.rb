# typed: true
# frozen_string_literal: true

require 'ipaddr'

# Purpose: Model for IP Allocation. This model is used to store the IP address allocated to a VPN device.
# Uses soft-delete: rows are never destroyed, only marked as unallocated for recycling.
class IpAllocation < ApplicationRecord
  extend T::Sig

  # rubocop:disable Rails/UniqueValidationWithoutIndex
  validates :ip_address, presence: true, uniqueness: true
  # rubocop:enable Rails/UniqueValidationWithoutIndex
  belongs_to :vpn_device, optional: true

  scope :allocated, -> { where(allocated: true) }
  scope :unallocated, -> { where(allocated: false) }

  sig { params(vpn_device: VpnDevice).returns(T.nilable(IpAllocation)) }
  def self.allocate_ip(vpn_device)
    # Step 1: Try to recycle an unallocated IP
    recycled = unallocated.lock.order(:id).first
    if recycled
      recycled.update!(allocated: true, vpn_device: vpn_device)
      return recycled
    end

    # Step 2: Allocate a fresh IP using count-based offset
    ip = next_fresh_ip
    return nil unless ip

    create!(vpn_device: vpn_device, ip_address: ip, allocated: true)
  end

  sig { params(vpn_device: VpnDevice).void }
  def self.deallocate_ip(vpn_device)
    where(vpn_device: vpn_device).update_all(allocated: false, vpn_device_id: nil) # rubocop:disable Rails/SkipsModelValidations
  end

  sig { returns(T.nilable(String)) }
  def self.next_fresh_ip
    vpn_configuration = VpnConfiguration.first
    return nil unless vpn_configuration

    network = IPAddr.new("#{vpn_configuration.network_address_base}/#{vpn_configuration.cidr_prefix}")
    server_ip = vpn_configuration.server_vpn_ip_address
    broadcast_int = network.to_range.last.to_i

    offset = count + 1
    candidate_int = network.to_i + offset

    # Skip server IP and broadcast if we land on them
    while candidate_int < broadcast_int
      candidate = IPAddr.new(candidate_int, Socket::AF_INET).to_s
      return candidate unless candidate == server_ip || exists?(ip_address: candidate)

      candidate_int += 1
    end
    nil # Subnet exhausted
  end
end
