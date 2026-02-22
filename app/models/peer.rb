# frozen_string_literal: true

class Peer < ApplicationRecord
  validates :name, presence: true, uniqueness: true, length: { maximum: 100 }
  validates :vpn_ip, presence: true, uniqueness: true
  validates :public_key, presence: true, uniqueness: true
  validates :private_key, presence: true
  validates :dns, length: { maximum: 255 }, allow_blank: true

  scope :active, -> { where(removed_at: nil) }

  def config
    <<~CONF
      [Interface]
      PrivateKey = #{private_key}
      Address = #{vpn_ip}/24
      DNS = #{dns.presence || '1.1.1.1'}

      [Peer]
      PublicKey = #{server_public_key}
      Endpoint = #{server_endpoint}
      AllowedIPs = #{allowed_ips}
      PersistentKeepalive = 25
    CONF
  end

  def removed?
    removed_at.present?
  end

  def remove!
    update!(removed_at: Time.current)
  end

  private

  def server_public_key
    ENV.fetch('WG_SERVER_PUBLIC_KEY', 'REPLACE_WITH_SERVER_PUBLIC_KEY')
  end

  def server_endpoint
    ENV.fetch('WG_SERVER_ENDPOINT', 'gate.clawstation.ai:51820')
  end

  def allowed_ips
    ENV.fetch('WG_ALLOWED_IPS', '10.5.42.0/24')
  end
end
