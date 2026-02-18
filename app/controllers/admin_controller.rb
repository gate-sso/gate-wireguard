# frozen_string_literal: true

class AdminController < ApplicationController
  before_action :require_login
  before_action :require_admin, except: [:index]

  layout 'admin'
  after_action :update_wireguard_config, only: %i[update_vpn_configuration add_network_address remove_network_address]

  def index
    @vpn_configuration = VpnConfiguration.first
    return unless @vpn_configuration.nil?

    redirect_to admin_vpn_configurations_path
  end

  def users
    @users = User.all
  end

  def add_user
    email = params[:email]&.strip&.downcase
    if email.blank?
      redirect_to admin_users_path, alert: 'Email is required.'
      return
    end

    if User.exists?(email: email)
      redirect_to admin_users_path, alert: 'A user with this email already exists.'
      return
    end

    User.create!(email: email, active: true)
    redirect_to admin_users_path, notice: "User #{email} has been added and pre-authorized."
  end

  def destroy_user
    user = User.find(params[:id])
    if user == current_user
      redirect_to admin_users_path, alert: 'You cannot delete your own account.'
      return
    end

    user.destroy!
    redirect_to admin_users_path, notice: "User #{user.email} has been removed."
  end

  def toggle_admin
    user = User.find(params[:id])
    if user == current_user
      redirect_to admin_users_path, alert: 'You cannot change your own admin status.'
      return
    end
    user.update(admin: !user.admin?)
    redirect_to admin_users_path
  end

  def toggle_active
    user = User.find(params[:id])
    if user == current_user
      redirect_to admin_users_path, alert: 'You cannot deactivate your own account.'
      return
    end
    user.update(active: !user.active?)
    redirect_to admin_users_path
  end

  def vpn_configurations
    @network_address = NetworkAddress.new
    @vpn_configuration = VpnConfiguration.get_vpn_configuration
    @network_interface_info = NetworkInterfaceHelper.default_gateway_interface
  end

  def update_vpn_configuration
    respond_to do |format|
      @vpn_configuration = VpnConfiguration.find(params[:id])
      if vpn_configuration_params[:wg_ip_range]
        ip_parts = vpn_configuration_params[:wg_ip_range].split('.')[0..2]
        @vpn_configuration.server_vpn_ip_address = "#{ip_parts.join('.')}.1"
      end
      if @vpn_configuration.update(vpn_configuration_params)
        format.html { redirect_to admin_vpn_configurations_path, notice: 'Vpn configuration was successfully updated.' }
        format.json { render :show, status: :ok, location: @vpn_configuration }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @vpn_configuration.errors, status: :unprocessable_entity }
      end
    end
  end

  def add_network_address
    @vpn_configuration = VpnConfiguration.find(params[:id])
    @network_address = NetworkAddress.new
    @network_address.network_address = params[:network_address]
    @network_address.vpn_configuration_id = @vpn_configuration.id

    respond_to do |format|
      if @network_address.save!
        format.html { redirect_to '/admin/vpn_configurations', notice: 'Network address was successfully added.' }
        format.json { render :show, status: :ok, location: @vpn_configuration }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @network_address.errors, status: :unprocessable_entity }
      end
    end
  end

  def remove_network_address
    @network_address = NetworkAddress.find(params[:id])
    @network_address.destroy!
    respond_to do |format|
      format.html { redirect_to '/admin/vpn_configurations', notice: 'Network address was deleted' }
      format.json { head :no_content }
    end
  end

  private

  def require_admin
    redirect_to root_path unless current_user.admin?
  end

  def set_vpn_configuration
    @vpn_configuration = VpnConfiguration.find(params[:id])
  end

  def vpn_configuration_params
    params.expect(vpn_configuration: %i[
                    wg_ip_address dns_servers wg_port wg_ip_range
                    wg_network_address wg_interface_name wg_listen_address
                    wg_keep_alive wg_forward_interface wg_fqdn
                  ])
  end

  def update_wireguard_config
    WireguardConfigGenerator.write_server_configuration(VpnConfiguration.first)
  end
end
