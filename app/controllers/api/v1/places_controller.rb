module Api
  module V1
    class PlacesController < ApplicationController
      before_action :require_login
      before_action :set_place, only: [ :show ]

      # GET /api/v1/places
      # 내 장소 목록 조회
      def index
        # N+1 방지: place_likes를 미리 로드
        places = current_user.places
          .left_joins(:place_likes)
          .select("places.*, place_likes.id as current_user_like_id")
          .where("place_likes.user_id = ? OR place_likes.user_id IS NULL", current_user.id)
          .order(created_at: :desc)
          .distinct

        render json: PlaceSerializer.serialize_collection(places, current_user: current_user), status: :ok
      end

      # GET /api/v1/places/:id
      # 장소 상세 조회 (조회수 증가)
      def show
        @place.increment_views!

        render json: PlaceSerializer.serialize(@place, current_user: current_user), status: :ok
      end

      # GET /api/v1/places/liked
      # 좋아요한 장소 목록
      def liked
        places = current_user.liked_places
          .includes(:place_likes)
          .order("place_likes.created_at DESC")

        render json: PlaceSerializer.serialize_collection(places, current_user: current_user), status: :ok
      end

      private

      def set_place
        @place = current_user.places.find(params[:id])
      end
    end
  end
end
