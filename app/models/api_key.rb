# typed: false
# frozen_string_literal: true

class ApiKey < ApplicationRecord
  validates :name, presence: true, length: { maximum: 100 }
  validates :token_digest, presence: true, uniqueness: true

  scope :active, -> { where(revoked_at: nil) }

  attr_accessor :raw_token

  def self.generate(name:)
    raw = "gw_#{SecureRandom.urlsafe_base64(32)}"
    create!(
      name: name,
      token_digest: Digest::SHA256.hexdigest(raw),
      raw_token: raw
    )
  end

  def self.authenticate(token)
    return nil if token.blank?

    digest = Digest::SHA256.hexdigest(token)
    key = active.find_by(token_digest: digest)
    key&.update(last_used_at: Time.current)
    key
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def revoked?
    revoked_at.present?
  end

  def active?
    !revoked?
  end
end
