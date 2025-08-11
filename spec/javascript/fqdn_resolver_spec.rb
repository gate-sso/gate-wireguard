require 'rails_helper'

RSpec.describe 'FQDN Resolver JavaScript Controller' do
  describe 'Controller file exists' do
    it 'has the fqdn_resolver_controller.js file' do
      controller_path = Rails.root.join('app', 'javascript', 'controllers', 'fqdn_resolver_controller.js')
      expect(File.exist?(controller_path)).to be true
    end

    it 'contains the expected controller class and methods' do
      controller_path = Rails.root.join('app', 'javascript', 'controllers', 'fqdn_resolver_controller.js')
      content = File.read(controller_path)
      
      expect(content).to include('export default class extends Controller')
      expect(content).to include('static targets = ["fqdn", "publicIp"]')
      expect(content).to include('resolveFqdn')
      expect(content).to include('performDnsResolution')
      expect(content).to include('lookupDns')
      expect(content).to include('isValidFqdn')
    end

    it 'includes DNS over HTTPS functionality' do
      controller_path = Rails.root.join('app', 'javascript', 'controllers', 'fqdn_resolver_controller.js')
      content = File.read(controller_path)
      
      expect(content).to include('cloudflare-dns.com/dns-query')
      expect(content).to include('application/dns-json')
    end

    it 'includes proper error handling and validation' do
      controller_path = Rails.root.join('app', 'javascript', 'controllers', 'fqdn_resolver_controller.js')
      content = File.read(controller_path)
      
      expect(content).to include('showError')
      expect(content).to include('showSuccess')
      expect(content).to include('showLoading')
      expect(content).to include('clearMessages')
    end
  end

  describe 'VPN Configuration FQDN support' do
    it 'allows setting and getting wg_fqdn attribute' do
      config = VpnConfiguration.new
      config.wg_fqdn = 'test.example.com'
      
      expect(config.wg_fqdn).to eq('test.example.com')
    end

    it 'allows setting and getting wg_ip_address attribute' do
      config = VpnConfiguration.new
      config.wg_ip_address = '192.168.1.1'
      
      expect(config.wg_ip_address).to eq('192.168.1.1')
    end

    it 'supports both FQDN and IP address together' do
      config = VpnConfiguration.new
      config.wg_fqdn = 'vpn.company.com'
      config.wg_ip_address = '203.0.113.10'
      
      expect(config.wg_fqdn).to eq('vpn.company.com')
      expect(config.wg_ip_address).to eq('203.0.113.10')
    end
  end

  describe 'Form Integration' do
    it 'verifies admin view template includes FQDN resolver controller' do
      template_path = Rails.root.join('app', 'views', 'admin', 'vpn_configurations.html.erb')
      content = File.read(template_path)
      
      expect(content).to include('controller: "fqdn-resolver"')
      expect(content).to include('fqdn_resolver_target: "fqdn"')
      expect(content).to include('fqdn_resolver_target: "publicIp"')
      expect(content).to include('input->fqdn-resolver#resolveFqdn')
    end

    it 'includes helpful user guidance text' do
      template_path = Rails.root.join('app', 'views', 'admin', 'vpn_configurations.html.erb')
      content = File.read(template_path)
      
      expect(content).to include('Enter a domain name to automatically resolve its IP address')
    end
  end
end
