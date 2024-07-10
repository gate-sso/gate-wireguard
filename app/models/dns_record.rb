# DNS Record is a model that represents a DNS record in the database.
class DnsRecord < ApplicationRecord
  belongs_to :user
  def self.time_to_live
    300
  end

  # adds dns record to zone
  def self.add_host(zone, host, ip_address)
    zone += '.' unless zone.end_with?('.')
    a = [
      ip: ip_address,
      ttl: time_to_live
    ]

    host_record = { a: a }
    REDIS.hset(zone, host, host_record.to_json)
  end

  def self.add_host_to_zone(dns_record)
    add_host(ENV['GATE_DNS_ZONE'], dns_record.host_name, dns_record.ip_address)
  end

  def self.refresh_zones
    REDIS.del("#{ENV['GATE_DNS_ZONE']}.")
    DnsRecord.all.each do |dns_record|
      add_host_to_zone(dns_record)
    end
  end
end
