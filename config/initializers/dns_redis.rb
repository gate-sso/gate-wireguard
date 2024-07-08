pool_size = 20
REDIS =  ConnectionPool::Wrapper.new do
  Redis.new(host: ENV["GATE_REDIS_HOST"], port: ENV["GATE_REDIS_PORT"])
end
