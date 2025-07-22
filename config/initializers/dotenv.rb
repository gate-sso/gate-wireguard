# frozen_string_literal: true

Dotenv.require_keys(
  'GOOGLE_CLIENT_ID',
  'GOOGLE_CLIENT_SECRET',
  'GATE_REDIS_HOST',
  'GATE_REDIS_PORT',
  'GATE_DNS_ZONE'
)
