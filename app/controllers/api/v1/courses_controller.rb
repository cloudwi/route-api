module Api
  module V1
    class CoursesController < ApplicationController
      before_action :require_login

      # GET /api/v1/courses
      # 내 코스 목록 조회
      def index
        courses = current_user.courses.includes(course_places: :place).order(created_at: :desc)

        render json: courses.map { |course| format_course(course) }, status: :ok
      end

      # GET /api/v1/courses/:id
      # 코스 상세 조회
      def show
        course = current_user.courses.includes(course_places: :place).find(params[:id])

        render json: format_course(course), status: :ok
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Course not found" }, status: :not_found
      end

      # POST /api/v1/courses
      # 코스 생성
      def create
        course = Course.create_with_places(
          user: current_user,
          name: params[:name],
          places_data: places_params
        )

        render json: format_course(course), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      # DELETE /api/v1/courses/:id
      # 코스 삭제
      def destroy
        course = current_user.courses.find(params[:id])
        course.destroy!

        render json: { message: "Course deleted" }, status: :ok
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Course not found" }, status: :not_found
      end

      # GET /api/v1/courses/:id/directions?mode=transit|driving
      # 코스 내 장소들 간의 경로 검색
      # A → B → C → D 코스라면, A→B, B→C, C→D 경로를 모두 반환
      def directions
        course = current_user.courses.includes(course_places: :place).find(params[:id])
        places = course.course_places.order(:position).map(&:place)

        if places.length < 2
          render json: { error: "Course must have at least 2 places" }, status: :unprocessable_entity
          return
        end

        mode = params[:mode]
        unless %w[transit driving].include?(mode)
          render json: { error: "Invalid mode. Use 'transit' or 'driving'" }, status: :bad_request
          return
        end

        # 각 구간별 경로 검색
        segments = []
        places.each_cons(2).with_index do |(from_place, to_place), index|
          route = fetch_route(from_place, to_place, mode)
          segments << {
            segment: index + 1,
            from: format_place_simple(from_place),
            to: format_place_simple(to_place),
            route: route
          }
        end

        render json: {
          course_id: course.id,
          course_name: course.name,
          mode: mode,
          total_segments: segments.length,
          segments: segments,
          summary: calculate_summary(segments, mode)
        }, status: :ok
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Course not found" }, status: :not_found
      end

      private

      def places_params
        return [] unless params[:places].is_a?(Array)

        params[:places].map do |place|
          {
            id: place[:id],
            name: place[:name],
            address: place[:address],
            road_address: place[:roadAddress],
            lat: place[:lat],
            lng: place[:lng],
            category: place[:category],
            telephone: place[:telephone],
            naver_map_url: place[:naverMapUrl]
          }
        end
      end

      def format_course(course)
        {
          id: course.id,
          name: course.name,
          places: course.course_places.map { |place| format_place(place) },
          createdAt: course.created_at.iso8601
        }
      end

      def format_place(course_place)
        place = course_place.place
        {
          id: place.naver_place_id,
          name: place.name,
          address: place.address,
          roadAddress: place.road_address,
          lat: place.latitude.to_f,
          lng: place.longitude.to_f,
          category: place.category,
          telephone: place.telephone,
          naverMapUrl: place.naver_map_url
        }
      end

      def format_place_simple(place)
        {
          name: place.name,
          lat: place.latitude.to_f,
          lng: place.longitude.to_f
        }
      end

      def fetch_route(from_place, to_place, mode)
        case mode
        when "transit"
          OdsayTransitService.search_route(
            start_lat: from_place.latitude.to_f,
            start_lng: from_place.longitude.to_f,
            end_lat: to_place.latitude.to_f,
            end_lng: to_place.longitude.to_f
          )
        when "driving"
          NaverDirectionsService.search_route(
            start_lat: from_place.latitude.to_f,
            start_lng: from_place.longitude.to_f,
            end_lat: to_place.latitude.to_f,
            end_lng: to_place.longitude.to_f
          )
        end
      end

      def calculate_summary(segments, mode)
        case mode
        when "transit"
          calculate_transit_summary(segments)
        when "driving"
          calculate_driving_summary(segments)
        end
      end

      def calculate_transit_summary(segments)
        total_time = 0
        total_distance = 0
        total_payment = 0

        segments.each do |segment|
          route = segment[:route]
          next if route[:error] || route[:paths].blank?

          # 첫 번째 경로(추천 경로) 기준
          best_path = route[:paths].first
          total_time += best_path[:total_time].to_i
          total_distance += best_path[:total_distance].to_i
          total_payment += best_path[:payment].to_i
        end

        {
          total_time: total_time,
          total_time_text: "#{total_time}분",
          total_distance: total_distance,
          total_distance_text: format_distance(total_distance),
          total_payment: total_payment,
          total_payment_text: "#{total_payment.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}원"
        }
      end

      def calculate_driving_summary(segments)
        total_duration = 0
        total_distance = 0
        total_toll = 0
        total_fuel = 0

        segments.each do |segment|
          route = segment[:route]
          next if route[:error] || route[:summary].blank?

          summary = route[:summary]
          total_duration += summary[:duration].to_i
          total_distance += summary[:distance].to_i
          total_toll += summary[:toll_fare].to_i
          total_fuel += summary[:fuel_price].to_i
        end

        total_minutes = (total_duration / 60_000.0).round

        {
          total_duration: total_duration,
          total_duration_minutes: total_minutes,
          total_duration_text: format_duration(total_minutes),
          total_distance: total_distance,
          total_distance_text: format_distance(total_distance),
          total_toll_fare: total_toll,
          total_fuel_price: total_fuel
        }
      end

      def format_distance(meters)
        if meters >= 1000
          "#{(meters / 1000.0).round(1)}km"
        else
          "#{meters}m"
        end
      end

      def format_duration(minutes)
        hours = (minutes / 60).to_i
        mins = (minutes % 60).to_i
        if hours > 0
          "#{hours}시간 #{mins}분"
        else
          "#{mins}분"
        end
      end
    end
  end
end
