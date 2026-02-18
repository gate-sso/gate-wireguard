# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin User Management', type: :request do
  let!(:admin_user) do
    User.create!(name: 'Admin', email: 'admin@example.com', admin: true, active: true, provider: 'oauth', uid: '1')
  end

  let!(:regular_user) do
    User.create!(name: 'Regular', email: 'regular@example.com', admin: false, active: true, provider: 'oauth', uid: '2')
  end

  let!(:inactive_user) do
    User.create!(name: 'Inactive', email: 'inactive@example.com', admin: false, active: false, provider: 'oauth',
                 uid: '3')
  end

  before do
    allow_any_instance_of(ActionController::Base).to receive(:session).and_return({ user_id: admin_user.id })
  end

  describe 'PATCH /admin/users/:id/toggle_admin' do
    it 'grants admin to a regular user' do
      patch toggle_admin_path(regular_user)
      expect(regular_user.reload.admin?).to be true
      expect(response).to redirect_to(admin_users_path)
    end

    it 'revokes admin from an admin user' do
      regular_user.update!(admin: true)
      patch toggle_admin_path(regular_user)
      expect(regular_user.reload.admin?).to be false
    end

    it 'prevents toggling own admin status' do
      patch toggle_admin_path(admin_user)
      expect(admin_user.reload.admin?).to be true
      expect(flash[:alert]).to include('own admin status')
    end

    context 'when user is not admin' do
      before do
        allow_any_instance_of(ActionController::Base).to receive(:session).and_return({ user_id: regular_user.id })
      end

      it 'redirects to root' do
        patch toggle_admin_path(inactive_user)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'PATCH /admin/users/:id/toggle_active' do
    it 'activates an inactive user' do
      patch toggle_active_path(inactive_user)
      expect(inactive_user.reload.active?).to be true
      expect(response).to redirect_to(admin_users_path)
    end

    it 'deactivates an active user' do
      patch toggle_active_path(regular_user)
      expect(regular_user.reload.active?).to be false
    end

    it 'prevents deactivating own account' do
      patch toggle_active_path(admin_user)
      expect(admin_user.reload.active?).to be true
      expect(flash[:alert]).to include('own account')
    end

    context 'when user is not admin' do
      before do
        allow_any_instance_of(ActionController::Base).to receive(:session).and_return({ user_id: regular_user.id })
      end

      it 'redirects to root' do
        patch toggle_active_path(inactive_user)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
