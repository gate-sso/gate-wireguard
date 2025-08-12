# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WireguardConfigGenerator do
  let(:vpn_configuration) do
    VpnConfiguration.create!(
      wg_private_key: 'test_private_key',
      wg_public_key: 'test_public_key',
      wg_port: '51820',
      wg_ip_range: '10.42.5.0/24',
      server_vpn_ip_address: '10.42.5.254',
      wg_ip_address: '203.0.113.10',
      dns_servers: '8.8.8.8, 8.8.4.4'
    )
  end

  let(:user) { User.create!(email: 'test@example.com', name: 'Test User') }
  let(:vpn_device) do
    device = user.vpn_devices.create!(
      description: 'Test Device',
      private_key: 'client_private_key',
      public_key: 'client_public_key'
    )
    IpAllocation.create!(vpn_device: device, ip_address: '10.42.5.100')
    device
  end

  describe '.generate_server_config' do
    it 'generates server configuration with proper defaults' do
      config = described_class.generate_server_config

      expect(config[:port]).to eq(51_820)
      expect(config[:range]).to eq('10.42.5.0')
      expect(config[:interface_name]).to eq('wg0')
      expect(config[:keep_alive]).to eq('25')
      expect(config[:forward_interface]).to eq('eth0')
      expect(config[:dns_servers]).to be_nil
    end

    it 'generates unique keys each time' do
      allow(Open3).to receive(:capture2).and_return(['unique_key_123', nil])

      config1 = described_class.generate_server_config
      config2 = described_class.generate_server_config

      expect(config1[:private_key]).to eq('unique_key_123')
      expect(config2[:private_key]).to eq('unique_key_123')
    end
  end

  describe '.generate_client_config' do
    context 'with FQDN configured' do
      before do
        vpn_configuration.update!(wg_fqdn: 'vpn.example.com')
      end

      it 'uses FQDN as endpoint' do
        config = described_class.generate_client_config(vpn_device, vpn_configuration)

        expect(config).to include('Endpoint = vpn.example.com:51820')
        expect(config).not_to include('Endpoint = 203.0.113.10:51820')
      end

      it 'includes all required sections' do
        config = described_class.generate_client_config(vpn_device, vpn_configuration)

        expect(config).to include('[Interface]')
        expect(config).to include('[Peer]')
        expect(config).to include('PrivateKey = client_private_key')
        expect(config).to include('Address = 10.42.5.100/24')
        expect(config).to include('PublicKey = test_public_key')
      end

      it 'includes configured DNS servers' do
        config = described_class.generate_client_config(vpn_device, vpn_configuration)

        expect(config).to include('DNS = 8.8.8.8, 8.8.4.4')
      end
    end

    context 'without FQDN configured' do
      it 'uses IP address as endpoint' do
        config = described_class.generate_client_config(vpn_device, vpn_configuration)

        expect(config).to include('Endpoint = 203.0.113.10:51820')
        expect(config).not_to include('vpn.example.com')
      end
    end

    context 'with custom DNS servers' do
      before do
        vpn_configuration.update!(dns_servers: '1.1.1.1, 1.0.0.1')
      end

      it 'uses custom DNS servers' do
        config = described_class.generate_client_config(vpn_device, vpn_configuration)

        expect(config).to include('DNS = 1.1.1.1, 1.0.0.1')
        expect(config).not_to include('DNS = 8.8.8.8, 8.8.4.4')
      end
    end

    context 'without DNS servers configured' do
      before do
        vpn_configuration.update!(dns_servers: nil)
      end

      it 'falls back to default DNS servers' do
        config = described_class.generate_client_config(vpn_device, vpn_configuration)

        expect(config).to include('DNS = 8.8.8.8, 8.8.4.4')
      end
    end

    context 'with empty DNS servers' do
      before do
        vpn_configuration.update!(dns_servers: '')
      end

      it 'uses default DNS servers for empty string' do
        config = described_class.generate_client_config(vpn_device, vpn_configuration)

        expect(config).to include('DNS = 8.8.8.8, 8.8.4.4')
      end
    end

    context 'with network addresses' do
      before do
        vpn_configuration.network_addresses.create!(network_address: '192.168.1.0/24')
        vpn_configuration.network_addresses.create!(network_address: '172.16.0.0/16')
      end

      it 'includes all network addresses in AllowedIPs' do
        config = described_class.generate_client_config(vpn_device, vpn_configuration)

        expect(config).to include('AllowedIPs = 192.168.1.0/24')
        expect(config).to include('AllowedIPs = 172.16.0.0/16')
        expect(config).to include('AllowedIPs = 10.42.5.254/32')
      end
    end

    context 'with keep alive configured' do
      before do
        vpn_configuration.update!(wg_keep_alive: '30')
      end

      it 'includes PersistentKeepalive' do
        config = described_class.generate_client_config(vpn_device, vpn_configuration)

        expect(config).to include('PersistentKeepalive = 20')
      end
    end

    context 'without keep alive configured' do
      before do
        vpn_configuration.update!(wg_keep_alive: nil)
      end

      it 'does not include PersistentKeepalive' do
        config = described_class.generate_client_config(vpn_device, vpn_configuration)

        expect(config).not_to include('PersistentKeepalive')
      end
    end
  end

  describe 'endpoint priority logic' do
    context 'both FQDN and IP configured' do
      before do
        vpn_configuration.update!(
          wg_fqdn: 'vpn.example.com',
          wg_ip_address: '203.0.113.10'
        )
      end

      it 'prioritizes FQDN over IP address' do
        config = described_class.generate_client_config(vpn_device, vpn_configuration)

        expect(config).to include('Endpoint = vpn.example.com:51820')
        expect(config).not_to include('Endpoint = 203.0.113.10:51820')
      end
    end

    context 'only IP configured' do
      before do
        vpn_configuration.update!(
          wg_fqdn: nil,
          wg_ip_address: '203.0.113.10'
        )
      end

      it 'uses IP address when FQDN is nil' do
        config = described_class.generate_client_config(vpn_device, vpn_configuration)

        expect(config).to include('Endpoint = 203.0.113.10:51820')
      end
    end

    context 'empty FQDN with IP configured' do
      before do
        vpn_configuration.update!(
          wg_fqdn: '',
          wg_ip_address: '203.0.113.10'
        )
      end

      it 'uses IP address when FQDN is empty string' do
        config = described_class.generate_client_config(vpn_device, vpn_configuration)

        expect(config).to include('Endpoint = 203.0.113.10:51820')
      end
    end
  end

  describe 'DNS fallback logic' do
    it 'uses configured DNS when present' do
      vpn_configuration.update!(dns_servers: 'custom.dns.com, backup.dns.com')
      config = described_class.generate_client_config(vpn_device, vpn_configuration)

      expect(config).to include('DNS = custom.dns.com, backup.dns.com')
    end

    it 'falls back to Google DNS when DNS is nil' do
      vpn_configuration.update!(dns_servers: nil)
      config = described_class.generate_client_config(vpn_device, vpn_configuration)

      expect(config).to include('DNS = 8.8.8.8, 8.8.4.4')
    end

    it 'falls back to Google DNS when DNS is empty' do
      vpn_configuration.update!(dns_servers: '')
      config = described_class.generate_client_config(vpn_device, vpn_configuration)

      expect(config).to include('DNS = 8.8.8.8, 8.8.4.4')
    end

    it 'falls back to Google DNS when DNS is whitespace only' do
      vpn_configuration.update!(dns_servers: '   ')
      config = described_class.generate_client_config(vpn_device, vpn_configuration)

      expect(config).to include('DNS = 8.8.8.8, 8.8.4.4')
    end
  end

  describe 'complete configuration scenarios' do
    context 'professional FQDN setup' do
      before do
        vpn_configuration.update!(
          wg_fqdn: 'corporate-vpn.company.com',
          dns_servers: 'internal.dns.company.com, 8.8.8.8',
          wg_keep_alive: '25'
        )
        vpn_configuration.network_addresses.create!(network_address: '10.0.0.0/8')
        vpn_configuration.network_addresses.create!(network_address: '172.16.0.0/12')
      end

      it 'generates complete professional configuration' do
        config = described_class.generate_client_config(vpn_device, vpn_configuration)

        # Check interface section
        expect(config).to include('[Interface]')
        expect(config).to include('PrivateKey = client_private_key')
        expect(config).to include('Address = 10.42.5.100/24')
        expect(config).to include('DNS = internal.dns.company.com, 8.8.8.8')

        # Check peer section
        expect(config).to include('[Peer]')
        expect(config).to include('PublicKey = test_public_key')
        expect(config).to include('Endpoint = corporate-vpn.company.com:51820')
        expect(config).to include('AllowedIPs = 10.42.5.254/32')
        expect(config).to include('AllowedIPs = 10.0.0.0/8')
        expect(config).to include('AllowedIPs = 172.16.0.0/12')
        expect(config).to include('PersistentKeepalive = 20')
      end
    end

    context 'basic IP setup' do
      before do
        vpn_configuration.update!(
          wg_fqdn: nil,
          dns_servers: nil,
          wg_keep_alive: nil
        )
      end

      it 'generates basic IP-based configuration' do
        config = described_class.generate_client_config(vpn_device, vpn_configuration)

        expect(config).to include('Endpoint = 203.0.113.10:51820')
        expect(config).to include('DNS = 8.8.8.8, 8.8.4.4')
        expect(config).not_to include('PersistentKeepalive')
      end
    end
  end
end
