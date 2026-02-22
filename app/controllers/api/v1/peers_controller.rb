# frozen_string_literal: true

module Api
  module V1
    class PeersController < ActionController::API
      include ApiAuthentication

      def index
        peers = Peer.active.order(created_at: :desc)
        render json: peers.map { |p| peer_json(p) }
      end

      def show
        peer = Peer.active.find(params[:id])
        render json: peer_json(peer)
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Peer not found' }, status: :not_found
      end

      def create
        peer = WireguardService.create_peer!(
          name: peer_params[:name],
          dns: peer_params[:dns]
        )

        render json: peer_json(peer), status: :created
      rescue WireguardService::WireguardError, ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_content
      end

      def destroy
        peer = Peer.active.find(params[:id])
        WireguardService.remove_peer!(peer)
        head :ok
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Peer not found' }, status: :not_found
      rescue WireguardService::WireguardError => e
        render json: { error: e.message }, status: :unprocessable_content
      end

      private

      def peer_params
        params.require(:peer).permit(:name, :dns)
      end

      def peer_json(peer)
        {
          id: peer.id,
          name: peer.name,
          vpn_ip: peer.vpn_ip,
          public_key: peer.public_key,
          config: peer.config,
          created_at: peer.created_at
        }
      end
    end
  end
end
