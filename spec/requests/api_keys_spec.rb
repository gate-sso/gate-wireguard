# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ApiKeys' do
  let(:admin_user) do
    User.create!(
      email: 'admin@example.com',
      name: 'Admin User',
      provider: 'google_oauth2',
      uid: '12345',
      admin: true,
      active: true
    )
  end

  let(:regular_user) do
    User.create!(
      email: 'user@example.com',
      name: 'Regular User',
      provider: 'google_oauth2',
      uid: '67890',
      admin: false,
      active: true
    )
  end

  def sign_in(user)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: user.provider,
      uid: user.uid,
      info: { email: user.email, name: user.name, image: nil }
    )
    get '/auth/google_oauth2/callback'
  end

  describe 'access control' do
    it 'redirects unauthenticated users to login' do
      get '/api_keys'
      expect(response).to redirect_to(login_path)
    end

    it 'redirects non-admin users to root' do
      sign_in(regular_user)
      get '/api_keys'
      expect(response).to redirect_to(root_path)
    end

    it 'allows admin users' do
      sign_in(admin_user)
      get '/api_keys'
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /api_keys' do
    it 'lists all API keys for admins' do
      sign_in(admin_user)
      ApiKey.generate(name: 'Key One')
      ApiKey.generate(name: 'Key Two')

      get '/api_keys'

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Key One')
      expect(response.body).to include('Key Two')
    end
  end

  describe 'GET /api_keys/new' do
    it 'renders the new key form for admins' do
      sign_in(admin_user)
      get '/api_keys/new'

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /api_keys' do
    it 'creates a new API key and redirects' do
      sign_in(admin_user)

      expect {
        post '/api_keys', params: { api_key: { name: 'My New Key' } }
      }.to change(ApiKey, :count).by(1)

      expect(response).to redirect_to(api_keys_path)
      follow_redirect!
      expect(response.body).to include('My New Key')
    end

    it 'sets the raw_token flash for one-time display' do
      sign_in(admin_user)
      post '/api_keys', params: { api_key: { name: 'Flash Key' } }

      expect(flash[:raw_token]).to start_with('gw_')
    end

    it 'uses default name when none provided' do
      sign_in(admin_user)
      post '/api_keys', params: { api_key: { name: '' } }

      # The controller falls back to 'Unnamed key' when name param is blank
      expect(response).to redirect_to(api_keys_path)
    end
  end

  describe 'DELETE /api_keys/:id' do
    it 'revokes the API key' do
      sign_in(admin_user)
      key = ApiKey.generate(name: 'To Revoke')

      delete "/api_keys/#{key.id}"

      expect(response).to redirect_to(api_keys_path)
      expect(key.reload).to be_revoked
    end
  end
end
