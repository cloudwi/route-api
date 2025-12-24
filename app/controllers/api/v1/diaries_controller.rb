module Api
  module V1
    class DiariesController < ApplicationController
      before_action :require_login
      before_action :set_diary, only: [ :update, :destroy ]
      before_action :set_diary_with_access_check, only: [ :show ]
      before_action :check_ownership, only: [ :update, :destroy ]

      # GET /api/v1/diaries
      # 내 일기 목록 조회 (작성한 일기 + 공유받은 일기)
      def index
        diaries = Diary.accessible_by(current_user).recent

        render json: DiarySerializer.serialize_simple_collection(diaries, current_user: current_user), status: :ok
      end

      # GET /api/v1/diaries/:id
      # 일기 상세 조회
      def show
        render json: DiarySerializer.serialize(@diary, current_user: current_user), status: :ok
      end

      # POST /api/v1/diaries
      # 일기 생성
      def create
        diary = current_user.diaries.build(diary_params)

        if diary.save
          # 썸네일 이미지 첨부 (단일)
          if params[:thumbnail_image].present?
            diary.thumbnail_image.attach(params[:thumbnail_image])
          end

          render json: DiarySerializer.serialize(diary, current_user: current_user), status: :created
        else
          render json: { error: "Failed to create diary", messages: diary.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/diaries/:id
      # 일기 수정
      def update
        if @diary.update(diary_params)
          # 새 썸네일 이미지가 있으면 교체
          if params[:thumbnail_image].present?
            @diary.thumbnail_image.purge if @diary.thumbnail_image.attached?
            @diary.thumbnail_image.attach(params[:thumbnail_image])
          end

          # 썸네일 이미지 삭제 요청
          if params[:delete_thumbnail_image] == "true" || params[:delete_thumbnail_image] == true
            @diary.thumbnail_image.purge if @diary.thumbnail_image.attached?
          end

          render json: DiarySerializer.serialize(@diary, current_user: current_user), status: :ok
        else
          render json: { error: "Failed to update diary", messages: @diary.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/diaries/:id
      # 일기 삭제
      def destroy
        @diary.destroy
        head :no_content
      end

      # POST /api/v1/diaries/:id/share
      # 일기 공유
      def share
        @diary = Diary.find(params[:id])

        # 소유자만 공유 가능
        unless @diary.owned_by?(current_user)
          return render json: { error: "Only the owner can share this diary" }, status: :forbidden
        end

        # 공유할 사용자 찾기
        share_user = User.find_by(id: params[:user_id])
        unless share_user
          return render json: { error: "User not found" }, status: :not_found
        end

        # 자기 자신과는 공유 불가
        if share_user.id == current_user.id
          return render json: { error: "Cannot share with yourself" }, status: :unprocessable_entity
        end

        # 공유 실행
        diary_user = @diary.share_with(share_user, role: params[:role] || "viewer")

        if diary_user.persisted?
          render json: { message: "Diary shared successfully", diary_user: diary_user }, status: :ok
        else
          render json: { error: "Failed to share diary", messages: diary_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/diaries/:id/unshare
      # 일기 공유 해제
      def unshare
        @diary = Diary.find(params[:id])

        # 소유자만 공유 해제 가능
        unless @diary.owned_by?(current_user)
          return render json: { error: "Only the owner can unshare this diary" }, status: :forbidden
        end

        share_user = User.find_by(id: params[:user_id])
        unless share_user
          return render json: { error: "User not found" }, status: :not_found
        end

        @diary.unshare_with(share_user)
        render json: { message: "Diary unshared successfully" }, status: :ok
      end

      private

      # 조회용: 접근 권한 체크 (소유자 또는 공유받은 사용자)
      def set_diary_with_access_check
        @diary = Diary.find(params[:id])

        unless @diary.accessible_by?(current_user)
          render json: { error: "Diary not found or you don't have access" }, status: :not_found
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Diary not found or you don't have access" }, status: :not_found
      end

      # 수정/삭제용: 일기만 찾기 (권한 체크는 check_ownership에서)
      def set_diary
        @diary = Diary.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Diary not found or you don't have access" }, status: :not_found
      end

      def check_ownership
        unless @diary.owned_by?(current_user)
          render json: { error: "Only the owner can perform this action" }, status: :forbidden
        end
      end

      def diary_params
        params.require(:diary).permit(:title, :content)
      end
    end
  end
end
