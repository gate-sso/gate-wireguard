# typed: false
# frozen_string_literal: true

module BackupOperations
  extend ActiveSupport::Concern

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
    VpnConfiguration.all.map { |config| config.attributes.except('created_at', 'updated_at') }
  end

  def export_vpn_devices
    VpnDevice.all.map do |device|
      device.attributes.except('created_at', 'updated_at').merge('user_email' => device.user&.email)
    end
  end

  def export_users
    User.all.map { |user| user.attributes.except('created_at', 'updated_at') }
  end

  def export_network_addresses
    NetworkAddress.all.map { |addr| addr.attributes.except('created_at', 'updated_at') }
  end

  def export_dns_records
    DnsRecord.all.map { |record| record.attributes.except('created_at', 'updated_at') }
  end

  def restore_from_backup(backup_data)
    ActiveRecord::Base.transaction do
      clear_existing_data if params[:clear_existing] == '1'
      restore_users(backup_data['users'] || [])
      restore_vpn_configurations(backup_data['vpn_configurations'] || [])
      restore_network_addresses(backup_data['network_addresses'] || [])
      restore_vpn_devices(backup_data['vpn_devices'] || [])
      restore_dns_records(backup_data['dns_records'] || [])
    end
  end

  def clear_existing_data
    VpnDevice.destroy_all
    NetworkAddress.destroy_all
    DnsRecord.destroy_all
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
    addresses_data.each { |addr_data| NetworkAddress.create!(addr_data.except('id')) }
  end

  def restore_vpn_devices(devices_data)
    devices_data.each do |device_data|
      user = User.find_by(email: device_data['user_email'])
      next unless user

      device_attributes = device_data.except('id', 'user_email').merge('user_id' => user.id)
      existing_device = VpnDevice.find_by(user: user, description: device_data['description'])

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
end
