# frozen_string_literal: true

class SessionsController < ApplicationController
  def create
    @user = User.from_omniauth(request.env['omniauth.auth'])
    unless @user.active?
      reset_session
      redirect_to login_path, alert: 'Your account is pending approval. Please contact an administrator.'
      return
    end
    session[:user_id] = @user.id
    redirect_to root_path
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path
  end
end
