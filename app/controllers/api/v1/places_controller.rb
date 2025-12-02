module Api
  module V1
    class PlacesController < ApplicationController
      before_action :require_login
      before_action :set_place, only: [ :show, :like ]

      # GET /api/v1/places
      # 내 장소 목록 조회
      def index
        places = current_user.places.order(created_at: :desc)

        render json: places.map { |place| format_place(place) }, status: :ok
      end

      # GET /api/v1/places/:id
      # 장소 상세 조회 (조회수 증가)
      def show
        @place.increment_views!

        render json: format_place(@place), status: :ok
      end

      # POST /api/v1/places/:id/like
      # 좋아요 토글 (추가/취소)
      def like
        like_record = @place.place_likes.find_by(user: current_user)

        if like_record
          # 이미 좋아요한 경우 -> 취소
          like_record.destroy!
          render json: {
            message: "좋아요 취소됨",
            likes_count: @place.reload.likes_count,
            liked: false
          }, status: :ok
        else
          # 좋아요하지 않은 경우 -> 추가
          @place.place_likes.create!(user: current_user)
          render json: {
            message: "좋아요 추가됨",
            likes_count: @place.reload.likes_count,
            liked: true
          }, status: :ok
        end
      end

      # GET /api/v1/places/liked
      # 좋아요한 장소 목록
      def liked
        places = current_user.liked_places.order("place_likes.created_at DESC")

        render json: places.map { |place| format_place(place) }, status: :ok
      end

      private

      def set_place
        @place = current_user.places.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Place not found" }, status: :not_found
      end

      def format_place(place)
        {
          id: place.id,
          naverPlaceId: place.naver_place_id,
          name: place.name,
          address: place.address,
          roadAddress: place.road_address,
          lat: place.latitude.to_f,
          lng: place.longitude.to_f,
          category: place.category,
          telephone: place.telephone,
          naverMapUrl: place.naver_map_url,
          viewsCount: place.views_count,
          likesCount: place.likes_count,
          liked: place.liked_by?(current_user),
          createdAt: place.created_at.iso8601
        }
      end
    end
  end
end
