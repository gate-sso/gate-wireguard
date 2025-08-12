# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'FQDN Resolution' do
  describe 'VPN Configuration Model' do
    it 'saves wg_fqdn and wg_ip_address correctly' do
      config = VpnConfiguration.new
      config.wg_fqdn = 'vpn.example.com'
      config.wg_ip_address = '93.184.216.34'
      config.wg_port = '51820'
      config.wg_ip_range = '10.8.0.0'
      config.wg_private_key = 'test_private_key'
      config.wg_public_key = 'test_public_key'

      expect(config.save).to be_truthy
      expect(config.wg_fqdn).to eq('vpn.example.com')
      expect(config.wg_ip_address).to eq('93.184.216.34')
    end

    it 'allows empty FQDN while keeping IP address' do
      config = VpnConfiguration.new
      config.wg_fqdn = ''
      config.wg_ip_address = '1.2.3.4'
      config.wg_port = '51820'
      config.wg_ip_range = '10.8.0.0'
      config.wg_private_key = 'test_private_key'
      config.wg_public_key = 'test_public_key'

      expect(config.save).to be_truthy
      expect(config.wg_fqdn).to be_blank
      expect(config.wg_ip_address).to eq('1.2.3.4')
    end

    it 'can handle nil values for FQDN and IP address' do
      config = VpnConfiguration.new
      config.wg_fqdn = nil
      config.wg_ip_address = nil
      config.wg_port = '51820'
      config.wg_ip_range = '10.8.0.0'
      config.wg_private_key = 'test_private_key'
      config.wg_public_key = 'test_public_key'

      expect(config.save).to be_truthy
      expect(config.wg_fqdn).to be_nil
      expect(config.wg_ip_address).to be_nil
    end
  end
end
