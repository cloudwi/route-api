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
    end
  end
end
