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

  describe 'POST /admin/users (add_user)' do
    it 'creates a pre-authorized user' do
      expect do
        post add_user_path, params: { email: 'newuser@example.com' }
      end.to change(User, :count).by(1)

      user = User.find_by(email: 'newuser@example.com')
      expect(user.active?).to be true
      expect(user.provider).to be_nil
      expect(response).to redirect_to(admin_users_path)
    end

    it 'normalizes email to lowercase' do
      post add_user_path, params: { email: 'NewUser@Example.COM' }
      expect(User.find_by(email: 'newuser@example.com')).to be_present
    end

    it 'rejects blank email' do
      expect do
        post add_user_path, params: { email: '' }
      end.not_to change(User, :count)
      expect(flash[:alert]).to include('required')
    end

    it 'rejects duplicate email' do
      expect do
        post add_user_path, params: { email: 'regular@example.com' }
      end.not_to change(User, :count)
      expect(flash[:alert]).to include('already exists')
    end

    context 'when user is not admin' do
      before do
        allow_any_instance_of(ActionController::Base).to receive(:session).and_return({ user_id: regular_user.id })
      end

      it 'redirects to root' do
        post add_user_path, params: { email: 'newuser@example.com' }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'DELETE /admin/users/:id (destroy_user)' do
    it 'deletes the user' do
      expect do
        delete destroy_user_path(regular_user)
      end.to change(User, :count).by(-1)
      expect(response).to redirect_to(admin_users_path)
    end

    it 'prevents deleting own account' do
      expect do
        delete destroy_user_path(admin_user)
      end.not_to change(User, :count)
      expect(flash[:alert]).to include('own account')
    end

    it 'can delete a pending (pre-added) user' do
      pending_user = User.create!(email: 'pending@example.com', active: true)
      expect do
        delete destroy_user_path(pending_user)
      end.to change(User, :count).by(-1)
    end

    context 'when user is not admin' do
      before do
        allow_any_instance_of(ActionController::Base).to receive(:session).and_return({ user_id: regular_user.id })
      end

      it 'redirects to root' do
        delete destroy_user_path(inactive_user)
        expect(response).to redirect_to(root_path)
      end
    end
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
