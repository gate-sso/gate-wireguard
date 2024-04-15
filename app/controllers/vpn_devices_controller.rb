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
  end

  # GET /vpn_devices/new
  def new
    @vpn_device = current_user.vpn_devices.build
    @config_file = WireGuardConfigGenerator.generate_config(current_user.id)
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
        format.html { redirect_to vpn_device_url(@vpn_device), notice: "Vpn device was successfully updated." }
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
      format.html { redirect_to vpn_devices_url, notice: "Vpn device was successfully destroyed." }
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
