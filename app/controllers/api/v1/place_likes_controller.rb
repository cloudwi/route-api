module Api
  module V1
    class PlaceLikesController < ApplicationController
      before_action :require_login
      before_action :set_place

      # POST /api/v1/places/:place_id/likes
      # 좋아요 토글 (추가/취소)
      def create
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

      private

      def set_place
        @place = Place.find(params[:place_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Place not found" }, status: :not_found
      end
    end
  end
end
