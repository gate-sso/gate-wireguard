require 'rails_helper'

RSpec.describe IpAllocation, type: :model do
  before(:each) do
    @vpn_configuration = VpnConfiguration.get_vpn_configuration
  end

  it 'should allocate first ip address' do
    ip = IpAllocation.next_available_ip
    expect(ip).to eq('10.42.5.2')
  end
end
