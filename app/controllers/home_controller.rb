# frozen_string_literal: true

class HomeController < ApplicationController
  def index; end

  def login
    @hide_navbar = true
  end
end
