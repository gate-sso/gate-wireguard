class VpnConfigurationsController < ApplicationController
  before_action :set_vpn_configuration, only: %i[ show edit update destroy ]
  before_action :require_login
  layout 'admin'
  # GET /vpn_configurations or /vpn_configurations.json
  def index
    @vpn_configurations = VpnConfiguration.all
    if @vpn_configurations.empty?
      redirect_to new_vpn_configuration_path
    else
      redirect_to vpn_configuration_path(@vpn_configurations.first)
    end
  end

  # GET /vpn_configurations/1 or /vpn_configurations/1.json
  def show
  end

  # GET /vpn_configurations/new
  def new
    @vpn_configuration = vpn_configuration.new
  end

  # GET /vpn_configurations/1/edit
  def edit
  end

  # POST /vpn_configurations or /vpn_configurations.json
  def create
    @vpn_configuration = vpn_configuration.new(vpn_configuration_params)

    respond_to do |format|
      if @vpn_configuration.save
        format.html { redirect_to vpn_configuration_url(@vpn_configuration), notice: "vpn_configuration was successfully created." }
        format.json { render :show, status: :created, location: @vpn_configuration }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @vpn_configuration.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /vpn_configurations/1 or /vpn_configurations/1.json
  def update
    respond_to do |format|
      if @vpn_configuration.update(vpn_configuration_params)
        format.html { redirect_to vpn_configuration_url(@vpn_configuration), notice: "vpn_configuration was successfully updated." }
        format.json { render :show, status: :ok, location: @vpn_configuration }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @vpn_configuration.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /vpn_configurations/1 or /vpn_configurations/1.json
  def destroy
    @vpn_configuration.destroy!

    respond_to do |format|
      format.html { redirect_to vpn_configurations_url, notice: "vpn_configuration was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_vpn_configuration
      @vpn_configuration = vpn_configuration.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def vpn_configuration_params
      params.require(:vpn_configuration).permit(:wg_private_key, :wg_public_key, :wg_ip_address, :wg_port)
    end
end
