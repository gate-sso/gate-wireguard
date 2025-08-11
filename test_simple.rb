#!/usr/bin/env ruby

require_relative 'config/environment'

puts "Rails environment loaded: #{Rails.env}"
puts "User model: #{User.first&.name || 'No users found'}"

# Test creating a user
user = User.create!(name: 'Test User', email: 'test@example.com', admin: true, provider: 'oauth', uid: '12345')
puts "Created user: #{user.name}"

# Test VPN Configuration
vpn_config = VpnConfiguration.get_vpn_configuration
puts "VPN Config ID: #{vpn_config.id}"

puts "Basic Rails functionality working!"
