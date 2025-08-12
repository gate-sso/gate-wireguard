# frozen_string_literal: true

class AddProfilePictureToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :profile_picture_url, :string
  end
end
