# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DnsRecord do
  describe '.time_to_live' do
    it 'returns 300 seconds' do
      expect(described_class.time_to_live).to eq(300)
    end
  end

  describe '.add_host' do
    let(:mock_redis) { instance_double(Redis) }

    before do
      mock_pool = ConnectionPool::Wrapper.new { mock_redis }
      stub_const('REDIS', mock_pool)
      allow(mock_redis).to receive(:hset)
    end

    it 'writes the correct JSON record to Redis' do
      described_class.add_host('test.local', 'myhost', '10.8.1.1')

      expected_json = { a: [{ ip: '10.8.1.1', ttl: 300 }] }.to_json
      expect(mock_redis).to have_received(:hset).with('test.local.', 'myhost', expected_json)
    end

    it 'appends a dot to zone if missing' do
      described_class.add_host('test.local', 'web', '10.0.0.1')

      expect(mock_redis).to have_received(:hset).with('test.local.', 'web', anything)
    end

    it 'does not double-dot if zone already ends with dot' do
      described_class.add_host('test.local.', 'web', '10.0.0.1')

      expect(mock_redis).to have_received(:hset).with('test.local.', 'web', anything)
    end
  end

  describe '.add_host_to_zone' do
    let(:mock_redis) { instance_double(Redis) }
    let(:user) { User.create!(email: 'test@example.com', name: 'Test', active: true) }
    let(:record) { described_class.new(host_name: 'myhost', ip_address: '10.0.0.5', user: user) }

    before do
      mock_pool = ConnectionPool::Wrapper.new { mock_redis }
      stub_const('REDIS', mock_pool)
      allow(mock_redis).to receive(:hset)
      allow(ENV).to receive(:fetch).with('GATE_DNS_ZONE', nil).and_return('example.zone')
    end

    it 'calls add_host with the correct zone, hostname, and IP' do
      described_class.add_host_to_zone(record)

      expected_json = { a: [{ ip: '10.0.0.5', ttl: 300 }] }.to_json
      expect(mock_redis).to have_received(:hset).with('example.zone.', 'myhost', expected_json)
    end
  end

  describe '.refresh_zones' do
    let(:mock_redis) { instance_double(Redis) }
    let(:user) { User.create!(email: 'test@example.com', name: 'Test', active: true) }

    before do
      mock_pool = ConnectionPool::Wrapper.new { mock_redis }
      stub_const('REDIS', mock_pool)
      allow(mock_redis).to receive(:hset)
      allow(mock_redis).to receive(:del)
      allow(ENV).to receive(:fetch).with('GATE_DNS_ZONE', nil).and_return('example.zone')
    end

    it 'clears the zone and re-adds all records' do
      described_class.create!(host_name: 'host1', ip_address: '10.0.0.1', user: user)
      described_class.create!(host_name: 'host2', ip_address: '10.0.0.2', user: user)

      described_class.refresh_zones

      expect(mock_redis).to have_received(:del).with('example.zone.')
      expect(mock_redis).to have_received(:hset).with('example.zone.', 'host1', anything)
      expect(mock_redis).to have_received(:hset).with('example.zone.', 'host2', anything)
    end
  end
end
