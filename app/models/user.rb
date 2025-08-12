# frozen_string_literal: true

class User < ApplicationRecord
  has_many :vpn_devices, dependent: :destroy
  def self.from_omniauth(auth)
    user = where(provider: auth.provider, uid: auth.uid).first_or_create do |new_user|
      new_user.email = auth.info.email
      new_user.name = auth.info.name
      new_user.profile_picture_url = process_profile_picture_url(auth.info.image)
      new_user.provider = auth.provider
      new_user.uid = auth.uid
      new_user.admin = User.none?
    end

    # Update profile picture for existing users
    if user.persisted?
      processed_url = process_profile_picture_url(auth.info.image)
      if user.profile_picture_url != processed_url
        user.update(
          name: auth.info.name,
          profile_picture_url: processed_url
        )
      end
    end

    user
  end

  def self.process_profile_picture_url(image_url)
    return nil if image_url.blank?

    # Google profile pictures often have long query parameters
    # We can remove size parameters and use a standard size
    if image_url.include?('googleusercontent.com')
      # Remove size parameters and add our own
      base_url = image_url.split('=').first
      return "#{base_url}=s96-c" # 96px size, cropped
    end

    # For other providers, just return the URL as is (up to 1000 chars to be safe)
    image_url.length > 1000 ? image_url[0..999] : image_url
  end
end
