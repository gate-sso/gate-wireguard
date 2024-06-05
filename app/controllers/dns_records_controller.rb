class DnsRecordsController < ApplicationController
  before_action :require_login
  layout 'admin'

  def index
    @dns_records = DnsRecord.all
    @dns_record = DnsRecord.new


  end

  def refresh_zones
    @dns_records = DnsRecord.all
    @dns_record = DnsRecord.new
    redirect_to dns_records_path, notice: 'DNS zones were refreshed successfully.'
  end


  # POST /dns_records or /dns_records.json
  def create

    @dns_record = DnsRecord.new(dns_record_params)
    @dns_record.user_id = current_user.id

    if @dns_record.save!
      redirect_to dns_records_path, notice: 'DNS record was successfully created.'
    else
      render :index
    end
  end

  def destroy
    @dns_record = DnsRecord.find(params[:id])
    @dns_record.destroy
    redirect_to dns_records_path, notice: 'DNS record was successfully destroyed.'
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_dns_record
    @dns_record = DnsRecord.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def dns_record_params
    params.require(:dns_record).permit(:host_name, :ip_address, :dns_zone_id)
  end

end

