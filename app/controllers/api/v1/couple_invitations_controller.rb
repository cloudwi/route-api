module Api
  module V1
    # 커플 초대 API 컨트롤러
    # 커플 연결을 위한 초대 링크를 생성하고 수락합니다
    class CoupleInvitationsController < ApplicationController
      before_action :require_login

      # POST /api/v1/couple_invitations
      # 커플 초대 링크 생성
      def create
        # 이미 커플이면 초대 생성 불가
        if current_user.in_couple?
          return render json: {
            error: "Already in a couple",
            message: "You are already in a couple relationship"
          }, status: :unprocessable_entity
        end

        # 기존에 사용되지 않은 초대가 있으면 재사용
        invitation = current_user.couple_invitations.valid.first

        # 없으면 새로 생성
        invitation ||= current_user.couple_invitations.create!

        render json: {
          token: invitation.token,
          expiresAt: invitation.expires_at.iso8601,
          inviteUrl: "#{request.base_url}/api/v1/couple_invitations/#{invitation.token}/accept"
        }, status: :created
      rescue StandardError => e
        Rails.logger.error "Couple Invitation Creation Error: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")

        render json: {
          error: "Internal server error",
          message: "An error occurred while creating the invitation"
        }, status: :internal_server_error
      end

      # POST /api/v1/couple_invitations/:token/accept
      # 초대 링크로 커플 연결
      def accept
        token = params[:token]

        invitation = CoupleInvitation.find_by(token: token)

        unless invitation
          return render json: {
            error: "Invitation not found",
            message: "The invitation link is invalid"
          }, status: :not_found
        end

        unless invitation.valid?
          return render json: {
            error: "Invitation expired or used",
            message: "The invitation link has expired or has already been used"
          }, status: :unprocessable_entity
        end

        # 자기 자신의 초대는 수락 불가
        if invitation.inviter_id == current_user.id
          return render json: {
            error: "Cannot accept own invitation",
            message: "You cannot accept your own invitation"
          }, status: :unprocessable_entity
        end

        # 이미 커플이면 수락 불가
        if current_user.in_couple?
          return render json: {
            error: "Already in a couple",
            message: "You are already in a couple relationship"
          }, status: :unprocessable_entity
        end

        # 초대한 사람이 이미 다른 커플이면 수락 불가
        if invitation.inviter.in_couple?
          return render json: {
            error: "Inviter already in a couple",
            message: "The person who invited you is already in a couple relationship"
          }, status: :unprocessable_entity
        end

        # 커플 생성 (user1_id < user2_id 보장)
        user1_id = [ invitation.inviter_id, current_user.id ].min
        user2_id = [ invitation.inviter_id, current_user.id ].max

        couple = Couple.create!(
          user1_id: user1_id,
          user2_id: user2_id
        )

        # 초대 사용 처리
        invitation.mark_as_used!

        render json: {
          message: "Successfully connected as a couple",
          couple: {
            id: couple.id,
            partnerId: couple.partner_for(current_user).id,
            partnerName: couple.partner_for(current_user).name,
            createdAt: couple.created_at.iso8601
          }
        }, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: {
          error: "Failed to create couple",
          message: e.message
        }, status: :unprocessable_entity
      rescue StandardError => e
        Rails.logger.error "Couple Invitation Accept Error: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")

        render json: {
          error: "Internal server error",
          message: "An error occurred while accepting the invitation"
        }, status: :internal_server_error
      end
    end
  end
end
