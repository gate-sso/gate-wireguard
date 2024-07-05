# This class helps with Redis configuration for CoreDNS
class CoreDNSRedisAdapter
  class << self
    redis = Redis.new(host: ENV['GATE_REDIS_HOST'], port: ENV['GATE_REDIS_PORT'])
    redis.sadd(ENV['GATE_REDIS_ZONE'], host)

    def update_host(dns_zone, host, ip_address); end
  end
end
