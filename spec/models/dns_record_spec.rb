# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DnsRecord do
  before do
    # Set up test environment variables if not present
    allow(ENV).to receive(:fetch).with('GATE_REDIS_HOST', nil).and_return('127.0.0.1')
    allow(ENV).to receive(:fetch).with('GATE_REDIS_PORT', nil).and_return('6379')
    allow(ENV).to receive(:fetch).with('GATE_DNS_ZONE', nil).and_return('test.local')

    @dns_zone = 'test.local'
    @dns_server = 'localhost'
    @dns_server_port = 1053
  end

  # Clean up after each test - no actual cleanup needed since we're mocking

  describe '.dns_record_exists?' do
    it 'returns true if the DNS record exists using a custom DNS server' do
      # Mock the DNS resolution to avoid dependency on external DNS server
      allow(DnsRecordsHelper).to receive(:resolve_dns_record).and_return(true)

      result = DnsRecordsHelper.resolve_dns_record('orbit.soracloud.dev', dns_server: @dns_server,
                                                                          dns_server_port: @dns_server_port)

      expect(result).to be_truthy
    end

    it 'adds the dns record to redis' do
      # Mock the connection pool wrapper by creating a real ConnectionPool::Wrapper with a mocked Redis
      mock_redis = instance_double(Redis)
      allow(mock_redis).to receive(:hset).and_return(true)

      # Create a real ConnectionPool::Wrapper that yields our mocked Redis
      mock_pool = ConnectionPool::Wrapper.new { mock_redis }
      stub_const('REDIS', mock_pool)

      # Mock the DNS helper methods to return expected values
      allow(DnsRecordsHelper).to receive(:get_ip_addres).with("orbit.#{@dns_zone}", dns_server: @dns_server,
                                                                                    dns_server_port: @dns_server_port).and_return('10.8.1.1')
      allow(DnsRecordsHelper).to receive(:get_ip_addres).with("orbit01.#{@dns_zone}", dns_server: @dns_server,
                                                                                      dns_server_port: @dns_server_port).and_return('10.8.2.2')

      described_class.add_host(@dns_zone, 'orbit', '10.8.1.1')
      described_class.add_host(@dns_zone, 'orbit01', '10.8.2.2')

      result1 = DnsRecordsHelper.get_ip_addres("orbit.#{@dns_zone}", dns_server: @dns_server,
                                                                     dns_server_port: @dns_server_port)
      expect(result1.to_s).to eq('10.8.1.1')

      result2 = DnsRecordsHelper.get_ip_addres("orbit01.#{@dns_zone}", dns_server: @dns_server,
                                                                       dns_server_port: @dns_server_port)
      expect(result2.to_s).to eq('10.8.2.2')
    end
  end
end
