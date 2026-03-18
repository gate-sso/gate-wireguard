# typed: false
# frozen_string_literal: true

module BackupOperations # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern

  private

  def generate_backup_data
    {
      metadata: {
        version: '1.1',
        created_at: Time.current,
        app_version: Rails::VERSION::STRING
      },
      vpn_configurations: export_vpn_configurations,
      vpn_devices: export_vpn_devices,
      users: export_users,
      network_addresses: export_network_addresses,
      dns_records: export_dns_records,
      ip_allocations: export_ip_allocations,
      api_keys: export_api_keys
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
    NetworkAddress.all.map do |addr|
      addr.attributes.except('created_at', 'updated_at')
    end
  end

  def export_dns_records
    DnsRecord.all.map { |record| record.attributes.except('created_at', 'updated_at') }
  end

  def export_ip_allocations
    IpAllocation.all.map do |alloc|
      alloc.attributes.except('created_at', 'updated_at').merge(
        'user_email' => alloc.vpn_device&.user&.email,
        'device_description' => alloc.vpn_device&.description
      )
    end
  end

  def export_api_keys
    ApiKey.all.map { |key| key.attributes.except('created_at', 'updated_at') }
  end

  def restore_from_backup(backup_data)
    ActiveRecord::Base.transaction do
      clear_existing_data if params[:clear_existing] == '1'
      restore_all_models(backup_data)
      sync_wireguard_config
    end
  end

  def restore_all_models(data)
    {
      'users' => :restore_users, 'vpn_configurations' => :restore_vpn_configurations,
      'network_addresses' => :restore_network_addresses, 'vpn_devices' => :restore_vpn_devices,
      'dns_records' => :restore_dns_records, 'ip_allocations' => :restore_ip_allocations,
      'api_keys' => :restore_api_keys
    }.each { |key, method| send(method, data[key] || []) }
  end

  def sync_wireguard_config
    config = VpnConfiguration.first
    WireguardConfigGenerator.write_server_configuration(config) if config
  end

  def clear_existing_data
    # Nullify device references first, then delete in dependency order
    IpAllocation.update_all(vpn_device_id: nil, allocated: false) # rubocop:disable Rails/SkipsModelValidations
    ApiKey.delete_all
    DnsRecord.delete_all
    VpnDevice.delete_all
    NetworkAddress.delete_all
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
    config = VpnConfiguration.first
    return unless config

    addresses_data.each do |addr_data|
      NetworkAddress.find_or_create_by!(
        network_address: addr_data['network_address'],
        vpn_configuration_id: config.id
      )
    end
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

  def restore_ip_allocations(allocations_data)
    allocations_data.each do |alloc_data|
      user = User.find_by(email: alloc_data['user_email'])
      device = user ? VpnDevice.find_by(user: user, description: alloc_data['device_description']) : nil
      alloc_attrs = alloc_data.except('id', 'user_email', 'device_description')
                              .merge('vpn_device_id' => device&.id)

      existing_alloc = IpAllocation.find_by(ip_address: alloc_data['ip_address'])
      if existing_alloc
        existing_alloc.update!(alloc_attrs)
      else
        IpAllocation.create!(alloc_attrs)
      end
    end
  end

  def restore_api_keys(api_keys_data)
    api_keys_data.each do |key_data|
      existing_key = ApiKey.find_by(token_digest: key_data['token_digest'])
      if existing_key
        existing_key.update!(key_data.except('id'))
      else
        ApiKey.create!(key_data.except('id'))
      end
    end
  end
end
