# frozen_string_literal: true

# DNS Record helper
module DnsRecordsHelper
  def self.resolve_dns_record(domain, dns_server: nil, dns_server_port: 53)
    dns_resolver = dns_server ? Resolv::DNS.new(nameserver_port: [[dns_server, dns_server_port]]) : Resolv::DNS.new
    result = false
    begin
      dns_resolver.timeouts = 2
      result = dns_resolver.getresources(domain, Resolv::DNS::Resource::IN::A).any? ||
               dns_resolver.getresources(domain, Resolv::DNS::Resource::IN::AAAA).any?
    rescue Resolv::ResolvError, Resolv::ResolvTimeout
      result = false
    ensure
      dns_resolver.close
    end
    result
  end

  def self.get_ip_addres(domain, dns_server: nil, dns_server_port: 53)
    dns_resolver = dns_server ? Resolv::DNS.new(nameserver_port: [[dns_server, dns_server_port]]) : Resolv::DNS.new
    result = nil
    begin
      dns_resolver.timeouts = 2
      result = dns_resolver.getaddress(domain)
    rescue Resolv::ResolvError, Resolv::ResolvTimeout
      result = nil
    ensure
      dns_resolver.close
    end
    result
  end
end
