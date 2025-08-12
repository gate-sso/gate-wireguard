require 'rails_helper'

RSpec.describe AdminController, type: :controller do
  describe 'Network Interface Detection' do
    let(:admin_user) { User.create!(name: 'Admin User', email: 'admin@example.com', admin: true) }

    before do
      allow(controller).to receive(:current_user).and_return(admin_user)
      allow(controller).to receive(:require_login).and_return(true)
    end

    describe 'GET #vpn_configurations' do
      it 'populates network interface information for admin users' do
        # Mock the helper to return test data
        allow(NetworkInterfaceHelper).to receive(:get_default_gateway_interface).and_return({
                                                                                              interface_name: 'eth0',
                                                                                              ip_address: '192.168.1.100',
                                                                                              success: true
                                                                                            })

        get :vpn_configurations

        expect(response).to be_successful
        expect(assigns(:network_interface_info)).to be_present
        expect(assigns(:network_interface_info)[:success]).to be true
        expect(assigns(:network_interface_info)[:interface_name]).to eq('eth0')
        expect(assigns(:network_interface_info)[:ip_address]).to eq('192.168.1.100')
      end

      it 'handles network detection errors gracefully' do
        # Mock the helper to return an error
        allow(NetworkInterfaceHelper).to receive(:get_default_gateway_interface).and_return({
                                                                                              error: "No default route found",
                                                                                              success: false
                                                                                            })

        get :vpn_configurations

        expect(response).to be_successful
        expect(assigns(:network_interface_info)).to be_present
        expect(assigns(:network_interface_info)[:success]).to be false
        expect(assigns(:network_interface_info)[:error]).to eq("No default route found")
      end
    end
  end
end
