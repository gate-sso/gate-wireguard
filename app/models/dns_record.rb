class DnsRecord < ApplicationRecord
  belongs_to :user
  belongs_to :dns_zone
end
