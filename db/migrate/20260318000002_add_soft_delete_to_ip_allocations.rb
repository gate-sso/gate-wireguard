# frozen_string_literal: true

require 'ipaddr'

class AddSoftDeleteToIpAllocations < ActiveRecord::Migration[8.0]
  def up
    change_table :ip_allocations, bulk: true do |t|
      t.boolean :allocated, default: true, null: false
      t.change_null :vpn_device_id, true
    end
    add_index :ip_allocations, :allocated

    # Remove the foreign key so unallocated rows can have NULL vpn_device_id
    remove_foreign_key :ip_allocations, :vpn_devices

    # Backfill gaps: ensure every IP from .1 up to the high-water mark has a row
    backfill_ip_gaps
  end

  def down
    remove_index :ip_allocations, :allocated

    # Clean up unallocated rows before restoring NOT NULL
    IpAllocation.where(vpn_device_id: nil).delete_all

    change_table :ip_allocations, bulk: true do |t|
      t.remove :allocated
      t.change_null :vpn_device_id, false
    end
    add_foreign_key :ip_allocations, :vpn_devices
  end

  private

  def backfill_ip_gaps
    vpn_config = VpnConfiguration.first
    return if vpn_config&.wg_ip_range.blank?

    network = parse_network(vpn_config)
    reserved = [vpn_config.server_vpn_ip_address, network.to_range.last.to_s, network.to_s].to_set
    allocated_ips = IpAllocation.pluck(:ip_address).to_set

    offset = 1
    filled = 0
    while filled < allocated_ips.size
      candidate = IPAddr.new(network.to_i + offset, Socket::AF_INET).to_s
      offset += 1
      next if reserved.include?(candidate)

      unless allocated_ips.include?(candidate)
        IpAllocation.create!(ip_address: candidate, allocated: false, vpn_device_id: nil)
      end
      filled += 1
    end
  end

  def parse_network(vpn_config)
    base = vpn_config.wg_ip_range.split('/').first
    prefix = vpn_config.wg_ip_range.include?('/') ? vpn_config.wg_ip_range.split('/').last.to_i : 24
    IPAddr.new("#{base}/#{prefix}")
  end
end
