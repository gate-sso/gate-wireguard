# frozen_string_literal: true

REDIS = ConnectionPool::Wrapper.new do
  Redis.new(host: ENV.fetch('GATE_REDIS_HOST', nil), port: ENV.fetch('GATE_REDIS_PORT', nil))
end
