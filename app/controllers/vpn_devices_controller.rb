class VpnDevicesController < ApplicationController
  before_action :set_vpn_device, only: %i[show edit update destroy]
  before_action :require_login
  after_action :update_wireguard_config, only: %i[update destroy]
  layout 'admin'

  # GET /vpn_devices or /vpn_devices.json
  def index
    @nodes = true if params['nodes'].present?
    @vpn_devices = if @nodes == true
                     # find vpn devices where node variable is true
                     VpnDevice.where(node: true)
                   else
                     VpnDevice.all
                   end
  end

  # GET /vpn_devices/1 or /vpn_devices/1.json
  def show
    @nodes = true if params['nodes'].present?
    if @vpn_device.description.nil? || @vpn_device.description.empty?
      redirect_to root_path, alert: 'Vpn device description is empty.'
    end
    @vpn_configuration = VpnConfiguration.all.first
  end

  def download_config
    @vpn_device = VpnDevice.find(params[:id])
    config_content = WireguardConfigGenerator.generate_client_config(@vpn_device, VpnConfiguration.first)
    send_data config_content, filename: 'gate_vpn_config.conf'
  end

  # GET /vpn_devices/new
  def new
    @vpn_device = current_user.vpn_devices.build
    @vpn_device.setup_device_with_keys

    respond_to do |format|
      if @vpn_device.save!
        IpAllocation.allocate_ip(@vpn_device)
        format.html { redirect_to root_path, notice: 'Vpn device was successfully updated.' }
        format.json { render :show, status: :ok, location: @vpn_device }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @vpn_device.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /vpn_devices or /vpn_devices.json
  def create
    config_file = params[:config_file]
    output, status = Open3.capture2e("sudo wg-quick up #{config_file}")

    if status.success?
      redirect_to vpn_devices_path, notice: 'WireGuard interface created successfully.'
    else
      redirect_to new_vpn_device_path, alert: "Failed to create WireGuard interface:\n#{output}"
    end
  end

  # PATCH/PUT /vpn_devices/1 or /vpn_devices/1.json
  def update
    respond_to do |format|
      if @vpn_device.update(vpn_device_params)
        format.html { redirect_to root_path, notice: 'Vpn device was successfully updated.' }
        format.json { render :show, status: :ok, location: @vpn_device }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @vpn_device.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /vpn_devices/1 or /vpn_devices/1.json
  def destroy
    @vpn_device.destroy!
    respond_to do |format|
      format.html { redirect_to root_path, notice: 'Vpn device was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_vpn_device
    @vpn_device = VpnDevice.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def vpn_device_params
    params.require(:vpn_device).permit(:user_id, :description, :private_key, :public_key, :node)
  end

  def update_wireguard_config
    WireguardConfigGenerator.write_server_configuration(VpnConfiguration.first)
  end
end
