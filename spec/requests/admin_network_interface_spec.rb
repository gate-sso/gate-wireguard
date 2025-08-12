# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin Network Interface Detection' do
  let(:admin_user) do
    User.create!(name: 'Admin User', email: 'admin@example.com', admin: true, provider: 'oauth', uid: '12345')
  end

  before do
    # Create the user
    admin_user
  end

  describe 'GET /admin/vpn_configurations' do
    it 'populates network interface information for admin users' do
      # Set up session before making the request
      allow_any_instance_of(ActionController::Base).to receive(:session).and_return({ user_id: admin_user.id })

      # Mock the helper to return test data
      allow(NetworkInterfaceHelper).to receive(:default_gateway_interface).and_return({
                                                                                        interface_name: 'eth0',
                                                                                        ip_address: '192.168.1.100',
                                                                                        success: true
                                                                                      })

      get '/admin/vpn_configurations'

      expect(response).to be_successful
      expect(response.body).to include('eth0')
      expect(response.body).to include('192.168.1.100')
      expect(response.body).to include('Auto-detected: eth0')
      expect(response.body).to include('Auto-detected: 192.168.1.100')
    end

    it 'handles network detection errors gracefully' do
      # Set up session before making the request
      allow_any_instance_of(ActionController::Base).to receive(:session).and_return({ user_id: admin_user.id })

      # Mock the helper to return an error
      allow(NetworkInterfaceHelper).to receive(:default_gateway_interface).and_return({
                                                                                        error: 'Network detection failed',
                                                                                        success: false
                                                                                      })

      get '/admin/vpn_configurations'

      expect(response).to be_successful
      expect(response.body).to include('Could not auto-detect')
    end

    it 'requires admin access' do
      regular_user = User.create!(name: 'Regular User', email: 'user@example.com', admin: false, provider: 'oauth',
                                  uid: '67890')
      # Set up session for regular user
      allow_any_instance_of(ActionController::Base).to receive(:session).and_return({ user_id: regular_user.id })

      get '/admin/vpn_configurations'

      expect(response).to redirect_to(root_path)
      # No longer expect unauthorized message - just silent redirect
    end
  end
end
