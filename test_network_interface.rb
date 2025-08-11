#!/usr/bin/env ruby

require 'bundler/setup'
require_relative 'config/environment'

puts "=== Network Interface Detection Test ==="
puts

# Test 1: Default Gateway Interface
puts "1. Testing Default Gateway Detection..."
default_info = NetworkInterfaceHelper.get_default_gateway_interface

if default_info[:success]
  puts "   ✅ Default gateway interface: #{default_info[:interface_name]}"
  puts "   ✅ Interface IP address: #{default_info[:ip_address]}"
else
  puts "   ❌ Failed to detect default gateway: #{default_info[:error]}"
end

puts

# Test 2: All Interfaces
puts "2. Testing All Interfaces Detection..."
all_interfaces = NetworkInterfaceHelper.get_all_interfaces

if all_interfaces[:success]
  puts "   ✅ Found #{all_interfaces[:interfaces].length} interfaces:"
  all_interfaces[:interfaces].each do |iface|
    is_default = NetworkInterfaceHelper.is_default_gateway_interface?(iface[:name])
    marker = is_default ? " (DEFAULT GATEWAY)" : ""
    puts "      - #{iface[:name]}: #{iface[:ip]}#{marker}"
  end
else
  puts "   ❌ Failed to detect interfaces: #{all_interfaces[:error]}"
end

puts
puts "=== Test completed ==="
