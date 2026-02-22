# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiKey do
  describe '.generate' do
    it 'creates a key with gw_ prefix and stores digest' do
      key = described_class.generate(name: 'Test Key')

      expect(key).to be_persisted
      expect(key.raw_token).to start_with('gw_')
      expect(key.token_digest).to eq(Digest::SHA256.hexdigest(key.raw_token))
      expect(key.name).to eq('Test Key')
    end
  end

  describe '.authenticate' do
    it 'finds active key by token' do
      key = described_class.generate(name: 'Auth Test')
      found = described_class.authenticate(key.raw_token)

      expect(found).to eq(key)
    end

    it 'returns nil for invalid token' do
      expect(described_class.authenticate('gw_bogus')).to be_nil
    end

    it 'returns nil for revoked key' do
      key = described_class.generate(name: 'Revoked')
      key.revoke!

      expect(described_class.authenticate(key.raw_token)).to be_nil
    end

    it 'returns nil for blank token' do
      expect(described_class.authenticate('')).to be_nil
      expect(described_class.authenticate(nil)).to be_nil
    end

    it 'updates last_used_at' do
      key = described_class.generate(name: 'Usage Track')
      expect(key.last_used_at).to be_nil

      described_class.authenticate(key.raw_token)
      key.reload
      expect(key.last_used_at).to be_present
    end
  end

  describe '#revoke!' do
    it 'sets revoked_at' do
      key = described_class.generate(name: 'To Revoke')
      expect { key.revoke! }.to change(key, :revoked?).from(false).to(true)
    end
  end

  describe 'validations' do
    it 'requires name and token_digest' do
      key = described_class.new
      expect(key).not_to be_valid
      expect(key.errors[:name]).to include("can't be blank")
      expect(key.errors[:token_digest]).to include("can't be blank")
    end
  end
end
