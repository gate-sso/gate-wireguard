# typed: false
# frozen_string_literal: true

class VpnDevicesController < ApplicationController
  before_action :set_vpn_device, only: %i[show update destroy]
  before_action :require_login
  after_action :update_wireguard_config, only: %i[create update destroy]
  layout 'admin'

  # GET /vpn_devices or /vpn_devices.json
  def index
    @nodes = true if params['nodes'].present?
    @vpn_devices = (@nodes == true ? VpnDevice.where(node: true) : VpnDevice.all)
  end

  # GET /my_devices - Show only current user's devices
  def my_devices
    @vpn_devices = current_user.vpn_devices
    @user_devices_only = true
    render :index
  end

  # GET /vpn_devices/1 or /vpn_devices/1.json
  def show
    @nodes = true if params['nodes'].present?
    redirect_to root_path, alert: 'Vpn device description is empty.' if @vpn_device.description.blank?
    @vpn_configuration = VpnConfiguration.first
  end

  def qr_code
    @vpn_device = downloadable_device
    return if performed?

    render html: @vpn_device.generate_qr_code.html_safe, layout: false # rubocop:disable Rails/OutputSafety
  end

  def download_config
    @vpn_device = downloadable_device
    return if performed?

    @vpn_configuration = VpnConfiguration.first

    # Handle case where no VPN configuration exists
    if @vpn_configuration.nil?
      render plain: 'VPN configuration not found', status: :service_unavailable
      return
    end

    config_content = WireguardConfigGenerator.generate_client_config(@vpn_device, @vpn_configuration)

    # Generate filename based on wg_fqdn or fallback to IP address
    filename = if @vpn_configuration.wg_fqdn.present?
                 "#{@vpn_configuration.wg_fqdn}.conf"
               elsif @vpn_configuration.wg_ip_address.present?
                 # Replace dots with underscores for IP address
                 "#{@vpn_configuration.wg_ip_address.gsub('.', '_')}.conf"
               else
                 # Fallback to original filename if neither is available
                 'gate_vpn_config.conf'
               end

    send_data config_content, filename: filename
  end

  # GET /vpn_devices/new
  def new
    @vpn_device = current_user.vpn_devices.build
  end

  # POST /vpn_devices or /vpn_devices.json
  def create
    @vpn_device = current_user.vpn_devices.build(vpn_device_params)
    @vpn_device.setup_device_with_keys

    respond_to do |format|
      if @vpn_device.save
        IpAllocation.allocate_ip(@vpn_device)
        format.html { redirect_to vpn_device_path(@vpn_device), notice: 'Device created successfully.' }
        format.json { render :show, status: :created, location: @vpn_device }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @vpn_device.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /vpn_devices/1 or /vpn_devices/1.json
  def update
    respond_to do |format|
      if @vpn_device.update(vpn_device_params)
        format.html { redirect_to root_path, notice: 'Vpn device was successfully updated.' }
        format.json { render :show, status: :ok, location: @vpn_device }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @vpn_device.errors, status: :unprocessable_content }
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

  # A device's config is the user's own to download -- or any device's, for an
  # administrator, who sees every device in the list and gets a working button
  # rather than a 404. A person who ends up with two user rows (a new email, a
  # re-invite) otherwise finds their old devices visible but not downloadable,
  # and the only clue was Rails' error page. Not found is a flash and a
  # redirect, not an exception.
  def downloadable_device
    scope = current_user.admin? ? VpnDevice.all : current_user.vpn_devices
    scope.find_by(id: params[:id]) || redirect_to(my_devices_path, alert: 'That device is not yours to download.')
  end

  # Only allow a list of trusted parameters through.
  def vpn_device_params
    params.expect(vpn_device: %i[user_id description private_key public_key node served_networks])
  end

  def update_wireguard_config
    WireguardConfigGenerator.write_server_configuration(VpnConfiguration.first)
  end
end
