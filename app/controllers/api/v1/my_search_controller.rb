module Api
  module V1
    class MySearchController < ApplicationController
      # 로그인 불필요 - 전체 공개 검색

      # GET /api/v1/my_search
      # 장소 검색
      # Parameters:
      #   - q: 검색 키워드 (optional)
      #   - category: 카테고리 필터 (optional)
      #   - limit: 결과 개수 제한 (optional, default: 20)
      def index
        query = params[:q]
        category = params[:category]
        limit = (params[:limit] || 20).to_i.clamp(1, 100)

        places = search_places(query, category, limit)

        render json: { places: places.map { |place| format_place(place) } }, status: :ok
      end

      # GET /api/v1/my_search/categories
      # 사용 가능한 카테고리 목록 (전체 장소에서 추출)
      def categories
        all_categories = Place.where.not(category: [ nil, "" ])
                              .distinct
                              .pluck(:category)

        # 대분류만 추출 (예: "카페,디저트>카페" → "카페,디저트")
        main_categories = all_categories.map { |cat| cat.split(">").first }
                                       .uniq
                                       .compact
                                       .sort

        render json: { categories: main_categories }, status: :ok
      end

      private

      def search_places(query, category, limit)
        places = Place.all

        # 카테고리 필터
        if category.present?
          places = places.where("category LIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(category)}%")
        end

        # 키워드 검색 (이름, 주소)
        if query.present?
          sanitized_query = ActiveRecord::Base.sanitize_sql_like(query)
          places = places.where(
            "name LIKE ? OR address LIKE ? OR road_address LIKE ?",
            "%#{sanitized_query}%", "%#{sanitized_query}%", "%#{sanitized_query}%"
          )
        end

        places.order(likes_count: :desc, created_at: :desc).limit(limit)
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
          createdAt: place.created_at.iso8601
        }
      end
    end
  end
end
