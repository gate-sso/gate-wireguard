require 'rails_helper'

RSpec.describe DnsRecord, type: :model do
  before(:each) do
    @redis = Redis.new(host: ENV['GATE_REDIS_HOST'], port: ENV['GATE_REDIS_PORT'])
    @dns_zone = ENV['GATE_REDIS_ZONE']
    @dns_server = 'localhost'
    @dns_server_port = 1053
  end

  describe '.dns_record_exists?' do
    it 'returns true if the DNS record exists using a custom DNS server' do
      result = DnsRecordsHelper.resolve_dns_record('orbit.soracloud.net', dns_server: @dns_server,
                                                                          dns_server_port: @dns_server_port)

      expect(result).to be_truthy
    end
  end
end
