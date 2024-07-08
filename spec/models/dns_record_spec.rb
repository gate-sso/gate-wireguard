# frozen_string_literal: true
require 'rails_helper'

RSpec.describe DnsRecord, type: :model do # rubocop:disable Metrics/BlockLength
  before(:each) do
    @redis = Redis.new(host: ENV['GATE_REDIS_HOST'], port: ENV['GATE_REDIS_PORT'])
    @dns_zone = ENV['GATE_DNS_ZONE']
    @dns_server = 'localhost'
    @dns_server_port = 1053
  end

  # write after each where we flush redis
  after(:each) do
    @redis.del("#{@dns_zone}.")
  end

  describe '.dns_record_exists?' do
    it 'returns true if the DNS record exists using a custom DNS server' do
      result = DnsRecordsHelper.resolve_dns_record('orbit.soracloud.dev', dns_server: @dns_server,
                                                                          dns_server_port: @dns_server_port)

      expect(result).to be_truthy
    end

    it 'should add the dns record to redis' do
      DnsRecord.add_host(@dns_zone, 'orbit', '10.8.1.1')
      DnsRecord.add_host(@dns_zone, 'orbit01', '10.8.2.2')
      result = DnsRecordsHelper.get_ip_addres("orbit.#{@dns_zone}", dns_server: @dns_server,
                                                                    dns_server_port: @dns_server_port)
      expect(result.to_s).to eq('10.8.1.1')

      result = DnsRecordsHelper.get_ip_addres("orbit01.#{@dns_zone}", dns_server: @dns_server,
                                                                      dns_server_port: @dns_server_port)
      expect(result.to_s).to eq('10.8.2.2')
    end
  end
end
