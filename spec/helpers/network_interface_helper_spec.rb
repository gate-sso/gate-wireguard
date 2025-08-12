require 'rails_helper'

RSpec.describe NetworkInterfaceHelper do
  describe '.get_default_gateway_interface' do
    context 'when default route is available' do
      it 'parses device name and src IP from ip route output' do
        allow(described_class).to receive(:`).with('ip route | grep default | head -1 2>/dev/null').and_return(
          'default via 192.168.1.1 dev eth0 proto dhcp src 192.168.1.100 metric 100'
        )

        result = described_class.get_default_gateway_interface

        expect(result[:success]).to be true
        expect(result[:interface_name]).to eq('eth0')
        expect(result[:ip_address]).to eq('192.168.1.100')
      end

      it 'falls back to ip addr when no src IP in route' do
        allow(described_class).to receive(:`).with('ip route | grep default | head -1 2>/dev/null').and_return(
          'default via 192.168.1.1 dev eth0 proto dhcp metric 100'
        )
        allow(described_class).to receive(:`).with("ip addr show eth0 2>/dev/null | grep 'inet ' | grep -v '127.0.0.1' | head -1").and_return(
          'inet 192.168.1.100/24 brd 192.168.1.255 scope global dynamic eth0'
        )

        result = described_class.get_default_gateway_interface

        expect(result[:success]).to be true
        expect(result[:interface_name]).to eq('eth0')
        expect(result[:ip_address]).to eq('192.168.1.100')
      end
    end

    context 'when no default route is found' do
      it 'returns error status' do
        allow(described_class).to receive(:`).with('ip route | grep default | head -1 2>/dev/null').and_return('')

        result = described_class.get_default_gateway_interface

        expect(result[:success]).to be false
        expect(result[:error]).to eq('No default route found')
      end
    end

    context 'when route parsing fails' do
      it 'returns error when device name cannot be parsed' do
        allow(described_class).to receive(:`).with('ip route | grep default | head -1 2>/dev/null').and_return(
          'invalid route output'
        )

        result = described_class.get_default_gateway_interface

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Could not parse device name from route')
      end
    end

    context 'when system command fails' do
      it 'handles exceptions gracefully' do
        allow(described_class).to receive(:`).and_raise(StandardError.new('System command failed'))

        result = described_class.get_default_gateway_interface

        expect(result[:success]).to be false
        expect(result[:error]).to eq('System command failed')
      end
    end
  end

  describe '.get_all_interfaces' do
    it 'parses multiple interfaces from ip addr output' do
      allow(described_class).to receive(:`).with("ip addr show 2>/dev/null | grep -E '^[0-9]+:|inet ' | grep -v '127.0.0.1'").and_return(
        "2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500\n" +
        "    inet 192.168.1.100/24 brd 192.168.1.255 scope global dynamic eth0\n" +
        "3: wlan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500\n" +
        "    inet 192.168.1.101/24 brd 192.168.1.255 scope global dynamic wlan0"
      )

      result = described_class.get_all_interfaces

      expect(result[:success]).to be true
      expect(result[:interfaces]).to contain_exactly(
        { name: 'eth0', ip: '192.168.1.100' },
        { name: 'wlan0', ip: '192.168.1.101' }
      )
    end

    it 'provides fallback data when no interfaces found' do
      allow(described_class).to receive(:`).and_return('')

      result = described_class.get_all_interfaces

      expect(result[:success]).to be true
      expect(result[:interfaces]).to contain_exactly(
        { name: 'eth0', ip: '192.168.1.100' },
        { name: 'wlan0', ip: '192.168.1.101' }
      )
    end
  end

  describe '.is_default_gateway_interface?' do
    it 'returns true for the default gateway interface' do
      allow(described_class).to receive(:get_default_gateway_interface).and_return({
                                                                                     interface_name: 'eth0',
                                                                                     ip_address: '192.168.1.100',
                                                                                     success: true
                                                                                   })

      expect(described_class.is_default_gateway_interface?('eth0')).to be true
      expect(described_class.is_default_gateway_interface?('wlan0')).to be false
    end

    it 'returns false when default gateway detection fails' do
      allow(described_class).to receive(:get_default_gateway_interface).and_return({
                                                                                     error: 'No default route found',
                                                                                     success: false
                                                                                   })

      expect(described_class.is_default_gateway_interface?('eth0')).to be false
    end
  end
end
