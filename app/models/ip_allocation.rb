class IpAllocation < ApplicationRecord
  validates :ip_address, presence: true, uniqueness: true
  belongs_to :vpn_device


  def self.next_available_ip
    # Start checking from .2 as .1 is reserved for the server
    (2..254).each do |i|
      ip = "#{BASE_IP}#{i}"
      return ip unless IpAllocation.exists?(ip_address: ip)
    end
    nil  # Return nil if no IP is available
  end

  def self.allocate_ip(vpn_client)
    ip = next_available_ip
    return nil unless ip

    IpAllocation.create!(vpn_client: vpn_client, ip_address: ip)
  end

  def self.deallocate_ip(vpn_client)
    IpAllocation.where(vpn_client: vpn_client).destroy_all
  end
end
