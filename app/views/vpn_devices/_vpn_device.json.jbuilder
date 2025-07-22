# frozen_string_literal: true

json.extract! vpn_device, :id, :user_id, :description, :private_key, :public_key, :created_at, :updated_at
json.url vpn_device_url(vpn_device, format: :json)
