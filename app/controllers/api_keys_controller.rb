# frozen_string_literal: true

class ApiKeysController < ApplicationController
  before_action :require_login
  before_action :require_admin

  def index
    @api_keys = ApiKey.order(created_at: :desc)
  end

  def new
    @api_key = ApiKey.new
  end

  def create
    @api_key = ApiKey.generate(name: params.dig(:api_key, :name).presence || 'Unnamed key')

    if @api_key.persisted?
      flash[:raw_token] = @api_key.raw_token
      redirect_to api_keys_path, notice: 'API key created. Copy the token now - it will not be shown again.'
    else
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    api_key = ApiKey.find(params[:id])
    api_key.revoke!
    redirect_to api_keys_path, notice: 'API key revoked.'
  end

  private

  def require_admin
    return if current_user&.admin?

    redirect_to root_path, alert: 'Access denied.'
  end
end
