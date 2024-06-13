module DnsCache
  def self.redis
    @redis ||= ConnectionPool::Wrapper.new do
      Redis.new(host: ENV["GATE_REDIS_HOST"], port: ENV["GATE_REDIS_PORT"])
    end
  end
end