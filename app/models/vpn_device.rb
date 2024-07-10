# This controllers takes care of VPN Decices
class VpnDevice < ApplicationRecord
  belongs_to :user
  has_one :ip_allocation, dependent: :destroy

  def setup_device_with_keys
    @keys = WireguardConfigGenerator.generate_keys
    self.public_key = @keys[:public_key]
    self.private_key = @keys[:private_key]
  end

  def generate_qr_code
    qr = RQRCode::QRCode.new(WireguardConfigGenerator.generate_client_config(self, VpnConfiguration.all.first))
    qr.as_svg(
      offset: 0,
      color: '000',
      shape_rendering: 'crispEdges',
      module_size: 2,
      level: 1
    )
  end
end
