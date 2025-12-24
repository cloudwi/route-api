module Api
  module V1
    # 이미지 업로드 API 컨트롤러
    # 이미지를 업로드하고 공개 URL을 반환합니다
    class ImagesController < ApplicationController
      # 로그인 선택 사항 - 현재는 ApplicationController에 require_login이 없으므로 생략

      # POST /api/v1/images
      # 이미지를 업로드하고 URL을 반환합니다
      # 파라미터:
      #   - image: 이미지 파일 (필수)
      #   - purpose: 이미지 용도 (선택, 예: place_thumbnail, profile)
      def create
        unless params[:image].present?
          return render json: {
            error: "Image is required",
            message: "Please provide an image file"
          }, status: :bad_request
        end

        image = Image.new(
          user: current_user,  # 로그인한 경우 사용자 연결
          purpose: params[:purpose]
        )
        image.file.attach(params[:image])

        if image.save
          render json: {
            id: image.id,
            url: image.url,
            purpose: image.purpose,
            createdAt: image.created_at.iso8601
          }, status: :created
        else
          render json: {
            error: "Failed to upload image",
            messages: image.errors.full_messages
          }, status: :unprocessable_entity
        end
      rescue StandardError => e
        Rails.logger.error "Image Upload Error: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")

        render json: {
          error: "Internal server error",
          message: "An error occurred while uploading the image"
        }, status: :internal_server_error
      end

      # GET /api/v1/images/:id
      # 이미지 정보 조회 (URL 포함)
      def show
        image = Image.find(params[:id])

        render json: {
          id: image.id,
          url: image.url,
          purpose: image.purpose,
          createdAt: image.created_at.iso8601
        }, status: :ok
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Image not found" }, status: :not_found
      end

      # DELETE /api/v1/images/:id
      # 이미지 삭제 (본인 또는 비로그인 업로드 이미지만 삭제 가능)
      def destroy
        image = Image.find(params[:id])

        # 권한 체크: 로그인한 사용자의 이미지이거나, 소유자가 없는 이미지만 삭제 가능
        if image.user_id.present? && image.user_id != current_user&.id
          return render json: { error: "You don't have permission to delete this image" }, status: :forbidden
        end

        image.destroy
        head :no_content
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Image not found" }, status: :not_found
      end
    end
  end
end
