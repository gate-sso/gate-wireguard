class AdminController < ApplicationController
  before_action :require_login
  # before_action :set_vpn_configuration, only: %i[ show update edit ]

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
        keys = WireguardConfigGenerator.generate_server_config
        @vpn_configuration = VpnConfiguration.new
        @vpn_configuration.wg_private_key = keys[:private_key]
        @vpn_configuration.wg_public_key = keys[:public_key]
        @vpn_configuration.wg_port = keys[:port]
        @vpn_configuration.wg_ip_range = keys[:range]
        @vpn_configuration.dns_servers = keys[:dns_servers]
        @vpn_configuration.save!
      end
      @vpn_configuration = VpnConfiguration.all.first
      @network_address = NetworkAddress.new
      @network_address.vpn_configuration_id = @vpn_configuration.id

    else
      redirect_to root_path, alert: "You are not authorized to access this page."
    end
  end

  def update_vpn_configuration
    respond_to do |format|
      @vpn_configuration = VpnConfiguration.find(params[:id])
      if @vpn_configuration.update(vpn_configuration_params)
        format.html { redirect_to admin_vpn_configurations_path, notice: "Vpn configuration was successfully updated." }
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
    @network_address.network_address = params[:network_address][:network_address]
    @network_address.network_address = params[:network_address][:network_address]
    @network_address.vpn_configuration_id = @vpn_configuration.id

    respond_to do |format|
      if @network_address.save!
        format.html { redirect_to "/admin/vpn_configurations", notice: "Network address was successfully added." }
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
      format.html { redirect_to "/admin/vpn_configurations", notice: "Network address was deleted" }
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
    params.require(:vpn_configuration).permit(:wg_private_key, :wg_public_key, :wg_ip_address, :dns_servers, :wg_port, :wg_ip_range)
  end

end
