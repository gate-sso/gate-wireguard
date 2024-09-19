# class SessionsControllerV2 < ApplicationController
#   def create
#     @user = User.from_omniauth(request.env['omniauth.auth'])
#     session[:user_id] = @user.id
#     redirect_to root_path
#   end

#   def destroy
#     session[:user_id] = nil
#     redirect_to root_path
#   end
# end

class SessionsController < ApplicationController
  def create
    auth = request.env['omniauth.auth']
    email_domain = auth['info']['email'].split('@').last

    if email_domain == ENV['HOSTED_DOMAINS']
      # Proceed with login
      user = User.find_or_create_by(provider: auth['provider'], uid: auth['uid']) do |u|
        u.name = auth['info']['name']
        u.email = auth['info']['email']
      end
      @user = user
      session[:user_id] = user.id
      redirect_to root_path, notice: 'Signed in!'
    else
      # Reject login for other domains
      redirect_to root_path, alert: 'Unauthorized domain.'
    end
  end
end