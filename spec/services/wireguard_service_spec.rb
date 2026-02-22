# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WireguardService do
  def create_peer(overrides = {})
    Peer.create!({
      name: "test-peer-#{SecureRandom.hex(4)}",
      vpn_ip: "10.5.42.#{rand(3..254)}",
      public_key: SecureRandom.base64(32),
      private_key: SecureRandom.base64(32),
      dns: 'ns01.clawstation.ai'
    }.merge(overrides))
  end

  let(:fake_private_key) { 'YWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXoxMjM0NQ==' }
  let(:fake_public_key) { 'cHVia2V5YWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eQ==' }
  let(:success_status) { instance_double(Process::Status, success?: true, exitstatus: 0) }
  let(:failure_status) { instance_double(Process::Status, success?: false, exitstatus: 1) }

  describe '.generate_keypair' do
    it 'returns a hash with private and public keys' do
      allow(Open3).to receive(:capture2).with('wg', 'genkey').and_return(["#{fake_private_key}\n", success_status])
      allow(Open3).to receive(:capture2).with('wg', 'pubkey', stdin_data: fake_private_key).and_return(["#{fake_public_key}\n", success_status])

      keypair = described_class.generate_keypair

      expect(keypair[:private_key]).to eq(fake_private_key)
      expect(keypair[:public_key]).to eq(fake_public_key)
    end

    it 'raises WireguardError if wg genkey fails' do
      allow(Open3).to receive(:capture2).with('wg', 'genkey').and_return(['', failure_status])

      expect { described_class.generate_keypair }.to raise_error(
        WireguardService::WireguardError, 'Failed to generate private key'
      )
    end

    it 'raises WireguardError if wg pubkey fails' do
      allow(Open3).to receive(:capture2).with('wg', 'genkey').and_return(["#{fake_private_key}\n", success_status])
      allow(Open3).to receive(:capture2).with('wg', 'pubkey', stdin_data: fake_private_key).and_return(['', failure_status])

      expect { described_class.generate_keypair }.to raise_error(
        WireguardService::WireguardError, 'Failed to derive public key'
      )
    end
  end

  describe '.allocate_ip!' do
    it 'allocates the first available IP (10.5.42.3)' do
      ip = described_class.allocate_ip!
      expect(ip).to eq('10.5.42.3')
    end

    it 'skips reserved IPs (.1 and .2)' do
      ip = described_class.allocate_ip!
      octet = ip.split('.').last.to_i
      expect(octet).to be >= 3
    end

    it 'skips IPs already in use by active peers' do
      create_peer(vpn_ip: '10.5.42.3')
      create_peer(vpn_ip: '10.5.42.4')

      ip = described_class.allocate_ip!
      expect(ip).to eq('10.5.42.5')
    end

    it 'does not skip IPs used by removed peers' do
      create_peer(vpn_ip: '10.5.42.3', removed_at: Time.current)

      ip = described_class.allocate_ip!
      expect(ip).to eq('10.5.42.3')
    end

    it 'raises WireguardError when all IPs are exhausted' do
      (3..254).each do |n|
        create_peer(
          vpn_ip: "10.5.42.#{n}",
          name: "peer-#{n}",
          public_key: "key-#{n}"
        )
      end

      expect { described_class.allocate_ip! }.to raise_error(
        WireguardService::WireguardError, /No available VPN IPs/
      )
    end
  end

  describe '.create_peer!' do
    before do
      allow(described_class).to receive(:generate_keypair).and_return(
        { private_key: fake_private_key, public_key: fake_public_key }
      )
      allow(Open3).to receive(:capture2e).and_return(['', success_status])
    end

    it 'creates a peer with generated keys and allocated IP' do
      peer = described_class.create_peer!(name: 'test-node')

      expect(peer).to be_persisted
      expect(peer.name).to eq('test-node')
      expect(peer.vpn_ip).to eq('10.5.42.3')
      expect(peer.public_key).to eq(fake_public_key)
      expect(peer.private_key).to eq(fake_private_key)
    end

    it 'sets custom DNS when provided' do
      peer = described_class.create_peer!(name: 'dns-node', dns: 'ns01.clawstation.ai')
      expect(peer.dns).to eq('ns01.clawstation.ai')
    end

    it 'calls wg set to add the peer' do
      described_class.create_peer!(name: 'wg-node')

      expect(Open3).to have_received(:capture2e).with(
        'wg', 'set', 'wg0', 'peer', fake_public_key, 'allowed-ips', '10.5.42.3/32'
      )
    end

    it 'persists the WireGuard config' do
      described_class.create_peer!(name: 'persist-node')

      expect(Open3).to have_received(:capture2e).with(
        'bash', '-c', /wg-quick strip wg0/
      )
    end

    it 'raises WireguardError for duplicate name' do
      described_class.create_peer!(name: 'dup-node')

      allow(described_class).to receive(:generate_keypair).and_return(
        { private_key: SecureRandom.base64(32), public_key: SecureRandom.base64(32) }
      )

      expect { described_class.create_peer!(name: 'dup-node') }.to raise_error(
        WireguardService::WireguardError, /Failed to create peer/
      )
    end

    it 'raises WireguardError when wg set fails' do
      allow(Open3).to receive(:capture2e).with('wg', 'set', anything, anything, anything, anything, anything).and_return(['error', failure_status])

      expect { described_class.create_peer!(name: 'fail-node') }.to raise_error(
        WireguardService::WireguardError, /Failed to add peer/
      )
    end
  end

  describe '.remove_peer!' do
    let(:peer) { create_peer }

    before do
      allow(Open3).to receive(:capture2e).and_return(['', success_status])
    end

    it 'soft-deletes the peer' do
      described_class.remove_peer!(peer)

      expect(peer.reload).to be_removed
    end

    it 'calls wg set to remove the peer' do
      described_class.remove_peer!(peer)

      expect(Open3).to have_received(:capture2e).with(
        'wg', 'set', 'wg0', 'peer', peer.public_key, 'remove'
      )
    end

    it 'persists the config after removal' do
      described_class.remove_peer!(peer)

      expect(Open3).to have_received(:capture2e).with(
        'bash', '-c', /wg-quick strip wg0/
      )
    end

    it 'raises WireguardError when wg set remove fails' do
      allow(Open3).to receive(:capture2e).with('wg', 'set', anything, anything, anything, anything).and_return(['error', failure_status])

      expect { described_class.remove_peer!(peer) }.to raise_error(
        WireguardService::WireguardError, /Failed to remove peer/
      )
    end
  end
end
