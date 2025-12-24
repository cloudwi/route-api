module Api
  module V1
    class PopularPlacesController < ApplicationController
      # 로그인 불필요 - require_login을 호출하지 않음

      # GET /api/v1/popular_places
      # 인기 장소 Top5 조회 (로그인 불필요)
      # 조회수 기준으로 정렬
      def index
        places = Place
          .select("places.*, views_count AS popularity_score")
          .order("popularity_score DESC")
          .limit(5)

        render json: {
          places: places.map { |place| format_place(place) }
        }, status: :ok
      end

      private

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
          popularityScore: place.respond_to?(:popularity_score) ? place.popularity_score : nil,
          createdAt: place.created_at.iso8601
        }
      end
    end
  end
end
