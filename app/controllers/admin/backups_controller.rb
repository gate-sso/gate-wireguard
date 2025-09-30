# frozen_string_literal: true

class Admin::BackupsController < ApplicationController
  before_action :require_login
  before_action :require_admin

  def index
    @backup_info = {
      vpn_configurations_count: VpnConfiguration.count,
      vpn_devices_count: VpnDevice.count,
      users_count: User.count,
      network_addresses_count: NetworkAddress.count,
      dns_records_count: DnsRecord.count,
      last_backup: session[:last_backup_time]
    }
  end

  def download
    backup_data = generate_backup_data

    filename = "gate-wireguard-backup-#{Time.current.strftime('%Y%m%d-%H%M%S')}.json"
    session[:last_backup_time] = Time.current

    send_data backup_data.to_json,
              filename: filename,
              type: 'application/json',
              disposition: 'attachment'
  end

  def restore
    unless params[:backup_file].present?
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

  def generate_backup_data
    {
      metadata: {
        version: '1.0',
        created_at: Time.current,
        app_version: Rails::VERSION::STRING
      },
      vpn_configurations: export_vpn_configurations,
      vpn_devices: export_vpn_devices,
      users: export_users,
      network_addresses: export_network_addresses,
      dns_records: export_dns_records
    }
  end

  def export_vpn_configurations
    VpnConfiguration.all.map do |config|
      config.attributes.except('created_at', 'updated_at')
    end
  end

  def export_vpn_devices
    VpnDevice.all.map do |device|
      device.attributes.except('created_at', 'updated_at').merge(
        'user_email' => device.user&.email
      )
    end
  end

  def export_users
    User.all.map do |user|
      user.attributes.except('created_at', 'updated_at')
    end
  end

  def export_network_addresses
    NetworkAddress.all.map do |addr|
      addr.attributes.except('created_at', 'updated_at')
    end
  end

  def export_dns_records
    DnsRecord.all.map do |record|
      record.attributes.except('created_at', 'updated_at')
    end
  end

  def restore_from_backup(backup_data)
    ActiveRecord::Base.transaction do
      # Clear existing data (be careful in production!)
      if params[:clear_existing] == '1'
        clear_existing_data
      end

      # Restore users first (needed for foreign keys)
      restore_users(backup_data['users'] || [])

      # Restore VPN configurations
      restore_vpn_configurations(backup_data['vpn_configurations'] || [])

      # Restore network addresses
      restore_network_addresses(backup_data['network_addresses'] || [])

      # Restore VPN devices
      restore_vpn_devices(backup_data['vpn_devices'] || [])

      # Restore DNS records
      restore_dns_records(backup_data['dns_records'] || [])
    end
  end

  def clear_existing_data
    VpnDevice.destroy_all
    NetworkAddress.destroy_all
    DnsRecord.destroy_all
    # Don't clear users or vpn_configurations unless explicitly requested
  end

  def restore_users(users_data)
    users_data.each do |user_data|
      existing_user = User.find_by(email: user_data['email'])
      if existing_user
        existing_user.update!(user_data.except('id'))
      else
        User.create!(user_data.except('id'))
      end
    end
  end

  def restore_vpn_configurations(configs_data)
    configs_data.each do |config_data|
      existing_config = VpnConfiguration.first
      if existing_config
        existing_config.update!(config_data.except('id'))
      else
        VpnConfiguration.create!(config_data.except('id'))
      end
    end
  end

  def restore_network_addresses(addresses_data)
    addresses_data.each do |addr_data|
      NetworkAddress.create!(addr_data.except('id'))
    end
  end

  def restore_vpn_devices(devices_data)
    devices_data.each do |device_data|
      user = User.find_by(email: device_data['user_email'])
      next unless user

      device_attributes = device_data.except('id', 'user_email').merge('user_id' => user.id)

      existing_device = VpnDevice.find_by(
        user: user,
        description: device_data['description']
      )

      if existing_device
        existing_device.update!(device_attributes)
      else
        VpnDevice.create!(device_attributes)
      end
    end
  end

  def restore_dns_records(records_data)
    records_data.each do |record_data|
      existing_record = DnsRecord.find_by(name: record_data['name'])
      if existing_record
        existing_record.update!(record_data.except('id'))
      else
        DnsRecord.create!(record_data.except('id'))
      end
    end
  end

  def require_admin
    redirect_to root_path, alert: 'Access denied.' unless current_user&.admin?
  end
end
