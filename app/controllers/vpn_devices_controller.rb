class VpnDevicesController < ApplicationController
  before_action :set_vpn_device, only: %i[ show edit update destroy ]

  # GET /vpn_devices or /vpn_devices.json
  def index
    @vpn_devices = VpnDevice.all
  end

  # GET /vpn_devices/1 or /vpn_devices/1.json
  def show
  end

  # GET /vpn_devices/new
  def new
    @vpn_device = VpnDevice.new
  end

  # GET /vpn_devices/1/edit
  def edit
  end

  # POST /vpn_devices or /vpn_devices.json
  def create
    @vpn_device = VpnDevice.new(vpn_device_params)

    respond_to do |format|
      if @vpn_device.save
        format.html { redirect_to vpn_device_url(@vpn_device), notice: "Vpn device was successfully created." }
        format.json { render :show, status: :created, location: @vpn_device }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @vpn_device.errors, status: :unprocessable_entity }
      end
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
