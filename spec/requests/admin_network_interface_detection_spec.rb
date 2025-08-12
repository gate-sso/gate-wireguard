require 'rails_helper'

RSpec.describe 'Admin::NetworkInterface', type: :request do
  describe 'Network Interface Detection' do
    let(:admin_user) { User.create!(name: 'Admin User', email: 'admin@example.com', admin: true) }
    let(:regular_user) { User.create!(name: 'Regular User', email: 'user@example.com', admin: false) }

    describe 'GET /admin/vpn_configurations' do
      context 'when user is admin' do
        before do
          allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin_user)
          allow_any_instance_of(ApplicationController).to receive(:logged_in?).and_return(true)
        end

        it 'displays network interface information for admin users' do
          # Mock the helper to return test data
          allow(NetworkInterfaceHelper).to receive(:get_default_gateway_interface).and_return({
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
          # Mock the helper to return an error
          allow(NetworkInterfaceHelper).to receive(:get_default_gateway_interface).and_return({
            error: "No default route found",
            success: false
          })

          get '/admin/vpn_configurations'

          expect(response).to be_successful
          expect(response.body).to include('No default route found')
        end
      end

      context 'when user is not admin' do
        before do
          allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(regular_user)
          allow_any_instance_of(ApplicationController).to receive(:logged_in?).and_return(true)
        end

        it 'denies access to regular users' do
          get '/admin/vpn_configurations'

          expect(response).to have_http_status(:redirect)
        end
      end

      context 'when user is not logged in' do
        before do
          allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
          allow_any_instance_of(ApplicationController).to receive(:logged_in?).and_return(false)
        end

        it 'redirects to login' do
          get '/admin/vpn_configurations'

          expect(response).to have_http_status(:redirect)
        end
      end
    end
  end
end
