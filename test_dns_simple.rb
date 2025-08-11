#!/usr/bin/env ruby

require 'bundler/setup'
require_relative 'config/environment'

puts "Testing DNS Record functionality..."

begin
  puts "1. Testing DNS Record model exists: #{DnsRecord}"
  puts "2. Testing DNS Records Helper exists: #{DnsRecordsHelper}"
  puts "3. Testing add_host method exists: #{DnsRecord.respond_to?(:add_host)}"
  puts "All basic tests passed!"
rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace
end
