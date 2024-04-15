class VpnConfiguration < ApplicationRecord
  has_many :network_addresses, dependent: :destroy
end
