class VpnDevicesController < ApplicationController
  before_action :set_vpn_device, only: %i[ show edit update destroy ]
  before_action :require_login
  layout 'admin'

  # GET /vpn_devices or /vpn_devices.json
  def index
    @vpn_devices = VpnDevice.all
  end

  # GET /vpn_devices/1 or /vpn_devices/1.json
  def show
    @vpn_device = VpnDevice.find(params[:id])
    if @vpn_device.description.nil? or @vpn_device.description.empty?
      redirect_to root_path, alert: "Vpn device description is empty."
    end

    @vpn_configuration = VpnConfiguration.all.first
    @device_configuaration = {
      private_key: @vpn_device.private_key,
      endpoint: @vpn_configuration.wg_ip_address,
      server_public_key: @vpn_configuration.public_key,
      server_port: @vpn_configuration.wg_port
    }
  end

  # GET /vpn_devices/new
  def new
    @vpn_device = current_user.vpn_devices.build
    @keys = WireguardConfigGenerator.generate_client_keys
    @vpn_device.public_key = @keys[:private_key]
    @vpn_device.private_key = @keys[:public_key]
    respond_to do |format|
      if @vpn_device.save!
        format.html { redirect_to root_path, notice: "Vpn device was successfully updated." }
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
        format.html { redirect_to root_path, notice: "Vpn device was successfully updated." }
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
      format.html { redirect_to root_path, notice: "Vpn device was successfully destroyed." }
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
      params.require(:vpn_device).permit(:user_id, :description, :private_key, :public_key)
    end
end
