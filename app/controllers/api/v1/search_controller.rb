module Api
  module V1
    # 장소 검색 API 컨트롤러
    # 네이버 로컬 검색 API를 프록시하여 클라이언트에 제공
    class SearchController < ApplicationController
      # JWT 인증을 건너뛰기 (검색은 인증 불필요)
      skip_before_action :authenticate_request

      # GET /api/v1/search?query=스타벅스 강남역
      # 장소를 검색하여 결과를 반환
      # 파라미터:
      #   - query: 검색 키워드 (필수)
      #   - display: 검색 결과 개수 (선택, 기본: 5)
      def index
        query = params[:query]

        if query.blank?
          render json: {
            error: "Query parameter is required",
            message: "Please provide a search query"
          }, status: :bad_request
          return
        end

        display = params[:display]&.to_i || 5
        display = [ [ display, 1 ].max, 5 ].min # 1~5 사이로 제한

        results = NaverSearchService.search_places(
          query: query,
          display: display
        )

        render json: {
          query: query,
          count: results.length,
          places: results
        }, status: :ok
      rescue StandardError => e
        Rails.logger.error "Search Controller Error: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")

        render json: {
          error: "Internal server error",
          message: "An error occurred while processing your search"
        }, status: :internal_server_error
      end
    end
  end
end
