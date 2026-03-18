# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin Backup & Restore Integration' do
  let!(:admin_user) { User.create!(name: 'Admin User', email: 'admin@example.com', admin: true) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin_user)
    allow_any_instance_of(ApplicationController).to receive(:logged_in?).and_return(true)
  end

  describe 'full backup → clear → restore cycle' do
    let!(:vpn_config) do
      VpnConfiguration.create!(
        wg_ip_range: '10.42.5.0/24',
        server_vpn_ip_address: '10.42.5.254',
        wg_port: '51820',
        wg_private_key: 'server_private_key',
        wg_public_key: 'server_public_key',
        wg_interface_name: 'wg0',
        wg_keep_alive: '25',
        wg_forward_interface: 'eth0',
        wg_fqdn: 'vpn.example.com',
        wg_ip_address: '203.0.113.10',
        dns_servers: '8.8.8.8'
      )
    end

    let!(:network_addr) do
      NetworkAddress.create!(network_address: '192.168.1.0/24', vpn_configuration: vpn_config)
    end

    let!(:device) do
      d = admin_user.vpn_devices.create!(
        description: 'test-laptop',
        public_key: 'device_pub_key',
        private_key: 'device_priv_key'
      )
      IpAllocation.create!(vpn_device: d, ip_address: '10.42.5.1', allocated: true)
      d
    end

    let!(:api_key) { ApiKey.generate(name: 'CI Key') }

    it 'restores all data after clearing' do
      # Step 1: Download backup
      get '/admin/backups/download'
      expect(response).to have_http_status(:success)
      backup_json = response.body
      backup_data = JSON.parse(backup_json)

      # Verify backup contains all models
      expect(backup_data['users'].length).to be >= 1
      expect(backup_data['vpn_configurations'].length).to eq(1)
      expect(backup_data['vpn_devices'].length).to eq(1)
      expect(backup_data['network_addresses'].length).to eq(1)
      expect(backup_data['ip_allocations'].length).to eq(1)
      expect(backup_data['api_keys'].length).to eq(1)
      expect(backup_data['metadata']['version']).to eq('1.1')

      # Step 2: Clear and restore
      backup_file = Rack::Test::UploadedFile.new(
        StringIO.new(backup_json), 'application/json', false, original_filename: 'backup.json'
      )
      post '/admin/backups/restore', params: { backup_file: backup_file, clear_existing: '1' }
      expect(response).to redirect_to('/admin/backups')

      # Step 3: Verify all data restored
      expect(VpnConfiguration.count).to eq(1)
      restored_config = VpnConfiguration.first
      expect(restored_config.wg_ip_range).to eq('10.42.5.0/24')
      expect(restored_config.wg_fqdn).to eq('vpn.example.com')
      expect(restored_config.dns_servers).to eq('8.8.8.8')

      expect(User.find_by(email: 'admin@example.com')).to be_present

      expect(VpnDevice.count).to eq(1)
      restored_device = VpnDevice.first
      expect(restored_device.description).to eq('test-laptop')
      expect(restored_device.public_key).to eq('device_pub_key')

      expect(NetworkAddress.count).to be >= 1
      expect(NetworkAddress.find_by(network_address: '192.168.1.0/24')).to be_present

      expect(IpAllocation.find_by(ip_address: '10.42.5.1')).to be_present

      expect(ApiKey.find_by(token_digest: api_key.token_digest)).to be_present
    end

    it 'merges data without clear_existing' do
      # Create a second user that only exists in the database (not in backup)
      User.create!(name: 'Extra User', email: 'extra@example.com')

      # Download backup (contains admin_user but not extra_user)
      get '/admin/backups/download'
      backup_json = response.body

      # Create another device after backup
      post_backup_device = admin_user.vpn_devices.create!(
        description: 'post-backup-device',
        public_key: 'post_pub_key',
        private_key: 'post_priv_key'
      )
      IpAllocation.create!(vpn_device: post_backup_device, ip_address: '10.42.5.2', allocated: true)

      # Restore WITHOUT clearing
      backup_file = Rack::Test::UploadedFile.new(
        StringIO.new(backup_json), 'application/json', false, original_filename: 'backup.json'
      )
      post '/admin/backups/restore', params: { backup_file: backup_file }
      expect(response).to redirect_to('/admin/backups')

      # Both pre-existing and restored data should coexist
      expect(User.find_by(email: 'extra@example.com')).to be_present
      expect(User.find_by(email: 'admin@example.com')).to be_present
      expect(VpnDevice.count).to eq(2) # original + post-backup
    end

    it 'rejects invalid JSON' do
      bad_file = Rack::Test::UploadedFile.new(
        StringIO.new('not json at all'), 'application/json', false, original_filename: 'bad.json'
      )
      post '/admin/backups/restore', params: { backup_file: bad_file }
      expect(response).to redirect_to('/admin/backups')
      follow_redirect!
      expect(response.body).to include('Invalid backup file')
    end

    it 'handles restore of v1.0 backup (missing ip_allocations/api_keys)' do
      v1_backup = {
        'metadata' => { 'version' => '1.0' },
        'users' => [{ 'email' => 'admin@example.com', 'name' => 'Admin', 'admin' => true, 'active' => true }],
        'vpn_configurations' => [vpn_config.attributes.except('id', 'created_at', 'updated_at')],
        'vpn_devices' => [],
        'network_addresses' => [],
        'dns_records' => []
      }

      backup_file = Rack::Test::UploadedFile.new(
        StringIO.new(v1_backup.to_json), 'application/json', false, original_filename: 'v1.json'
      )
      post '/admin/backups/restore', params: { backup_file: backup_file, clear_existing: '1' }
      expect(response).to redirect_to('/admin/backups')
    end
  end
end
