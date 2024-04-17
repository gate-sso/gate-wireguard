class VpnDevice < ApplicationRecord
  belongs_to :user
  has_one :ip_allocation

  def setup_device_with_keys_and_ip
    @keys = WireguardConfigGenerator.generate_client_keys
    self.public_key = @keys[:private_key]
    self.private_key = @keys[:public_key]
  end


end
