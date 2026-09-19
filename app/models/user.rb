# typed: false
# frozen_string_literal: true

class User < ApplicationRecord
  has_many :vpn_devices, dependent: :destroy

  def self.api_system_user
    find_or_create_by!(provider: 'api', uid: 'api-system') do |u|
      u.name = 'API System'
      u.email = 'api@gate.clawstation.ai'
      u.admin = false
      u.active = true
    end
  end

  def self.from_omniauth(auth)
    user = find_for_omniauth(auth) || auto_create_admin(auth) || auto_create_from_domain(auth)
    return nil unless user

    update_omniauth_fields(user, auth)
    user
  end

  def self.find_for_omniauth(auth)
    find_by(email: auth.info.email) || find_by(provider: auth.provider, uid: auth.uid)
  end

  def self.auto_create_admin(auth)
    return nil unless ENV['ADMIN_USER_EMAIL'].present? && auth.info.email == ENV['ADMIN_USER_EMAIL']

    create!(
      email: auth.info.email, name: auth.info.name,
      profile_picture_url: process_profile_picture_url(auth.info.image),
      provider: auth.provider, uid: auth.uid, admin: true, active: true
    )
  end

  # Anyone whose (Google-verified) address is on an authorized domain signs up
  # on first login -- active, not an administrator. Everyone else still has to
  # be added by an administrator first, which is the invite. AUTHORIZED_DOMAINS
  # is a comma-separated list; empty or unset keeps the invite-only behaviour.
  def self.auto_create_from_domain(auth)
    email = auth.info.email.to_s.strip.downcase
    domain = email.split('@', 2).last
    return nil if domain.blank? || authorized_domains.exclude?(domain)

    create!(
      email: email, name: auth.info.name,
      profile_picture_url: process_profile_picture_url(auth.info.image),
      provider: auth.provider, uid: auth.uid, admin: false, active: true
    )
  end

  def self.authorized_domains
    ENV.fetch('AUTHORIZED_DOMAINS', '').split(',').map { |d| d.strip.downcase }.compact_blank
  end

  def self.update_omniauth_fields(user, auth)
    user.update(
      provider: auth.provider, uid: auth.uid,
      name: auth.info.name, profile_picture_url: process_profile_picture_url(auth.info.image)
    )
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
