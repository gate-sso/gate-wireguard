# typed: false
# frozen_string_literal: true

module Admin
  class BackupsController < ApplicationController
    extend T::Sig
    include BackupOperations

    before_action :require_login
    before_action :require_admin

    sig { void }
    def index
      last_backup = session[:last_backup_time]
      last_backup_time = Time.zone.parse(last_backup.to_s) if last_backup

      @backup_info = {
        vpn_configurations_count: VpnConfiguration.count,
        vpn_devices_count: VpnDevice.count,
        users_count: User.count,
        network_addresses_count: NetworkAddress.count,
        dns_records_count: DnsRecord.count,
        last_backup: last_backup_time
      }
    end

    sig { void }
    def download
      backup_data = generate_backup_data

      filename = "gate-wireguard-backup-#{Time.current.strftime('%Y%m%d-%H%M%S')}.json"
      session[:last_backup_time] = Time.current

      send_data backup_data.to_json,
                filename: filename,
                type: 'application/json',
                disposition: 'attachment'
    end

    sig { void }
    def restore
      if params[:backup_file].blank?
        redirect_to admin_backups_path, alert: 'Please select a backup file to restore.'
        return
      end

      begin
        backup_content = params[:backup_file].read
        backup_data = JSON.parse(backup_content)

        restore_from_backup(backup_data)

        redirect_to admin_backups_path, notice: 'Backup restored successfully!'
      rescue JSON::ParserError
        redirect_to admin_backups_path, alert: 'Invalid backup file format. Please select a valid JSON backup file.'
      rescue StandardError => e
        Rails.logger.error "Backup restore error: #{e.message}"
        redirect_to admin_backups_path, alert: "Restore failed: #{e.message}"
      end
    end

    private

    sig { void }
    def require_admin
      redirect_to root_path, alert: 'Access denied.' unless current_user&.admin?
    end
  end
end
