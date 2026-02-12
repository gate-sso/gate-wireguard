# frozen_string_literal: true

class SessionsController < ApplicationController
  def create
    auth = request.env['omniauth.auth']
    unless email_allowed?(auth.info.email)
      redirect_to root_path, alert: 'You are not authorized, please contact admins.'
      return
    end
    @user = User.from_omniauth(request.env['omniauth.auth'])
    session[:user_id] = @user.id
    redirect_to root_path
  end

  def email_allowed?(email)
    allowed_domains = ENV.fetch('ALLOWED_EMAIL_DOMAINS', '')
                         .split(',')
                         .map(&:strip)

    whitelisted_emails = ENV.fetch('WHITELISTED_EMAILS', '')
                            .split(',')
                            .map(&:strip)

    domain = email.split('@').last

    allowed_domains.include?(domain) || whitelisted_emails.include?(email)
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path
  end
end
