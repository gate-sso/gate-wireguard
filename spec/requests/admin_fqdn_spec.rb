# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin FQDN Configuration' do
  let(:admin_user) do
    User.create!(name: 'Test User', email: 'test@example.com', admin: true, provider: 'oauth', uid: '12345')
  end
  let(:vpn_config) { VpnConfiguration.get_vpn_configuration }

  before do
    # Create the user and set up session-based authentication
    admin_user
    vpn_config # Ensure VPN configuration exists
  end

  describe 'PATCH /admin/vpn_configuration/:id' do
    it 'updates VPN configuration with wg_fqdn parameter' do
      # Set up session before making the request
      allow_any_instance_of(ActionController::Base).to receive(:session).and_return({ user_id: admin_user.id })

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
      # Set up session before making the request
      allow_any_instance_of(ActionController::Base).to receive(:session).and_return({ user_id: admin_user.id })

      patch "/admin/vpn_configuration/#{vpn_config.id}", params: {
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
      expect(response).to redirect_to('/admin/vpn_configurations')
    end

    it 'preserves existing FQDN when not provided in update' do
      # Set up session before making the request
      allow_any_instance_of(ActionController::Base).to receive(:session).and_return({ user_id: admin_user.id })

      # First set an FQDN
      vpn_config.update!(wg_fqdn: 'existing.domain.com')

      # Update other fields without touching FQDN
      patch "/admin/vpn_configuration/#{vpn_config.id}", params: {
        vpn_configuration: {
          wg_ip_address: '10.0.0.1',
          wg_port: '51822'
        }
      }

      vpn_config.reload
      expect(vpn_config.wg_fqdn).to eq('existing.domain.com')
      expect(vpn_config.wg_ip_address).to eq('10.0.0.1')
      expect(vpn_config.wg_port).to eq('51822')
    end

    it 'requires admin access' do
      regular_user = User.create!(name: 'Regular User', email: 'user@example.com', admin: false, provider: 'oauth',
                                  uid: '67890')
      # Set up session for regular user
      allow_any_instance_of(ActionController::Base).to receive(:session).and_return({ user_id: regular_user.id })

      patch "/admin/vpn_configuration/#{vpn_config.id}", params: {
        vpn_configuration: {
          wg_fqdn: 'unauthorized.com'
        }
      }

      expect(response).to redirect_to(root_path)
    end

    it 'handles invalid configuration data' do
      # Set up session before making the request
      allow_any_instance_of(ActionController::Base).to receive(:session).and_return({ user_id: admin_user.id })

      patch "/admin/vpn_configuration/#{vpn_config.id}", params: {
        vpn_configuration: {
          wg_port: 'invalid_port'
        }
      }

      # Should handle the error gracefully and show the form again or redirect
      expect(response.status).to be_in([200, 302, 422])
    end
  end
end
