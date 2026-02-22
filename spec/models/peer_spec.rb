# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Peer do
  def create_peer(overrides = {})
    Peer.create!({
      name: "test-peer-#{SecureRandom.hex(4)}",
      vpn_ip: "10.5.42.#{rand(3..254)}",
      public_key: SecureRandom.base64(32),
      private_key: SecureRandom.base64(32),
      dns: 'ns01.clawstation.ai'
    }.merge(overrides))
  end

  describe 'validations' do
    it 'requires name, vpn_ip, public_key, and private_key' do
      peer = Peer.new
      expect(peer).not_to be_valid
      expect(peer.errors[:name]).to include("can't be blank")
      expect(peer.errors[:vpn_ip]).to include("can't be blank")
      expect(peer.errors[:public_key]).to include("can't be blank")
      expect(peer.errors[:private_key]).to include("can't be blank")
    end

    it 'enforces uniqueness on name' do
      create_peer(name: 'unique-peer', vpn_ip: '10.5.42.100', public_key: 'key1')
      duplicate = Peer.new(name: 'unique-peer', vpn_ip: '10.5.42.101', public_key: 'key2', private_key: 'pk')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include('has already been taken')
    end

    it 'enforces uniqueness on vpn_ip' do
      create_peer(vpn_ip: '10.5.42.50', name: 'peer-a', public_key: 'ka')
      duplicate = Peer.new(name: 'peer-b', vpn_ip: '10.5.42.50', public_key: 'kb', private_key: 'pk')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:vpn_ip]).to include('has already been taken')
    end

    it 'enforces uniqueness on public_key' do
      create_peer(public_key: 'shared-key', name: 'peer-c', vpn_ip: '10.5.42.60')
      duplicate = Peer.new(name: 'peer-d', vpn_ip: '10.5.42.61', public_key: 'shared-key', private_key: 'pk')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:public_key]).to include('has already been taken')
    end
  end

  describe '#config' do
    it 'generates a WireGuard client config' do
      peer = create_peer(vpn_ip: '10.5.42.10', private_key: 'test-private-key', dns: 'ns01.clawstation.ai')
      config = peer.config

      expect(config).to include('PrivateKey = test-private-key')
      expect(config).to include('Address = 10.5.42.10/24')
      expect(config).to include('DNS = ns01.clawstation.ai')
      expect(config).to include('[Peer]')
      expect(config).to include('PersistentKeepalive = 25')
    end
  end

  describe 'scopes' do
    it '.active excludes removed peers' do
      active_peer = create_peer(name: 'active', vpn_ip: '10.5.42.30', public_key: 'ak')
      create_peer(name: 'removed', vpn_ip: '10.5.42.31', public_key: 'rk', removed_at: Time.current)

      expect(Peer.active).to contain_exactly(active_peer)
    end
  end

  describe '#remove!' do
    it 'sets removed_at' do
      peer = create_peer
      expect { peer.remove! }.to change(peer, :removed?).from(false).to(true)
    end
  end
end
