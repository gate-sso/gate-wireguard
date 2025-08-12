# frozen_string_literal: true

require 'rails_helper'

# Integration tests for network interface detection functionality
RSpec.describe 'Network Interface Detection Integration' do
  describe 'NetworkInterfaceHelper integration' do
    it 'can detect network interfaces in real environment' do
      # This test will work in real deployment but may use fallback data in restricted environments
      result = NetworkInterfaceHelper.get_default_gateway_interface

      expect(result).to have_key(:success)
      expect(result[:success]).to be_in([true, false])

      if result[:success]
        expect(result).to have_key(:interface_name)
        expect(result).to have_key(:ip_address)
        expect(result[:interface_name]).to be_a(String)
        expect(result[:ip_address]).to match(/\A\d+\.\d+\.\d+\.\d+\z/)
      else
        expect(result).to have_key(:error)
        expect(result[:error]).to be_a(String)
      end
    end

    it 'can enumerate all interfaces' do
      result = NetworkInterfaceHelper.get_all_interfaces

      expect(result[:success]).to be true
      expect(result[:interfaces]).to be_an(Array)
      expect(result[:interfaces]).not_to be_empty

      result[:interfaces].each do |interface|
        expect(interface).to have_key(:name)
        expect(interface).to have_key(:ip)
        expect(interface[:name]).to be_a(String)
        expect(interface[:ip]).to match(/\A\d+\.\d+\.\d+\.\d+\z/)
      end
    end

    it 'can check if interface is default gateway' do
      # This should work regardless of real or fallback data
      result = NetworkInterfaceHelper.is_default_gateway_interface?('eth0')
      expect(result).to be_in([true, false])

      result = NetworkInterfaceHelper.is_default_gateway_interface?('nonexistent_interface')
      expect(result).to be false
    end
  end
end
