# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IpAllocation do
  before do
    @vpn_configuration = VpnConfiguration.get_vpn_configuration
  end

  it 'allocates first ip address' do
    ip = described_class.next_available_ip
    expect(ip).to eq('10.42.5.2')
  end
end
