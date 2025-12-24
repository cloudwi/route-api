module Api
  module V1
    class PlacesController < ApplicationController
      before_action :require_login
      before_action :set_place, only: [ :show ]

      # GET /api/v1/places
      # 내 장소 목록 조회
      def index
        places = current_user.places.order(created_at: :desc)

        render json: PlaceSerializer.serialize_collection(places), status: :ok
      end

      # GET /api/v1/places/:id
      # 장소 상세 조회 (조회수 증가)
      def show
        @place.increment_views!

        render json: PlaceSerializer.serialize(@place), status: :ok
      end

      private

      def set_place
        @place = current_user.places.find(params[:id])
      end
    end
  end
end
