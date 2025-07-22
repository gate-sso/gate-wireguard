# frozen_string_literal: true

json.array! @vpn_devices, partial: 'vpn_devices/vpn_device', as: :vpn_device
