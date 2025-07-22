# frozen_string_literal: true

class User < ApplicationRecord
  has_many :vpn_devices, dependent: :destroy
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.name = auth.info.name
      user.provider = auth.provider
      user.uid = auth.uid
      user.admin = User.none?
    end
  end
end
