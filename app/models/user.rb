class User < ApplicationRecord
  has_many :vpn_devices, dependent: :destroy
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.name = auth.info.name
      user.provider = auth.provider
      user.uid = auth.uid
      if User.all.count == 0
        user.admin = true
      else
        user.admin = false
      end
    end
  end
end
