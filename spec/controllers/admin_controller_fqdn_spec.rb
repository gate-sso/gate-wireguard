require 'rails_helper'

RSpec.describe AdminController, type: :controller do
  let(:user) { User.create!(name: 'Test User', email: 'test@example.com', admin: true) }
  let(:vpn_config) { VpnConfiguration.get_vpn_configuration }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:require_login).and_return(true)
    vpn_config # Ensure VPN configuration exists
  end

  describe 'PATCH #update_vpn_configuration' do
    it 'updates VPN configuration with wg_fqdn parameter' do
      patch :update_vpn_configuration, params: {
        id: vpn_config.id,
        vpn_configuration: {
          wg_fqdn: 'vpn.newdomain.com',
          wg_ip_address: '203.0.113.50',
          wg_port: '51820'
        }
      }

      vpn_config.reload
      expect(vpn_config.wg_fqdn).to eq('vpn.newdomain.com')
      expect(vpn_config.wg_ip_address).to eq('203.0.113.50')
      expect(response).to redirect_to(admin_vpn_configurations_path)
    end

    it 'allows empty wg_fqdn while keeping other parameters' do
      patch :update_vpn_configuration, params: {
        id: vpn_config.id,
        vpn_configuration: {
          wg_fqdn: '',
          wg_ip_address: '192.168.100.1',
          wg_port: '51821'
        }
      }

      vpn_config.reload
      expect(vpn_config.wg_fqdn).to be_blank
      expect(vpn_config.wg_ip_address).to eq('192.168.100.1')
      expect(vpn_config.wg_port).to eq('51821')
    end

    it 'preserves existing FQDN when not provided in update' do
      # First set an FQDN
      vpn_config.update!(wg_fqdn: 'existing.domain.com')

      # Update other fields without touching FQDN
      patch :update_vpn_configuration, params: {
        id: vpn_config.id,
        vpn_configuration: {
          wg_port: '51822'
        }
      }

      vpn_config.reload
      expect(vpn_config.wg_fqdn).to eq('existing.domain.com')
      expect(vpn_config.wg_port).to eq('51822')
    end
  end

  describe 'GET #vpn_configurations' do
    it 'responds successfully when user is admin' do
      get :vpn_configurations

      expect(response).to be_successful
    end

    it 'loads VPN configuration with FQDN data in the database' do
      vpn_config.update!(wg_fqdn: 'test.vpn.com', wg_ip_address: '1.2.3.4')

      get :vpn_configurations

      expect(response).to be_successful

      # Verify the data is in the database
      reloaded_config = VpnConfiguration.first
      expect(reloaded_config.wg_fqdn).to eq('test.vpn.com')
      expect(reloaded_config.wg_ip_address).to eq('1.2.3.4')
    end
  end

  describe 'private methods' do
    it 'includes wg_fqdn in permitted parameters' do
      controller_instance = AdminController.new
      allow(controller_instance).to receive(:params).and_return(
        ActionController::Parameters.new(
          vpn_configuration: {
            wg_fqdn: 'test.com',
            wg_ip_address: '1.1.1.1',
            wg_port: '51820',
            other_param: 'should_be_filtered'
          }
        )
      )

      permitted = controller_instance.send(:vpn_configuration_params)

      expect(permitted.keys).to include('wg_fqdn')
      expect(permitted.keys).to include('wg_ip_address')
      expect(permitted.keys).to include('wg_port')
      expect(permitted.keys).not_to include('other_param')
    end
  end
end
