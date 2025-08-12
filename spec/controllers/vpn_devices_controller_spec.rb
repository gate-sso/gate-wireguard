# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VpnDevicesController, type: :controller do
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
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:require_login).and_return(true)
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
        get :download_config, params: { id: vpn_device.id }

        expect(response).to have_http_status(:success)
        expect(response.headers['Content-Disposition']).to include('filename="vpn.example.com.conf"')
        expect(response.content_type).to eq('application/octet-stream')
      end

      it 'generates correct config content' do
        get :download_config, params: { id: vpn_device.id }

        expect(response.body).to include('[Interface]')
        expect(response.body).to include('[Peer]')
        expect(response.body).to include('Endpoint = vpn.example.com:51820')
      end
    end

    context 'with IP address only' do
      let!(:vpn_configuration) do
        VpnConfiguration.create!(
          wg_fqdn: nil,
          wg_ip_address: '192.168.100.50',
          wg_private_key: 'server_private_key',
          wg_public_key: 'server_public_key',
          wg_port: '51820',
          server_vpn_ip_address: '10.42.5.254'
        )
      end

      it 'downloads config with IP-based filename' do
        get :download_config, params: { id: vpn_device.id }

        expect(response).to have_http_status(:success)
        expect(response.headers['Content-Disposition']).to include('filename="192_168_100_50.conf"')
      end

      it 'generates config with IP endpoint' do
        get :download_config, params: { id: vpn_device.id }

        expect(response.body).to include('Endpoint = 192.168.100.50:51820')
      end
    end

    context 'with empty FQDN but IP configured' do
      let!(:vpn_configuration) do
        VpnConfiguration.create!(
          wg_fqdn: '',
          wg_ip_address: '203.0.113.25',
          wg_private_key: 'server_private_key',
          wg_public_key: 'server_public_key',
          wg_port: '51820',
          server_vpn_ip_address: '10.42.5.254'
        )
      end

      it 'uses IP-based filename when FQDN is empty' do
        get :download_config, params: { id: vpn_device.id }

        expect(response.headers['Content-Disposition']).to include('filename="203_0_113_25.conf"')
      end
    end

    context 'without FQDN or IP configured' do
      let!(:vpn_configuration) do
        VpnConfiguration.create!(
          wg_fqdn: nil,
          wg_ip_address: nil,
          wg_private_key: 'server_private_key',
          wg_public_key: 'server_public_key',
          wg_port: '51820',
          server_vpn_ip_address: '10.42.5.254'
        )
      end

      it 'falls back to default filename' do
        get :download_config, params: { id: vpn_device.id }

        expect(response.headers['Content-Disposition']).to include('filename="gate_vpn_config.conf"')
      end
    end

    context 'with complex FQDN' do
      let!(:vpn_configuration) do
        VpnConfiguration.create!(
          wg_fqdn: 'secure-vpn.corporate.example.com',
          wg_private_key: 'server_private_key',
          wg_public_key: 'server_public_key',
          wg_port: '51820',
          server_vpn_ip_address: '10.42.5.254'
        )
      end

      it 'handles complex FQDN correctly' do
        get :download_config, params: { id: vpn_device.id }

        expect(response.headers['Content-Disposition']).to include('filename="secure-vpn.corporate.example.com.conf"')
        expect(response.body).to include('Endpoint = secure-vpn.corporate.example.com:51820')
      end
    end

    context 'with special characters in IP' do
      let!(:vpn_configuration) do
        VpnConfiguration.create!(
          wg_fqdn: nil,
          wg_ip_address: '10.0.0.1',
          wg_private_key: 'server_private_key',
          wg_public_key: 'server_public_key',
          wg_port: '51820',
          server_vpn_ip_address: '10.42.5.254'
        )
      end

      it 'replaces dots with underscores in filename' do
        get :download_config, params: { id: vpn_device.id }

        expect(response.headers['Content-Disposition']).to include('filename="10_0_0_1.conf"')
        expect(response.headers['Content-Disposition']).not_to include('10.0.0.1.conf')
      end
    end

    context 'filename priority testing' do
      context 'both FQDN and IP present' do
        let!(:vpn_configuration) do
          VpnConfiguration.create!(
            wg_fqdn: 'priority.example.com',
            wg_ip_address: '198.51.100.10',
            wg_private_key: 'server_private_key',
            wg_public_key: 'server_public_key',
            wg_port: '51820',
            server_vpn_ip_address: '10.42.5.254'
          )
        end

        it 'prioritizes FQDN over IP for filename' do
          get :download_config, params: { id: vpn_device.id }

          expect(response.headers['Content-Disposition']).to include('filename="priority.example.com.conf"')
          expect(response.headers['Content-Disposition']).not_to include('198_51_100_10.conf')
        end
      end
    end

    context 'error handling' do
      it 'handles non-existent VPN device' do
        expect {
          get :download_config, params: { id: 99999 }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'filename generation logic' do
    let!(:vpn_configuration) do
      VpnConfiguration.create!(
        wg_private_key: 'server_private_key',
        wg_public_key: 'server_public_key',
        wg_port: '51820',
        server_vpn_ip_address: '10.42.5.254'
      )
    end

    it 'handles various IP formats correctly' do
      test_cases = [
        { ip: '1.2.3.4', expected: '1_2_3_4.conf' },
        { ip: '192.168.1.1', expected: '192_168_1_1.conf' },
        { ip: '10.0.0.0', expected: '10_0_0_0.conf' },
        { ip: '255.255.255.255', expected: '255_255_255_255.conf' }
      ]

      test_cases.each do |test_case|
        vpn_configuration.update!(wg_ip_address: test_case[:ip], wg_fqdn: nil)
        get :download_config, params: { id: vpn_device.id }

        expect(response.headers['Content-Disposition']).to include("filename=\"#{test_case[:expected]}\"")
      end
    end

    it 'handles various FQDN formats correctly' do
      test_cases = [
        'vpn.com',
        'secure.vpn.example.org',
        'vpn-server.company.co.uk',
        'test123.subdomain.domain.net'
      ]

      test_cases.each do |fqdn|
        vpn_configuration.update!(wg_fqdn: fqdn)
        get :download_config, params: { id: vpn_device.id }

        expect(response.headers['Content-Disposition']).to include("filename=\"#{fqdn}.conf\"")
      end
    end
  end
end
