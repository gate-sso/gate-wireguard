# frozen_string_literal: true

require 'net/http'

class ProfileImagesController < ApplicationController
  before_action :require_login

  def show
    user = current_user

    if user.profile_picture_url.present?
      fetch_and_serve_image(user.profile_picture_url)
    else
      serve_default_avatar
    end
  end

  private

  def fetch_and_serve_image(image_url)
    response = Net::HTTP.get_response(URI(image_url))

    if response.code == '200'
      serve_image_response(response)
    else
      serve_default_avatar
    end
  rescue StandardError => e
    Rails.logger.error "Profile image fetch error: #{e.message}"
    serve_default_avatar
  end

  def serve_image_response(response)
    response_headers = {
      'Content-Type' => response['content-type'] || 'image/jpeg',
      'Cache-Control' => 'public, max-age=3600',
      'Expires' => 1.hour.from_now.httpdate
    }

    send_data response.body, response_headers
  end

  def serve_default_avatar
    redirect_to asset_path('default-avatar.svg')
  end
end
