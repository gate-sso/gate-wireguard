#!/usr/bin/env ruby

require 'bundler/setup'
require_relative 'config/environment'

puts "Testing FQDN functionality..."

# Test 1: Check if VpnConfiguration model has wg_fqdn attribute
begin
  config = VpnConfiguration.new
  config.wg_fqdn = 'test.example.com'
  config.wg_ip_address = '1.2.3.4'
  puts "✅ VpnConfiguration supports wg_fqdn: #{config.wg_fqdn}"
  puts "✅ VpnConfiguration supports wg_ip_address: #{config.wg_ip_address}"
rescue => e
  puts "❌ VpnConfiguration error: #{e.message}"
end

# Test 2: Check if the JavaScript controller file exists
controller_path = Rails.root.join('app', 'javascript', 'controllers', 'fqdn_resolver_controller.js')
if File.exist?(controller_path)
  puts "✅ FQDN resolver controller file exists"
  content = File.read(controller_path)
  if content.include?('export default class extends Controller')
    puts "✅ Controller has correct structure"
  else
    puts "❌ Controller structure issue"
  end
else
  puts "❌ FQDN resolver controller file missing"
end

# Test 3: Check admin controller updates
admin_controller_path = Rails.root.join('app', 'controllers', 'admin_controller.rb')
if File.exist?(admin_controller_path)
  content = File.read(admin_controller_path)
  if content.include?('wg_fqdn')
    puts "✅ Admin controller supports wg_fqdn parameter"
  else
    puts "❌ Admin controller missing wg_fqdn support"
  end
end

puts "FQDN functionality test completed!"
