# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VpnConfiguration, type: :model do
  let(:vpn_configuration) { VpnConfiguration.new }

  describe 'validations and attributes' do
    it 'allows setting wg_fqdn' do
      vpn_configuration.wg_fqdn = 'vpn.example.com'
      expect(vpn_configuration.wg_fqdn).to eq('vpn.example.com')
    end

    it 'allows setting dns_servers' do
      vpn_configuration.dns_servers = '8.8.8.8, 1.1.1.1'
      expect(vpn_configuration.dns_servers).to eq('8.8.8.8, 1.1.1.1')
    end

    it 'allows setting wg_ip_range' do
      vpn_configuration.wg_ip_range = '10.42.5.0/24'
      expect(vpn_configuration.wg_ip_range).to eq('10.42.5.0/24')
    end

    it 'allows setting server_vpn_ip_address' do
      vpn_configuration.server_vpn_ip_address = '10.42.5.254'
      expect(vpn_configuration.server_vpn_ip_address).to eq('10.42.5.254')
    end
  end

  describe '.get_vpn_configuration' do
    context 'when no configuration exists' do
      it 'creates a new configuration' do
        # Mock system calls that might be used by WireguardConfigGenerator
        allow(Open3).to receive(:capture2).with('wg genkey').and_return(['test_private_key', '', double(success?: true)])
        allow(Open3).to receive(:capture2).with('wg pubkey', stdin_data: 'test_private_key').and_return(['test_public_key', '', double(success?: true)])
        
        expect(VpnConfiguration.count).to eq(0)
        config = VpnConfiguration.get_vpn_configuration
        expect(VpnConfiguration.count).to eq(1)
        expect(config).to be_a(VpnConfiguration)
      end

      it 'sets default values' do
        # Mock system calls that might be used by NetworkInterfaceHelper
        allow(Open3).to receive(:capture2).with('wg genkey').and_return(['test_private_key', '', double(success?: true)])
        allow(Open3).to receive(:capture2).with('wg pubkey', stdin_data: 'test_private_key').and_return(['test_public_key', '', double(success?: true)])
        
        config = VpnConfiguration.get_vpn_configuration
        expect(config.wg_port).to eq('51820')
        expect(config.wg_ip_range).to eq('10.42.5.0')
        expect(config.wg_interface_name).to eq('wg0')
        expect(config.wg_keep_alive).to eq('25')
        expect(config.wg_forward_interface).to eq('eth0')
      end
    end

    context 'when configuration exists' do
      let!(:existing_config) { 
        VpnConfiguration.create!(
          wg_port: '51820', 
          wg_ip_range: '10.42.5.0',
          wg_private_key: 'test_private_key',
          wg_public_key: 'test_public_key',
          wg_ip_address: '192.168.1.1'
        ) 
      }

      it 'returns existing configuration' do
        config = VpnConfiguration.get_vpn_configuration
        expect(config).to eq(existing_config)
        expect(VpnConfiguration.count).to eq(1)
      end
    end
  end

  describe 'wg_fqdn functionality' do
    let!(:config) { 
      VpnConfiguration.create!(
        wg_fqdn: 'vpn.example.com', 
        wg_ip_address: '203.0.113.10',
        wg_port: '51820',
        wg_private_key: 'test_private_key',
        wg_public_key: 'test_public_key'
      ) 
    }

    it 'saves wg_fqdn correctly' do
      expect(config.wg_fqdn).to eq('vpn.example.com')
    end

    it 'can update wg_fqdn' do
      config.update!(wg_fqdn: 'new-vpn.example.com')
      expect(config.reload.wg_fqdn).to eq('new-vpn.example.com')
    end

    it 'allows nil wg_fqdn' do
      config.update!(wg_fqdn: nil)
      expect(config.reload.wg_fqdn).to be_nil
    end

    it 'handles empty string wg_fqdn' do
      config.update!(wg_fqdn: '')
      expect(config.reload.wg_fqdn).to eq('')
    end
  end

  describe 'network configuration' do
    let!(:config) { VpnConfiguration.create!(wg_ip_range: '10.42.5.0/24', server_vpn_ip_address: '10.42.5.254') }

    it 'saves network range correctly' do
      expect(config.wg_ip_range).to eq('10.42.5.0/24')
    end

    it 'saves server VPN IP correctly' do
      expect(config.server_vpn_ip_address).to eq('10.42.5.254')
    end

    it 'can update network configuration' do
      config.update!(wg_ip_range: '192.168.1.0/24', server_vpn_ip_address: '192.168.1.254')
      config.reload
      expect(config.wg_ip_range).to eq('192.168.1.0/24')
      expect(config.server_vpn_ip_address).to eq('192.168.1.254')
    end
  end

  describe 'DNS configuration' do
    let!(:config) { VpnConfiguration.create! }

    it 'allows custom DNS servers' do
      config.update!(dns_servers: '1.1.1.1, 1.0.0.1')
      expect(config.reload.dns_servers).to eq('1.1.1.1, 1.0.0.1')
    end

    it 'allows multiple DNS formats' do
      config.update!(dns_servers: '8.8.8.8,8.8.4.4,1.1.1.1')
      expect(config.reload.dns_servers).to eq('8.8.8.8,8.8.4.4,1.1.1.1')
    end

    it 'allows nil DNS servers' do
      config.update!(dns_servers: nil)
      expect(config.reload.dns_servers).to be_nil
    end
  end

  describe 'complete configuration scenarios' do
    context 'FQDN-based setup' do
      let!(:config) do
        VpnConfiguration.create!(
          wg_fqdn: 'vpn.company.com',
          wg_ip_address: '203.0.113.10',
          wg_ip_range: '10.42.5.0/24',
          server_vpn_ip_address: '10.42.5.254',
          dns_servers: '1.1.1.1, 1.0.0.1',
          wg_port: '51820'
        )
      end

      it 'saves all configuration correctly' do
        expect(config.wg_fqdn).to eq('vpn.company.com')
        expect(config.wg_ip_address).to eq('203.0.113.10')
        expect(config.wg_ip_range).to eq('10.42.5.0/24')
        expect(config.server_vpn_ip_address).to eq('10.42.5.254')
        expect(config.dns_servers).to eq('1.1.1.1, 1.0.0.1')
        expect(config.wg_port).to eq('51820')
      end
    end

    context 'IP-only setup' do
      let!(:config) do
        VpnConfiguration.create!(
          wg_ip_address: '192.168.100.1',
          wg_ip_range: '172.16.0.0/16',
          server_vpn_ip_address: '172.16.255.254',
          wg_port: '51821'
        )
      end

      it 'works without FQDN' do
        expect(config.wg_fqdn).to be_nil
        expect(config.wg_ip_address).to eq('192.168.100.1')
        expect(config.wg_ip_range).to eq('172.16.0.0/16')
        expect(config.server_vpn_ip_address).to eq('172.16.255.254')
      end
    end
  end

  describe 'associations' do
    let!(:config) { VpnConfiguration.create! }

    it 'has many network_addresses' do
      expect(config).to respond_to(:network_addresses)
      expect(config.network_addresses).to be_a(ActiveRecord::Associations::CollectionProxy)
    end

    it 'destroys dependent network_addresses' do
      config.network_addresses.create!(network_address: '192.168.1.0/24')
      expect { config.destroy! }.to change { NetworkAddress.count }.by(-1)
    end
  end
end
