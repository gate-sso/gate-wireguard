# frozen_string_literal: true

class NetworkAddress < ApplicationRecord
  belongs_to :vpn_configuration
end
