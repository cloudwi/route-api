module Api
  module V1
    # 일기 질문 프롬프트 API 컨트롤러
    # 커플 일기를 위한 질문 제공
    class DiaryPromptsController < ApplicationController
      # GET /api/v1/diary_prompts
      # 모든 질문 목록 조회
      def index
        category = params[:category]

        prompts = if category.present?
          DiaryPrompt.by_category(category)
        else
          DiaryPrompt.all
        end

        render json: {
          count: prompts.count,
          prompts: prompts.map do |prompt|
            {
              id: prompt.id,
              content: prompt.content,
              category: prompt.category
            }
          end
        }, status: :ok
      end

      # GET /api/v1/diary_prompts/random
      # 랜덤 질문 하나 조회
      def random
        category = params[:category]

        prompt = if category.present?
          DiaryPrompt.random_by_category(category)
        else
          DiaryPrompt.random
        end

        unless prompt
          return render json: {
            error: "No prompts found",
            message: "No diary prompts available"
          }, status: :not_found
        end

        render json: {
          id: prompt.id,
          content: prompt.content,
          category: prompt.category
        }, status: :ok
      end

      # GET /api/v1/diary_prompts/categories
      # 카테고리 목록 조회
      def categories
        categories = DiaryPrompt.categories

        render json: {
          count: categories.count,
          categories: categories
        }, status: :ok
      end
    end
  end
end
