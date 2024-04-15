class AdminController < ApplicationController
  before_action :require_login
  layout 'admin'

  def users
    if current_user.admin?
      @users = User.all
    else
      redirect_to root_path, alert: "You are not authorized to access this page."
    end
  end
end
