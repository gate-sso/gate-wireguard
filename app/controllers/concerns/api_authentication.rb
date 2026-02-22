# frozen_string_literal: true

module ApiAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_api_key!
  end

  private

  def authenticate_api_key!
    token = request.headers['Authorization']&.delete_prefix('Bearer ')&.strip
    @current_api_key = ApiKey.authenticate(token)

    return if @current_api_key

    render json: { error: 'Unauthorized - invalid or missing API key' }, status: :unauthorized
  end

  def current_api_key
    @current_api_key
  end
end
