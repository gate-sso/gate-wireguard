# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin Backup System', type: :request do
  let!(:admin_user) { User.create!(name: 'Admin User', email: 'admin@example.com', admin: true) }

  describe 'GET /admin/backups' do
    context 'when user is admin' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin_user)
        allow_any_instance_of(ApplicationController).to receive(:logged_in?).and_return(true)
      end

      it 'shows the backup dashboard' do
        get '/admin/backups'
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET /admin/backups/download' do
    context 'when user is admin' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin_user)
        allow_any_instance_of(ApplicationController).to receive(:logged_in?).and_return(true)
      end

      it 'downloads backup as JSON file' do
        get '/admin/backups/download'
        expect(response).to have_http_status(:success)
        expect(response.headers['Content-Type']).to include('application/json')
      end
    end
  end
end
