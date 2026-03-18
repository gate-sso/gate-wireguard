# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IpAllocation do
  let!(:vpn_configuration) do
    VpnConfiguration.create!(
      wg_ip_range: '10.42.5.0/24',
      server_vpn_ip_address: '10.42.5.254',
      wg_port: '51820',
      wg_private_key: 'test_private_key',
      wg_public_key: 'test_public_key'
    )
  end

  let(:user) { User.create!(email: 'test@example.com', name: 'Test User', active: true) }

  def create_device(description)
    device = user.vpn_devices.build(description: description)
    device.public_key = SecureRandom.base64(32)
    device.private_key = SecureRandom.base64(32)
    device.save!
    device
  end

  describe '.allocate_ip' do
    it 'allocates the first available IP' do
      device = create_device('device-1')
      allocation = described_class.allocate_ip(device)

      expect(allocation).to be_present
      expect(allocation.ip_address).to eq('10.42.5.1')
      expect(allocation.allocated).to be true
      expect(allocation.vpn_device).to eq(device)
    end

    it 'allocates sequential IPs for multiple devices' do
      device1 = create_device('device-1')
      device2 = create_device('device-2')

      alloc1 = described_class.allocate_ip(device1)
      alloc2 = described_class.allocate_ip(device2)

      expect(alloc1.ip_address).to eq('10.42.5.1')
      expect(alloc2.ip_address).to eq('10.42.5.2')
    end

    it 'recycles deallocated IPs before allocating fresh ones' do
      device1 = create_device('device-1')
      device2 = create_device('device-2')
      device3 = create_device('device-3')

      described_class.allocate_ip(device1) # gets .1
      described_class.allocate_ip(device2) # gets .2

      # Deallocate device1's IP (.1)
      described_class.deallocate_ip(device1)

      # Next allocation should recycle .1
      alloc3 = described_class.allocate_ip(device3)
      expect(alloc3.ip_address).to eq('10.42.5.1')
    end
  end

  describe '.deallocate_ip' do
    it 'marks the IP as unallocated and clears the device reference' do
      device = create_device('device-1')
      described_class.allocate_ip(device)

      described_class.deallocate_ip(device)

      allocation = described_class.find_by(ip_address: '10.42.5.1')
      expect(allocation.allocated).to be false
      expect(allocation.vpn_device_id).to be_nil
    end

    it 'does not delete the row' do
      device = create_device('device-1')
      described_class.allocate_ip(device)

      expect { described_class.deallocate_ip(device) }.not_to change(described_class, :count)
    end
  end

  describe '.next_fresh_ip' do
    it 'computes IP from count-based offset' do
      expect(described_class.next_fresh_ip).to eq('10.42.5.1')
    end

    it 'skips the server IP' do
      vpn_configuration.update!(
        wg_ip_range: '10.42.5.0/30',
        server_vpn_ip_address: '10.42.5.1'
      )

      # .0 is network, .1 is server, .2 should be first available
      expect(described_class.next_fresh_ip).to eq('10.42.5.2')
    end
  end
end
