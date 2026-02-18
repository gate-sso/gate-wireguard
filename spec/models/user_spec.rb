# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User do
  describe '.from_omniauth' do
    let(:auth) do
      OmniAuth::AuthHash.new(
        provider: 'google_oauth2',
        uid: '123456',
        info: {
          email: 'user@example.com',
          name: 'Test User',
          image: 'https://lh3.googleusercontent.com/photo=s96-c'
        }
      )
    end

    it 'creates a new user from OAuth data' do
      expect { described_class.from_omniauth(auth) }.to change(described_class, :count).by(1)
    end

    it 'returns existing user on subsequent login' do
      described_class.from_omniauth(auth)
      expect { described_class.from_omniauth(auth) }.not_to change(described_class, :count)
    end

    it 'creates new users as inactive by default' do
      user = described_class.from_omniauth(auth)
      expect(user.active?).to be false
    end

    it 'creates new users as non-admin by default' do
      user = described_class.from_omniauth(auth)
      expect(user.admin?).to be false
    end

    context 'when ADMIN_USER_EMAIL matches' do
      before { allow(ENV).to receive(:[]).and_call_original }

      it 'sets admin and active for matching email' do
        allow(ENV).to receive(:[]).with('ADMIN_USER_EMAIL').and_return('user@example.com')
        allow(ENV).to receive(:fetch).and_call_original

        user = described_class.from_omniauth(auth)
        expect(user.admin?).to be true
        expect(user.active?).to be true
      end

      it 'does not set admin for non-matching email' do
        allow(ENV).to receive(:[]).with('ADMIN_USER_EMAIL').and_return('other@example.com')
        allow(ENV).to receive(:fetch).and_call_original

        user = described_class.from_omniauth(auth)
        expect(user.admin?).to be false
        expect(user.active?).to be false
      end

      it 'does not set admin when ADMIN_USER_EMAIL is blank' do
        allow(ENV).to receive(:[]).with('ADMIN_USER_EMAIL').and_return('')
        allow(ENV).to receive(:fetch).and_call_original

        user = described_class.from_omniauth(auth)
        expect(user.admin?).to be false
      end
    end

    it 'updates profile picture for existing users' do
      user = described_class.from_omniauth(auth)
      user.update!(active: true)

      new_auth = auth.dup
      new_auth.info.image = 'https://lh3.googleusercontent.com/newphoto=s96-c'

      returned_user = described_class.from_omniauth(new_auth)
      expect(returned_user.profile_picture_url).to include('newphoto')
    end
  end

  describe 'active attribute' do
    it 'defaults to false' do
      user = described_class.new
      expect(user.active?).to be false
    end

    it 'can be set to true' do
      user = described_class.create!(name: 'Test', email: 'test@example.com', provider: 'oauth', uid: '1', active: true)
      expect(user.active?).to be true
    end
  end
end
