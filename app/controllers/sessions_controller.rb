# typed: false
# frozen_string_literal: true

class SessionsController < ApplicationController
  def create
    @user = User.from_omniauth(request.env['omniauth.auth'])
    if @user.nil?
      reset_session
      redirect_to login_path, alert: 'Your account has not been authorized. Please contact an administrator.'
      return
    end
    unless @user.active?
      reset_session
      redirect_to login_path, alert: 'Your account is pending approval. Please contact an administrator.'
      return
    end
    session[:user_id] = @user.id
    auto_create_default_device(@user)
    redirect_to root_path
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path
  end

  private

  # First-time login: provision a default device so the user can immediately
  # download a config. Silent no-op if VPN config isn't set up yet, if the
  # user already has a device, or if device creation errors out.
  def auto_create_default_device(user)
    return if user.vpn_devices.any?
    return if VpnConfiguration.first.nil?

    device = user.vpn_devices.build(description: "#{user.name}'s Machine")
    device.setup_device_with_keys
    return unless device.save

    IpAllocation.allocate_ip(device)
    WireguardConfigGenerator.write_server_configuration(VpnConfiguration.first)
  rescue StandardError => e
    Rails.logger.warn("auto_create_default_device failed for user=#{user.id}: #{e.class}: #{e.message}")
  end
end
