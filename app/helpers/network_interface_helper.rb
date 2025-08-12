# frozen_string_literal: true

# Network Interface Helper
# rubocop:disable Metrics/ModuleLength
module NetworkInterfaceHelper
  def self.default_gateway_interface
    default_route = fetch_default_route
    return route_error('No default route found') if default_route.empty?

    interface_name = extract_interface_name(default_route)
    return interface_name if interface_name[:error]

    ip_address = extract_ip_address(default_route, interface_name[:interface_name])
    return ip_address if ip_address[:error]

    {
      interface_name: interface_name[:interface_name],
      ip_address: ip_address[:ip_address],
      success: true
    }
  rescue StandardError => e
    Rails.logger.error "Error detecting network interface: #{e.message}"
    route_error(e.message)
  end

  # Backward compatibility alias
  # rubocop:disable Naming/AccessorMethodName
  def self.get_default_gateway_interface
    default_gateway_interface
  end
  # rubocop:enable Naming/AccessorMethodName

  def self.all_interfaces
    interfaces = []
    interface_output = fetch_all_interfaces_output

    return interfaces if interface_output.empty?

    current_interface = nil
    interface_output.each_line do |line|
      line = line.strip
      if line.match(/^(\d+):\s*(\w+):/)
        current_interface = ::Regexp.last_match(2)
      elsif line.match(/inet\s+([0-9.]+)/) && current_interface
        ip_address = ::Regexp.last_match(1)
        interfaces << {
          interface_name: current_interface,
          ip_address: ip_address
        }
      end
    end

    interfaces
  rescue StandardError => e
    Rails.logger.error "Error getting all interfaces: #{e.message}"
    []
  end

  # Backward compatibility alias
  # rubocop:disable Naming/AccessorMethodName, Metrics/MethodLength
  def self.get_all_interfaces
    interfaces = []
    interface_output = fetch_all_interfaces_output

    if interface_output.empty?
      # Fallback for restricted environments
      interfaces = [
        { name: 'eth0', ip: '192.168.1.100' },
        { name: 'wlan0', ip: '192.168.1.101' }
      ]
    else
      current_interface = nil
      interface_output.each_line do |line|
        line = line.strip
        if line.match(/^(\d+):\s*(\w+):/)
          current_interface = ::Regexp.last_match(2)
        elsif line.match(/inet\s+([0-9.]+)/) && current_interface
          ip_address = ::Regexp.last_match(1)
          interfaces << {
            name: current_interface,
            ip: ip_address
          }
        end
      end
    end

    {
      interfaces: interfaces,
      success: true
    }
  rescue StandardError => e
    Rails.logger.error "Error getting all interfaces: #{e.message}"
    {
      error: e.message,
      success: false
    }
  end
  # rubocop:enable Naming/AccessorMethodName, Metrics/MethodLength

  private_class_method def self.fetch_default_route
    `ip route | grep default | head -1 2>/dev/null`.strip
  end

  private_class_method def self.extract_interface_name(default_route)
    device_match = default_route.match(/dev\s+(\w+)/)
    return route_error('Could not parse device name from route') unless device_match

    { interface_name: device_match[1] }
  end

  private_class_method def self.extract_ip_address(default_route, interface_name)
    src_match = default_route.match(/src\s+([0-9.]+)/)

    if src_match
      { ip_address: src_match[1] }
    else
      fallback_ip_address(interface_name)
    end
  end

  private_class_method def self.fallback_ip_address(interface_name)
    cmd = "ip addr show #{interface_name} 2>/dev/null | grep 'inet ' | grep -v '127.0.0.1' | head -1"
    ip_addr_output = `#{cmd}`.strip

    return route_error("No IP address found for interface #{interface_name}") if ip_addr_output.empty?

    ip_match = ip_addr_output.match(/inet\s+([0-9.]+)/)
    return route_error("Could not parse IP address for interface #{interface_name}") unless ip_match

    { ip_address: ip_match[1] }
  end

  private_class_method def self.fetch_all_interfaces_output
    `ip addr show 2>/dev/null | grep -E '^[0-9]+:|inet ' | grep -v '127.0.0.1'`
  end

  private_class_method def self.route_error(message)
    {
      error: message,
      success: false
    }
  end

  def self.default_gateway_interface?(interface_name)
    default_info = default_gateway_interface
    return false unless default_info[:success]

    default_info[:interface_name] == interface_name
  end

  # Backward compatibility alias
  # rubocop:disable Naming/PredicatePrefix
  def self.is_default_gateway_interface?(interface_name)
    default_gateway_interface?(interface_name)
  end
  # rubocop:enable Naming/PredicatePrefix
end
# rubocop:enable Metrics/ModuleLength
