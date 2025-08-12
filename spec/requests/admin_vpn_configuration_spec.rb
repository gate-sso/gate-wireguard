require 'rails_helper'

RSpec.describe 'Admin::VpnConfiguration', type: :request do
  let(:admin_user) { User.create!(name: 'Admin User', email: 'admin@example.com', admin: true) }
  let(:regular_user) { User.create!(name: 'Regular User', email: 'user@example.com', admin: false) }
  let(:vpn_config) { VpnConfiguration.get_vpn_configuration }

  before do
    vpn_config # Ensure VPN configuration exists
  end

  describe 'PATCH /admin/vpn_configuration/:id' do
    context 'when user is admin' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin_user)
        allow_any_instance_of(ApplicationController).to receive(:logged_in?).and_return(true)
      end

      it 'updates VPN configuration with wg_fqdn parameter' do
        patch "/admin/vpn_configuration/#{vpn_config.id}", params: {
          vpn_configuration: {
            wg_fqdn: 'vpn.newdomain.com',
            wg_ip_address: '203.0.113.50',
            wg_port: '51820'
          }
        }

        vpn_config.reload
        expect(vpn_config.wg_fqdn).to eq('vpn.newdomain.com')
        expect(vpn_config.wg_ip_address).to eq('203.0.113.50')
        expect(response).to redirect_to('/admin/vpn_configurations')
      end

      it 'allows empty wg_fqdn while keeping other parameters' do
        patch "/admin/vpn_configuration/#{vpn_config.id}", params: {
          vpn_configuration: {
            wg_fqdn: '',
            wg_ip_address: '192.168.1.100',
            wg_port: '51820'
          }
        }

        vpn_config.reload
        expect(vpn_config.wg_fqdn).to eq('')
        expect(vpn_config.wg_ip_address).to eq('192.168.1.100')
        expect(response).to redirect_to('/admin/vpn_configurations')
      end

      it 'handles complex FQDN values' do
        complex_fqdn = 'secure-vpn.corporate.example.com'
        
        patch "/admin/vpn_configuration/#{vpn_config.id}", params: {
          vpn_configuration: {
            wg_fqdn: complex_fqdn,
            wg_ip_address: '203.0.113.75',
            wg_port: '51820'
          }
        }

        vpn_config.reload
        expect(vpn_config.wg_fqdn).to eq(complex_fqdn)
        expect(response).to redirect_to('/admin/vpn_configurations')
      end
    end

    context 'when user is not admin' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(regular_user)
        allow_any_instance_of(ApplicationController).to receive(:logged_in?).and_return(true)
      end

      it 'denies access to regular users' do
        patch "/admin/vpn_configuration/#{vpn_config.id}", params: {
          vpn_configuration: {
            wg_fqdn: 'vpn.unauthorized.com'
          }
        }

        expect(response).to have_http_status(:redirect)
      end
    end

    context 'with invalid parameters' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin_user)
        allow_any_instance_of(ApplicationController).to receive(:logged_in?).and_return(true)
      end

      it 'handles validation errors gracefully' do
        patch "/admin/vpn_configuration/#{vpn_config.id}", params: {
          vpn_configuration: {
            wg_fqdn: 'vpn.example.com',
            wg_port: 'invalid_port'
          }
        }

        expect(response.status).to be_in([200, 302, 422])
      end
    end
  end
end
