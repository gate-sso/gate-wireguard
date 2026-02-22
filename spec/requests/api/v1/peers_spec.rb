# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Peers' do
  let(:api_key) { ApiKey.generate(name: 'Test Key') }
  let(:auth_headers) { { 'Authorization' => "Bearer #{api_key.raw_token}" } }

  let(:fake_private_key) { SecureRandom.base64(32) }
  let(:fake_public_key) { SecureRandom.base64(32) }
  let(:success_status) { instance_double(Process::Status, success?: true, exitstatus: 0) }

  def create_peer(overrides = {})
    Peer.create!({
      name: "peer-#{SecureRandom.hex(4)}",
      vpn_ip: "10.5.42.#{rand(3..254)}",
      public_key: SecureRandom.base64(32),
      private_key: SecureRandom.base64(32),
      dns: 'ns01.clawstation.ai'
    }.merge(overrides))
  end

  describe 'authentication' do
    it 'returns 401 without an API key' do
      get '/api/v1/peers'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 401 with an invalid API key' do
      get '/api/v1/peers', headers: { 'Authorization' => 'Bearer gw_bogus' }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 401 with a revoked API key' do
      api_key.revoke!
      get '/api/v1/peers', headers: auth_headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'succeeds with a valid API key' do
      get '/api/v1/peers', headers: auth_headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /api/v1/peers' do
    it 'returns active peers as JSON' do
      peer = create_peer(name: 'active-peer', vpn_ip: '10.5.42.10')
      create_peer(name: 'removed-peer', vpn_ip: '10.5.42.11', removed_at: Time.current)

      get '/api/v1/peers', headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json.length).to eq(1)
      expect(json.first['name']).to eq('active-peer')
      expect(json.first['vpn_ip']).to eq('10.5.42.10')
      expect(json.first['id']).to eq(peer.id)
    end

    it 'returns an empty array when no peers exist' do
      get '/api/v1/peers', headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq([])
    end

    it 'includes config in the response' do
      create_peer(name: 'config-peer', vpn_ip: '10.5.42.20')

      get '/api/v1/peers', headers: auth_headers

      json = response.parsed_body
      expect(json.first['config']).to include('PrivateKey')
      expect(json.first['config']).to include('[Interface]')
    end
  end

  describe 'GET /api/v1/peers/:id' do
    it 'returns a single peer' do
      peer = create_peer(name: 'show-peer', vpn_ip: '10.5.42.30')

      get "/api/v1/peers/#{peer.id}", headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['name']).to eq('show-peer')
      expect(json['vpn_ip']).to eq('10.5.42.30')
      expect(json['public_key']).to eq(peer.public_key)
    end

    it 'returns 404 for non-existent peer' do
      get '/api/v1/peers/99999', headers: auth_headers

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body['error']).to eq('Peer not found')
    end

    it 'returns 404 for removed peer' do
      peer = create_peer(removed_at: Time.current)

      get "/api/v1/peers/#{peer.id}", headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/peers' do
    before do
      allow(WireguardService).to receive(:create_peer!).and_call_original
      allow(WireguardService).to receive(:generate_keypair).and_return(
        { private_key: fake_private_key, public_key: fake_public_key }
      )
      allow(Open3).to receive(:capture2e).and_return(['', success_status])
    end

    it 'creates a new peer' do
      post '/api/v1/peers', params: { peer: { name: 'new-node' } }, headers: auth_headers

      expect(response).to have_http_status(:created)
      json = response.parsed_body
      expect(json['name']).to eq('new-node')
      expect(json['vpn_ip']).to start_with('10.5.42.')
      expect(json['public_key']).to eq(fake_public_key)
      expect(json['config']).to include('PrivateKey')
      expect(json['id']).to be_present
    end

    it 'accepts custom DNS' do
      post '/api/v1/peers', params: { peer: { name: 'dns-node', dns: 'ns01.clawstation.ai' } }, headers: auth_headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body['config']).to include('DNS = ns01.clawstation.ai')
    end

    it 'returns 422 for duplicate name' do
      create_peer(name: 'existing-node', vpn_ip: '10.5.42.50')

      # Need a fresh keypair to avoid public_key uniqueness violation
      allow(WireguardService).to receive(:generate_keypair).and_return(
        { private_key: SecureRandom.base64(32), public_key: SecureRandom.base64(32) }
      )

      post '/api/v1/peers', params: { peer: { name: 'existing-node' } }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body['error']).to be_present
    end

    it 'returns 422 when WireguardService raises' do
      allow(WireguardService).to receive(:create_peer!).and_raise(
        WireguardService::WireguardError, 'wg command failed'
      )

      post '/api/v1/peers', params: { peer: { name: 'fail-node' } }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body['error']).to eq('wg command failed')
    end
  end

  describe 'DELETE /api/v1/peers/:id' do
    before do
      allow(Open3).to receive(:capture2e).and_return(['', success_status])
    end

    it 'removes a peer' do
      peer = create_peer(name: 'delete-me', vpn_ip: '10.5.42.60')

      delete "/api/v1/peers/#{peer.id}", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(peer.reload).to be_removed
    end

    it 'returns 404 for non-existent peer' do
      delete '/api/v1/peers/99999', headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 for already removed peer' do
      peer = create_peer(removed_at: Time.current)

      delete "/api/v1/peers/#{peer.id}", headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 422 when WireguardService raises' do
      peer = create_peer(name: 'wg-fail', vpn_ip: '10.5.42.70')

      allow(WireguardService).to receive(:remove_peer!).and_raise(
        WireguardService::WireguardError, 'wg set failed'
      )

      delete "/api/v1/peers/#{peer.id}", headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body['error']).to eq('wg set failed')
    end
  end
end
