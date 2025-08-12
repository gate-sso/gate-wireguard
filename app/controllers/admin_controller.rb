# frozen_string_literal: true

class AdminController < ApplicationController
  before_action :require_login
  # before_action :set_vpn_configuration, only: %i[ show update edit ]

  layout 'admin'
  after_action :update_wireguard_config, only: %i[update_vpn_configuration add_network_address remove_network_address]

  def index
    @vpn_configuration = VpnConfiguration.first
    return unless @vpn_configuration.nil?

    redirect_to admin_vpn_configurations_path
  end

  def users
    if current_user.admin?
      @users = User.all
    else
      redirect_to root_path
    end
  end

  def vpn_configurations
    if current_user.admin?
      @network_address = NetworkAddress.new
      @vpn_configuration = VpnConfiguration.get_vpn_configuration

      # Get network interface information for auto-population
      @network_interface_info = NetworkInterfaceHelper.get_default_gateway_interface

    else
      redirect_to root_path
    end
  end

  def update_vpn_configuration
    unless current_user.admin?
      redirect_to root_path
      return
    end

    respond_to do |format|
      @vpn_configuration = VpnConfiguration.find(params[:id])
      if vpn_configuration_params[:wg_ip_range]
        @vpn_configuration.server_vpn_ip_address = "#{vpn_configuration_params[:wg_ip_range].split('.')[0..2].join('.')}.1"
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
    unless current_user.admin?
      redirect_to root_path
      return
    end

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
    unless current_user.admin?
      redirect_to root_path
      return
    end

    @network_address = NetworkAddress.find(params[:id])
    @network_address.destroy!
    respond_to do |format|
      format.html { redirect_to '/admin/vpn_configurations', notice: 'Network address was deleted' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_vpn_configuration
    @vpn_configuration = VpnConfiguration.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def vpn_configuration_params
    params.expect(vpn_configuration: %i[wg_ip_address dns_servers wg_port wg_ip_range
                                        wg_network_address wg_interface_name wg_listen_address wg_keep_alive wg_forward_interface wg_fqdn])
  end

  def update_wireguard_config
    WireguardConfigGenerator.write_server_configuration(VpnConfiguration.first)
  end
end
