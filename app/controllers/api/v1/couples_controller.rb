module Api
  module V1
    # 커플 관계 API 컨트롤러
    # 커플 정보 조회 및 관계 해제 기능 제공
    class CouplesController < ApplicationController
      before_action :require_login

      # GET /api/v1/couple
      # 현재 사용자의 커플 정보 조회
      def show
        couple = current_user.couple

        unless couple
          return render json: {
            error: "Not in a couple",
            message: "You are not in a couple relationship"
          }, status: :not_found
        end

        partner = couple.partner_for(current_user)

        render json: {
          id: couple.id,
          partner: {
            id: partner.id,
            name: partner.name,
            email: partner.email,
            profileImage: partner.profile_image
          },
          createdAt: couple.created_at.iso8601
        }, status: :ok
      end

      # DELETE /api/v1/couple
      # 커플 관계 해제
      def destroy
        couple = current_user.couple

        unless couple
          return render json: {
            error: "Not in a couple",
            message: "You are not in a couple relationship"
          }, status: :not_found
        end

        couple.destroy!

        render json: {
          message: "Successfully disconnected from couple"
        }, status: :ok
      rescue StandardError => e
        Rails.logger.error "Couple Disconnect Error: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")

        render json: {
          error: "Internal server error",
          message: "An error occurred while disconnecting from couple"
        }, status: :internal_server_error
      end
    end
  end
end
