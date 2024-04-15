class AdminController < ApplicationController
  before_action :require_login
  layout 'admin'

  def users
    if current_user.admin?
      @users = User.all
    else
      redirect_to root_path, alert: "You are not authorized to access this page."
    end
  end

  def vpn_configurations
    if current_user.admin?
      @vpn_configuration = VpnConfiguration.all
      if @vpn_configuration.empty?
        keys = WireGuardConfigGenerator.generate_server_config
        @vpn_configuration = VpnConfiguration.new
        @vpn_configuration.wg_private_key = keys[:private_key]
        @vpn_configuration.wg_public_key = keys[:public_key]
        @vpn_configuration.wg_ip_address = keys[:endpoint]
        @vpn_configuration.save!
      end

    else
      redirect_to root_path, alert: "You are not authorized to access this page."
    end
  end
end
