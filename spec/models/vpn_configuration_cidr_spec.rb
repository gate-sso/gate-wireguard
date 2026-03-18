# frozen_string_literal: true

require 'rails_helper'
require 'ipaddr'

RSpec.describe VpnConfiguration do
  describe '#cidr_prefix' do
    it 'parses CIDR prefix from wg_ip_range' do
      config = described_class.new(wg_ip_range: '10.42.5.0/24')
      expect(config.cidr_prefix).to eq(24)
    end

    it 'handles /16 networks' do
      config = described_class.new(wg_ip_range: '192.168.0.0/16')
      expect(config.cidr_prefix).to eq(16)
    end

    it 'handles /8 networks' do
      config = described_class.new(wg_ip_range: '10.0.0.0/8')
      expect(config.cidr_prefix).to eq(8)
    end

    it 'defaults to 24 when no CIDR specified' do
      config = described_class.new(wg_ip_range: '10.42.5.0')
      expect(config.cidr_prefix).to eq(24)
    end

    it 'defaults to 24 when wg_ip_range is blank' do
      config = described_class.new(wg_ip_range: nil)
      expect(config.cidr_prefix).to eq(24)
    end
  end

  describe '#network_address_base' do
    it 'extracts network address without CIDR suffix' do
      config = described_class.new(wg_ip_range: '10.42.5.0/24')
      expect(config.network_address_base).to eq('10.42.5.0')
    end

    it 'returns as-is when no CIDR specified' do
      config = described_class.new(wg_ip_range: '10.42.5.0')
      expect(config.network_address_base).to eq('10.42.5.0')
    end

    it 'handles /16 networks' do
      config = described_class.new(wg_ip_range: '192.168.0.0/16')
      expect(config.network_address_base).to eq('192.168.0.0')
    end
  end

  describe '.compute_last_usable_ip' do
    it 'calculates last usable IP for /24' do
      expect(described_class.compute_last_usable_ip('10.42.5.0/24')).to eq('10.42.5.254')
    end

    it 'calculates last usable IP for /16' do
      expect(described_class.compute_last_usable_ip('192.168.0.0/16')).to eq('192.168.255.254')
    end

    it 'calculates last usable IP for /8' do
      expect(described_class.compute_last_usable_ip('10.0.0.0/8')).to eq('10.255.255.254')
    end

    it 'calculates last usable IP for /30' do
      expect(described_class.compute_last_usable_ip('172.16.1.0/30')).to eq('172.16.1.2')
    end

    it 'calculates last usable IP for /28' do
      expect(described_class.compute_last_usable_ip('192.168.1.96/28')).to eq('192.168.1.110')
    end

    it 'defaults to /24 when no CIDR specified' do
      expect(described_class.compute_last_usable_ip('192.168.100.0')).to eq('192.168.100.254')
    end
  end

  describe 'IP allocation count-based offset' do
    def compute_next_ip(network_cidr, count)
      network = IPAddr.new(network_cidr)
      IPAddr.new(network.to_i + count + 1, Socket::AF_INET).to_s
    end

    it 'computes first IP when count is 0' do
      expect(compute_next_ip('10.5.0.0/16', 0)).to eq('10.5.0.1')
    end

    it 'computes third IP when count is 2' do
      expect(compute_next_ip('10.5.0.0/16', 2)).to eq('10.5.0.3')
    end

    it 'crosses octet boundary correctly' do
      expect(compute_next_ip('10.5.0.0/16', 255)).to eq('10.5.1.0')
    end

    it 'computes correct IP at offset 256' do
      expect(compute_next_ip('10.5.0.0/16', 256)).to eq('10.5.1.1')
    end

    it 'works for /24 networks' do
      expect(compute_next_ip('10.42.5.0/24', 0)).to eq('10.42.5.1')
      expect(compute_next_ip('10.42.5.0/24', 9)).to eq('10.42.5.10')
    end
  end
end
