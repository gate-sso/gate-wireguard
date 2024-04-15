class ConfigurationsController < ApplicationController
  before_action :set_configuration, only: %i[ show edit update destroy ]

  # GET /configurations or /configurations.json
  def index
    @configurations = Configuration.all
  end

  # GET /configurations/1 or /configurations/1.json
  def show
  end

  # GET /configurations/new
  def new
    @configuration = Configuration.new
  end

  # GET /configurations/1/edit
  def edit
  end

  # POST /configurations or /configurations.json
  def create
    @configuration = Configuration.new(configuration_params)

    respond_to do |format|
      if @configuration.save
        format.html { redirect_to configuration_url(@configuration), notice: "Configuration was successfully created." }
        format.json { render :show, status: :created, location: @configuration }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @configuration.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /configurations/1 or /configurations/1.json
  def update
    respond_to do |format|
      if @configuration.update(configuration_params)
        format.html { redirect_to configuration_url(@configuration), notice: "Configuration was successfully updated." }
        format.json { render :show, status: :ok, location: @configuration }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @configuration.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /configurations/1 or /configurations/1.json
  def destroy
    @configuration.destroy!

    respond_to do |format|
      format.html { redirect_to configurations_url, notice: "Configuration was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_configuration
      @configuration = Configuration.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def configuration_params
      params.require(:configuration).permit(:wg_private_key, :wg_public_key, :wg_ip_address, :wg_port)
    end
end
