# frozen_string_literal: true

class ChangeProfilePictureUrlToText < ActiveRecord::Migration[8.0]
  def up
    change_column :users, :profile_picture_url, :text
  end

  def down
    change_column :users, :profile_picture_url, :string
  end
end
