# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Devices' do
  let(:api_key) { ApiKey.generate(name: 'Test Key') }
  let(:auth_headers) { { 'Authorization' => "Bearer #{api_key.raw_token}" } }

  let(:fake_private_key) { SecureRandom.base64(32) }
  let(:fake_public_key) { SecureRandom.base64(32) }
  let(:success_status) { instance_double(Process::Status, success?: true, exitstatus: 0) }

  let(:vpn_config) do
    VpnConfiguration.create!(
      wg_private_key: SecureRandom.base64(32),
      wg_public_key: SecureRandom.base64(32),
      wg_port: '51820',
      wg_ip_range: '10.42.5.0',
      server_vpn_ip_address: '10.42.5.1',
      wg_interface_name: 'wg0',
      wg_keep_alive: '25',
      wg_forward_interface: 'eth0',
      wg_fqdn: 'gate.example.com'
    )
  end

  before do
    vpn_config # ensure VpnConfiguration exists

    allow(Open3).to receive(:capture2).with('wg genkey').and_return(["#{fake_private_key}\n", success_status])
    allow(Open3).to receive(:capture2).with('wg pubkey', stdin_data: fake_private_key).and_return(
      ["#{fake_public_key}\n", success_status]
    )

    # Stub server config writing (writes to filesystem)
    allow(WireguardConfigGenerator).to receive(:write_server_configuration)
  end

  def create_device_via_api(name: 'test-device')
    post '/api/v1/devices', params: { device: { name: name } }, headers: auth_headers, as: :json
  end

  def create_web_device(user:, description:)
    device = user.vpn_devices.build(description: description)
    device.public_key = SecureRandom.base64(32)
    device.private_key = SecureRandom.base64(32)
    device.save!
    IpAllocation.allocate_ip(device)
    device
  end

  describe 'authentication' do
    it 'returns 401 without an API key' do
      get '/api/v1/devices'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 401 with an invalid API key' do
      get '/api/v1/devices', headers: { 'Authorization' => 'Bearer gw_bogus' }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 401 with a revoked API key' do
      api_key.revoke!
      get '/api/v1/devices', headers: auth_headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'succeeds with a valid API key' do
      get '/api/v1/devices', headers: auth_headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /api/v1/devices' do
    it 'creates a VpnDevice with IP allocation' do
      create_device_via_api(name: 'my-laptop')

      expect(response).to have_http_status(:created)
      json = response.parsed_body
      expect(json['name']).to eq('my-laptop')
      expect(json['vpn_ip']).to be_present
      expect(json['public_key']).to eq(fake_public_key)
      expect(json['config']).to include('[Interface]')
      expect(json['config']).to include('PrivateKey')
      expect(json['id']).to be_present
    end

    it 'returns config_filename as name.gate.clawstation.conf' do
      create_device_via_api(name: 'host01-cnt03')

      json = response.parsed_body
      expect(json['config_filename']).to eq('host01-cnt03.gate.clawstation.conf')
    end

    it 'sanitizes special characters in config_filename' do
      create_device_via_api(name: 'My Device #1')

      json = response.parsed_body
      expect(json['config_filename']).to eq('my_device__1.gate.clawstation.conf')
    end

    it 'creates device owned by API system user' do
      create_device_via_api(name: 'api-device')

      device = VpnDevice.last
      expect(device.user.provider).to eq('api')
      expect(device.user.email).to eq('api@gate.clawstation.ai')
      expect(device.user.name).to eq('API System')
    end

    it 'allocates IP from VpnConfiguration range' do
      create_device_via_api(name: 'range-test')

      json = response.parsed_body
      expect(json['vpn_ip']).to start_with('10.42.5.')
    end

    it 'returns 422 when name is blank' do
      create_device_via_api(name: '')

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body['error']).to eq('Name is required')
    end

    it 'stores name as VpnDevice description' do
      create_device_via_api(name: 'stored-name')

      expect(VpnDevice.last.description).to eq('stored-name')
    end

    it 'device is visible alongside web-created devices' do
      user = User.create!(email: 'web@test.com', name: 'Web User', provider: 'google_oauth2', uid: '111', active: true)
      create_web_device(user: user, description: 'web-device')
      create_device_via_api(name: 'api-device')

      expect(VpnDevice.count).to eq(2)
    end

    it 'regenerates server config after creation' do
      create_device_via_api(name: 'regen-test')

      expect(WireguardConfigGenerator).to have_received(:write_server_configuration).with(vpn_config)
    end
  end

  describe 'IP allocation across web and API' do
    let(:web_user) do
      User.create!(email: 'web@test.com', name: 'Web User', provider: 'google_oauth2', uid: '111', active: true)
    end

    it 'allocates unique IPs when interleaving web and API device creation' do
      # Web device gets first IP
      web_device1 = create_web_device(user: web_user, description: 'web-device-1')
      web_ip1 = web_device1.ip_allocation.ip_address
      expect(web_ip1).to eq('10.42.5.2')

      # API device gets next IP (not the same as web)
      create_device_via_api(name: 'api-device-1')
      api_ip1 = response.parsed_body['vpn_ip']
      expect(api_ip1).to eq('10.42.5.3')

      # Another web device gets next available
      web_device2 = create_web_device(user: web_user, description: 'web-device-2')
      web_ip2 = web_device2.ip_allocation.ip_address
      expect(web_ip2).to eq('10.42.5.4')

      # Another API device continues sequentially
      create_device_via_api(name: 'api-device-2')
      api_ip2 = response.parsed_body['vpn_ip']
      expect(api_ip2).to eq('10.42.5.5')

      # All IPs are unique
      all_ips = [web_ip1, api_ip1, web_ip2, api_ip2]
      expect(all_ips.uniq.length).to eq(4)
    end

    it 'reuses freed IPs after web device deletion' do
      web_device = create_web_device(user: web_user, description: 'temp-device')
      freed_ip = web_device.ip_allocation.ip_address
      expect(freed_ip).to eq('10.42.5.2')

      # Create a second device
      create_device_via_api(name: 'api-device')
      expect(response.parsed_body['vpn_ip']).to eq('10.42.5.3')

      # Delete the web device, freeing .2
      web_device.destroy!

      # Next API device should get the freed .2 back
      create_device_via_api(name: 'api-reclaim')
      expect(response.parsed_body['vpn_ip']).to eq('10.42.5.2')
    end

    it 'shares the same IpAllocation table for both web and API devices' do
      create_web_device(user: web_user, description: 'web-shared')
      create_device_via_api(name: 'api-shared')

      expect(IpAllocation.count).to eq(2)
      ips = IpAllocation.pluck(:ip_address)
      expect(ips).to contain_exactly('10.42.5.2', '10.42.5.3')
    end
  end

  describe 'GET /api/v1/devices' do
    it 'returns all devices as JSON' do
      create_device_via_api(name: 'list-device')

      get '/api/v1/devices', headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json.length).to eq(1)
      expect(json.first['name']).to eq('list-device')
      expect(json.first['config']).to include('[Interface]')
    end

    it 'returns empty array when no devices exist' do
      get '/api/v1/devices', headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq([])
    end

    it 'includes web-created devices' do
      user = User.create!(email: 'web@test.com', name: 'Web User', provider: 'google_oauth2', uid: '111', active: true)
      create_web_device(user: user, description: 'web-device')

      get '/api/v1/devices', headers: auth_headers

      json = response.parsed_body
      expect(json.length).to eq(1)
      expect(json.first['name']).to eq('web-device')
    end
  end

  describe 'GET /api/v1/devices/:id' do
    it 'returns a single device' do
      create_device_via_api(name: 'show-device')
      device_id = response.parsed_body['id']

      get "/api/v1/devices/#{device_id}", headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['name']).to eq('show-device')
      expect(json['config_filename']).to eq('show-device.gate.clawstation.conf')
    end

    it 'returns 404 for non-existent device' do
      get '/api/v1/devices/99999', headers: auth_headers

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body['error']).to eq('Device not found')
    end
  end

  describe 'DELETE /api/v1/devices/:id' do
    it 'destroys the device and its IP allocation' do
      create_device_via_api(name: 'delete-me')
      device_id = response.parsed_body['id']

      expect { delete "/api/v1/devices/#{device_id}", headers: auth_headers }
        .to change(VpnDevice, :count).by(-1)

      # IP allocation is soft-deleted (marked unallocated), not destroyed
      expect(IpAllocation.where(allocated: false).count).to eq(1)

      expect(response).to have_http_status(:ok)
    end

    it 'regenerates server config after deletion' do
      create_device_via_api(name: 'regen-delete')
      device_id = response.parsed_body['id']

      delete "/api/v1/devices/#{device_id}", headers: auth_headers

      # Called once for create and once for delete
      expect(WireguardConfigGenerator).to have_received(:write_server_configuration).with(vpn_config).at_least(:twice)
    end

    it 'returns 404 for non-existent device' do
      delete '/api/v1/devices/99999', headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
