module Api
  module V1
    # 통합 경로 검색 API 컨트롤러
    # 이동 수단에 따라 대중교통(ODsay) 또는 자동차(Naver Directions) 경로를 반환
    class DirectionsController < ApplicationController
      before_action :require_login

      # 지원하는 이동 수단
      TRANSPORT_MODES = %w[transit driving].freeze

      # GET /api/v1/directions
      # 경로 검색
      #
      # 필수 파라미터:
      #   - start_lat: 출발지 위도
      #   - start_lng: 출발지 경도
      #   - end_lat: 도착지 위도
      #   - end_lng: 도착지 경도
      #   - mode: 이동 수단 (transit: 대중교통, driving: 자동차)
      #
      # 선택 파라미터 (대중교통):
      #   - path_type: 경로 유형 (0: 모두, 1: 지하철, 2: 버스)
      #
      # 선택 파라미터 (자동차):
      #   - route_option: 경로 옵션 (fastest, comfortable, optimal, avoid_toll, avoid_car_only)
      #   - car_type: 차량 타입 (1-6)
      #   - waypoints: 경유지 배열 [{lat:, lng:}, ...]
      def index
        # 필수 파라미터 검증
        validation_error = validate_required_params
        return render_error(validation_error, :bad_request) if validation_error

        # 좌표 검증
        coord_error = validate_coordinates
        return render_error(coord_error, :bad_request) if coord_error

        # 이동 수단에 따라 적절한 서비스 호출
        result = case params[:mode]
        when "transit"
          search_transit_route
        when "driving"
          search_driving_route
        end

        if result[:error]
          render_error(result[:error], :unprocessable_entity)
        else
          render json: {
            mode: params[:mode],
            start: { lat: start_lat, lng: start_lng },
            destination: { lat: end_lat, lng: end_lng },
            result: result
          }, status: :ok
        end
      end

      private

      def validate_required_params
        missing = []
        missing << "start_lat" if params[:start_lat].blank?
        missing << "start_lng" if params[:start_lng].blank?
        missing << "end_lat" if params[:end_lat].blank?
        missing << "end_lng" if params[:end_lng].blank?
        missing << "mode" if params[:mode].blank?

        return "Missing required parameters: #{missing.join(', ')}" if missing.any?

        unless TRANSPORT_MODES.include?(params[:mode])
          return "Invalid mode. Supported modes: #{TRANSPORT_MODES.join(', ')}"
        end

        nil
      end

      def validate_coordinates
        coords = [ start_lat, start_lng, end_lat, end_lng ]

        if coords.any?(&:nil?)
          return "Invalid coordinate format. Please provide valid numbers."
        end

        # 한국 영역 좌표 범위 검증 (대략적)
        if start_lat < 33 || start_lat > 43 || end_lat < 33 || end_lat > 43
          return "Latitude must be between 33 and 43 (Korean peninsula)"
        end

        if start_lng < 124 || start_lng > 132 || end_lng < 124 || end_lng > 132
          return "Longitude must be between 124 and 132 (Korean peninsula)"
        end

        nil
      end

      def start_lat
        @start_lat ||= params[:start_lat]&.to_f
      end

      def start_lng
        @start_lng ||= params[:start_lng]&.to_f
      end

      def end_lat
        @end_lat ||= params[:end_lat]&.to_f
      end

      def end_lng
        @end_lng ||= params[:end_lng]&.to_f
      end

      def search_transit_route
        OdsayTransitService.search_route(
          start_lat: start_lat,
          start_lng: start_lng,
          end_lat: end_lat,
          end_lng: end_lng,
          path_type: params[:path_type]&.to_i || 0
        )
      end

      def search_driving_route
        options = {
          route_option: params[:route_option] || "optimal",
          car_type: params[:car_type]&.to_i,
          waypoints: parse_waypoints
        }.compact

        NaverDirectionsService.search_route(
          start_lat: start_lat,
          start_lng: start_lng,
          end_lat: end_lat,
          end_lng: end_lng,
          **options
        )
      end

      def parse_waypoints
        return nil if params[:waypoints].blank?

        # waypoints는 JSON 배열 형태로 전달: [{"lat": 37.5, "lng": 127.0}, ...]
        waypoints = params[:waypoints]
        waypoints = JSON.parse(waypoints) if waypoints.is_a?(String)

        waypoints.map do |wp|
          { lat: wp["lat"].to_f, lng: wp["lng"].to_f }
        end
      rescue JSON::ParserError
        nil
      end

      def render_error(message, status)
        render json: {
          error: message,
          mode: params[:mode]
        }, status: status
      end
    end
  end
end
