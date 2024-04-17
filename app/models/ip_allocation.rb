class IpAllocation < ApplicationRecord
  validates :ip_address, presence: true, uniqueness: true
  belongs_to :vpn_device


  def self.next_available_ip
    # Start checking from .2 as .1 is reserved for the server
    (2..254).each do |i|
      ip = "#{get_base_ip}.#{i}"
      return ip unless IpAllocation.exists?(ip_address: ip)
    end
    nil  # Return nil if no IP is available
  end

  def self.get_base_ip
    vpn_configuration = VpnConfiguration.all.first
    return vpn_configuration.wg_ip_range.split('.')[0..2].join('.')
  end
  def self.allocate_ip(vpn_device)
    ip = next_available_ip
    return nil unless ip

    IpAllocation.create!(vpn_device: vpn_device, ip_address: ip)
  end

  def self.deallocate_ip(vpn_client)
    IpAllocation.where(vpn_device: vpn_client).destroy_all
  end
end
