class DnsZone < ApplicationRecord
  has_many :dns_records
end
