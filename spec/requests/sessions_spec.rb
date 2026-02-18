# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sessions', type: :request do
  let(:auth_hash) do
    OmniAuth::AuthHash.new(
      provider: 'google_oauth2',
      uid: '123456',
      info: {
        email: 'user@example.com',
        name: 'Test User',
        image: 'https://example.com/photo.jpg'
      }
    )
  end

  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = auth_hash
  end

  describe 'GET /auth/google_oauth2/callback' do
    context 'when user is pre-authorized and active' do
      it 'logs in and redirects to root' do
        User.create!(email: 'user@example.com', active: true)

        get '/auth/google_oauth2/callback'
        expect(response).to redirect_to(root_path)
      end
    end

    context 'when user is pre-authorized but inactive' do
      it 'redirects to login with pending approval message' do
        User.create!(email: 'user@example.com', active: false)

        get '/auth/google_oauth2/callback'
        expect(response).to redirect_to(login_path)
        expect(flash[:alert]).to include('pending approval')
      end
    end

    context 'when user email is not in the system' do
      it 'redirects to login' do
        get '/auth/google_oauth2/callback'
        expect(response).to redirect_to(login_path)
      end

      it 'sets an unauthorized flash message' do
        get '/auth/google_oauth2/callback'
        expect(flash[:alert]).to include('not been authorized')
      end

      it 'does not create a user record' do
        expect { get '/auth/google_oauth2/callback' }.not_to change(User, :count)
      end
    end

    context 'when user is new and matches ADMIN_USER_EMAIL' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('ADMIN_USER_EMAIL').and_return('user@example.com')
        allow(ENV).to receive(:fetch).and_call_original
      end

      it 'auto-activates and logs in' do
        get '/auth/google_oauth2/callback'
        expect(response).to redirect_to(root_path)

        user = User.find_by(email: 'user@example.com')
        expect(user.admin?).to be true
        expect(user.active?).to be true
      end
    end
  end

  describe 'DELETE /logout' do
    it 'clears session and redirects to root' do
      get '/logout'
      expect(response).to redirect_to(root_path)
    end
  end
end
