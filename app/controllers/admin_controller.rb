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

  def vpn_configuration
    if current_user.admin?
      @vpn_configuration = VpnConfiguration.all
      if @vpn_configuration.empty?
        redirect_to new_vpn_configuration_path
      else
        redirect_to vpn_configuration_path(@vpn_configuration.first)
      end
    else
      redirect_to root_path, alert: "You are not authorized to access this page."
    end
  end
end
