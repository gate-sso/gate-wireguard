# frozen_string_literal: true

module Api
  module V1
    class DevicesController < ActionController::API
      include ApiAuthentication

      def index
        devices = VpnDevice.includes(:ip_allocation, :user).order(created_at: :desc)
        render json: devices.map { |d| device_json(d) }
      end

      def show
        device = VpnDevice.find(params[:id])
        render json: device_json(device)
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Device not found' }, status: :not_found
      end

      def create
        name = device_params[:name]
        if name.blank?
          render json: { error: 'Name is required' }, status: :unprocessable_content
          return
        end

        user = User.api_system_user
        device = user.vpn_devices.build(description: name)
        device.setup_device_with_keys

        ActiveRecord::Base.transaction do
          device.save!
          allocation = IpAllocation.allocate_ip(device)
          unless allocation
            device.errors.add(:base, 'No available IP addresses in the VPN range')
            raise ActiveRecord::RecordInvalid, device
          end
        end

        update_wireguard_config

        render json: device_json(device), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_content
      end

      def destroy
        device = VpnDevice.find(params[:id])
        device.destroy!
        update_wireguard_config
        head :ok
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Device not found' }, status: :not_found
      end

      private

      def device_params
        params.expect(device: [:name])
      end

      def device_json(device)
        vpn_config = VpnConfiguration.first
        {
          id: device.id,
          name: device.description,
          vpn_ip: device.ip_allocation&.ip_address,
          public_key: device.public_key,
          config: vpn_config ? WireguardConfigGenerator.generate_client_config(device, vpn_config) : nil,
          config_filename: config_filename(device),
          created_at: device.created_at
        }
      end

      def config_filename(device)
        sanitized = device.description.to_s.gsub(/[^a-zA-Z0-9_-]/, '_').downcase
        "#{sanitized}.gate.clawstation.conf"
      end

      def update_wireguard_config
        vpn_config = VpnConfiguration.first
        WireguardConfigGenerator.write_server_configuration(vpn_config) if vpn_config
      end
    end
  end
end
