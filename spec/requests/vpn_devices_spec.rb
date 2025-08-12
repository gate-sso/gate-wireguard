# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'VpnDevices', type: :request do
  let(:user) { User.create!(email: 'test@example.com', name: 'Test User') }
  let(:vpn_device) do
    device = user.vpn_devices.create!(
      description: 'Test Device',
      private_key: 'client_private_key',
      public_key: 'client_public_key'
    )
    IpAllocation.create!(vpn_device: device, ip_address: '10.42.5.100')
    device
  end

  before do
    # Simulate user login by setting session
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    allow_any_instance_of(ApplicationController).to receive(:logged_in?).and_return(true)
  end

  describe 'GET #download_config' do
    context 'with FQDN configured' do
      let!(:vpn_configuration) do
        VpnConfiguration.create!(
          wg_fqdn: 'vpn.example.com',
          wg_ip_address: '203.0.113.10',
          wg_private_key: 'server_private_key',
          wg_public_key: 'server_public_key',
          wg_port: '51820',
          server_vpn_ip_address: '10.42.5.254'
        )
      end

      it 'downloads config with FQDN filename' do
        get "/vpn_devices/download/#{vpn_device.id}"

        expect(response).to have_http_status(:success)
        expect(response.headers['Content-Disposition']).to include('filename="vpn.example.com.conf"')
        expect(response.content_type).to eq('application/octet-stream')
      end

      it 'generates correct config content' do
        get "/vpn_devices/download/#{vpn_device.id}"

        expect(response.body).to include('[Interface]')
        expect(response.body).to include('[Peer]')
        expect(response.body).to include('Endpoint = vpn.example.com:51820')
      end
    end

    context 'with IP address configured' do
      let!(:vpn_configuration) do
        VpnConfiguration.create!(
          wg_fqdn: '',
          wg_ip_address: '192.168.100.50',
          wg_private_key: 'server_private_key',
          wg_public_key: 'server_public_key',
          wg_port: '51820',
          server_vpn_ip_address: '10.42.5.254'
        )
      end

      it 'downloads config with IP filename' do
        get "/vpn_devices/download/#{vpn_device.id}"

        expect(response).to have_http_status(:success)
        expect(response.headers['Content-Disposition']).to include('filename="192_168_100_50.conf"')
      end

      it 'generates correct config content with IP endpoint' do
        get "/vpn_devices/download/#{vpn_device.id}"

        expect(response.body).to include('Endpoint = 192.168.100.50:51820')
      end
    end

    context 'with empty configuration' do
      it 'handles missing VPN configuration gracefully' do
        # Clear any existing VPN configuration
        VpnConfiguration.delete_all

        get "/vpn_devices/download/#{vpn_device.id}"

        expect(response).to have_http_status(:service_unavailable)
        expect(response.body).to include('VPN configuration not found')
      end
    end

    context 'with missing FQDN and IP' do
      let!(:vpn_configuration) do
        VpnConfiguration.create!(
          wg_fqdn: '',
          wg_ip_address: '',
          wg_private_key: 'server_private_key',
          wg_public_key: 'server_public_key',
          wg_port: '51820',
          server_vpn_ip_address: '10.42.5.254'
        )
      end

      it 'downloads config with default filename' do
        get "/vpn_devices/download/#{vpn_device.id}"

        expect(response).to have_http_status(:success)
        expect(response.headers['Content-Disposition']).to include('filename="gate_vpn_config.conf"')
      end
    end

    context 'with complex FQDN' do
      let!(:vpn_configuration) do
        VpnConfiguration.create!(
          wg_fqdn: 'secure-vpn.corporate.example.com',
          wg_ip_address: '203.0.113.10',
          wg_private_key: 'server_private_key',
          wg_public_key: 'server_public_key',
          wg_port: '51820',
          server_vpn_ip_address: '10.42.5.254'
        )
      end

      it 'handles complex FQDN correctly' do
        get "/vpn_devices/download/#{vpn_device.id}"

        expect(response).to have_http_status(:success)
        expect(response.headers['Content-Disposition']).to include('filename="secure-vpn.corporate.example.com.conf"')
        expect(response.body).to include('Endpoint = secure-vpn.corporate.example.com:51820')
      end
    end

    context 'with invalid device ID' do
      it 'handles invalid device ID gracefully' do
        get '/vpn_devices/download/99999'

        expect(response).to have_http_status(:not_found)
      end

      context 'when device does not belong to user' do
        let(:other_user) { User.create!(email: 'other@example.com', name: 'Other User') }
        let(:other_device) do
          device = other_user.vpn_devices.create!(
            description: 'Other Device',
            private_key: 'other_private_key',
            public_key: 'other_public_key'
          )
          IpAllocation.create!(vpn_device: device, ip_address: '10.42.5.101')
          device
        end

        it 'does not allow access to other users devices' do
          get "/vpn_devices/download/#{other_device.id}"

          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context 'when user is not logged in' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
        allow_any_instance_of(ApplicationController).to receive(:logged_in?).and_return(false)
      end

      it 'requires authentication' do
        get "/vpn_devices/download/#{vpn_device.id}"

        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
