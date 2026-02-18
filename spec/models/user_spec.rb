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

    context 'when user email is not pre-authorized' do
      it 'returns nil' do
        expect(described_class.from_omniauth(auth)).to be_nil
      end

      it 'does not create a user' do
        expect { described_class.from_omniauth(auth) }.not_to change(described_class, :count)
      end
    end

    context 'when user email is pre-authorized' do
      let!(:pre_added_user) { described_class.create!(email: 'user@example.com', active: true) }

      it 'returns the pre-added user' do
        user = described_class.from_omniauth(auth)
        expect(user).to eq(pre_added_user)
      end

      it 'updates OAuth fields on the pre-added user' do
        user = described_class.from_omniauth(auth)
        expect(user.provider).to eq('google_oauth2')
        expect(user.uid).to eq('123456')
        expect(user.name).to eq('Test User')
        expect(user.profile_picture_url).to be_present
      end

      it 'does not create a new user' do
        expect { described_class.from_omniauth(auth) }.not_to change(described_class, :count)
      end
    end

    context 'when user already has OAuth credentials (returning user)' do
      let!(:existing_user) do
        described_class.create!(
          email: 'user@example.com', name: 'Test User',
          provider: 'google_oauth2', uid: '123456', active: true
        )
      end

      it 'returns the existing user' do
        expect(described_class.from_omniauth(auth)).to eq(existing_user)
      end

      it 'does not create a new user' do
        expect { described_class.from_omniauth(auth) }.not_to change(described_class, :count)
      end
    end

    context 'when ADMIN_USER_EMAIL matches' do
      before { allow(ENV).to receive(:[]).and_call_original }

      it 'auto-creates admin user even if not pre-added' do
        allow(ENV).to receive(:[]).with('ADMIN_USER_EMAIL').and_return('user@example.com')
        allow(ENV).to receive(:fetch).and_call_original

        expect { described_class.from_omniauth(auth) }.to change(described_class, :count).by(1)
        user = described_class.from_omniauth(auth)
        expect(user.admin?).to be true
        expect(user.active?).to be true
      end

      it 'returns existing user if admin email is already in system' do
        allow(ENV).to receive(:[]).with('ADMIN_USER_EMAIL').and_return('user@example.com')
        allow(ENV).to receive(:fetch).and_call_original

        existing = described_class.create!(email: 'user@example.com', active: true)
        user = described_class.from_omniauth(auth)
        expect(user).to eq(existing)
      end

      it 'does not auto-create for non-matching email' do
        allow(ENV).to receive(:[]).with('ADMIN_USER_EMAIL').and_return('other@example.com')
        allow(ENV).to receive(:fetch).and_call_original

        expect(described_class.from_omniauth(auth)).to be_nil
      end

      it 'does not auto-create when ADMIN_USER_EMAIL is blank' do
        allow(ENV).to receive(:[]).with('ADMIN_USER_EMAIL').and_return('')
        allow(ENV).to receive(:fetch).and_call_original

        expect(described_class.from_omniauth(auth)).to be_nil
      end
    end

    it 'updates profile picture for existing users' do
      described_class.create!(
        email: 'user@example.com', name: 'Test User',
        provider: 'google_oauth2', uid: '123456', active: true
      )

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
