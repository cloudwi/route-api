# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Diaries API", type: :request do
  # 테스트용 사용자 및 토큰 생성
  let(:user) { User.create!(provider: "kakao", uid: "test123", name: "Test User", email: "test@test.com") }
  let(:other_user) { User.create!(provider: "kakao", uid: "test456", name: "Other User", email: "other@test.com") }
  let(:token) { JsonWebToken.encode(user_id: user.id) }
  let(:Authorization) { "Bearer #{token}" }

  path "/api/v1/diaries" do
    get "일기 목록 조회" do
      tags "일기"
      description "현재 로그인한 사용자의 일기 목록을 조회합니다 (작성한 일기 + 공유받은 일기)"
      produces "application/json"
      security [ bearer_auth: [] ]

      response "200", "조회 성공" do
        schema type: :array,
               items: {
                 type: :object,
                 properties: {
                   id: { type: :integer, description: "일기 ID" },
                   title: { type: :string, description: "일기 제목" },
                   thumbnailImage: { type: :string, nullable: true, description: "썸네일 이미지 URL" },
                   author: {
                     type: :object,
                     properties: {
                       id: { type: :integer, description: "작성자 ID" },
                       name: { type: :string, description: "작성자 이름" }
                     }
                   },
                   isOwner: { type: :boolean, description: "소유자 여부" },
                   createdAt: { type: :string, format: "date-time", description: "생성일시" }
                 }
               }

        run_test!
      end

      response "401", "인증 실패" do
        let(:Authorization) { "" }
        run_test!
      end
    end

    post "일기 생성" do
      tags "일기"
      description "새로운 일기를 생성합니다. 썸네일 이미지는 multipart/form-data로 전송합니다."
      consumes "multipart/form-data"
      produces "application/json"
      security [ bearer_auth: [] ]

      parameter name: :diary, in: :formData, schema: {
        type: :object,
        properties: {
          title: { type: :string, description: "일기 제목" },
          content: { type: :string, description: "일기 내용" }
        },
        required: [ "title" ]
      }

      parameter name: :thumbnail_image, in: :formData, type: :file, description: "썸네일 이미지 (단일)", required: false

      response "201", "생성 성공" do
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 title: { type: :string },
                 content: { type: :string },
                 thumbnailImage: { type: :string, nullable: true, description: "썸네일 이미지 URL" },
                 author: {
                   type: :object,
                   properties: {
                     id: { type: :integer },
                     name: { type: :string },
                     profileImage: { type: :string, nullable: true }
                   }
                 },
                 isOwner: { type: :boolean },
                 createdAt: { type: :string, format: "date-time" },
                 updatedAt: { type: :string, format: "date-time" }
               }

        let(:diary) { { title: "테스트 일기", content: "테스트 내용" } }
        run_test!
      end

      response "422", "유효성 검증 실패" do
        let(:diary) { { content: "제목 없음" } }
        run_test!
      end

      response "401", "인증 실패" do
        let(:Authorization) { "" }
        let(:diary) { { title: "테스트 일기" } }
        run_test!
      end
    end
  end

  path "/api/v1/diaries/{id}" do
    parameter name: :id, in: :path, type: :integer, description: "일기 ID"

    get "일기 상세 조회" do
      tags "일기"
      description "특정 일기의 상세 정보를 조회합니다"
      produces "application/json"
      security [ bearer_auth: [] ]

      response "200", "조회 성공" do
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 title: { type: :string },
                 content: { type: :string },
                 thumbnailImage: { type: :string, nullable: true, description: "썸네일 이미지 URL" },
                 author: {
                   type: :object,
                   properties: {
                     id: { type: :integer },
                     name: { type: :string },
                     profileImage: { type: :string, nullable: true }
                   }
                 },
                 isOwner: { type: :boolean },
                 createdAt: { type: :string, format: "date-time" },
                 updatedAt: { type: :string, format: "date-time" }
               }

        let(:diary_record) { Diary.create!(user: user, title: "테스트 일기", content: "테스트 내용") }
        let(:id) { diary_record.id }
        run_test!
      end

      response "404", "일기 없음" do
        let(:id) { 99999 }
        run_test!
      end

      response "401", "인증 실패" do
        let(:Authorization) { "" }
        let(:diary_record) { Diary.create!(user: user, title: "테스트 일기", content: "테스트 내용") }
        let(:id) { diary_record.id }
        run_test!
      end
    end

    patch "일기 수정" do
      tags "일기"
      description "일기를 수정합니다. 소유자만 수정 가능합니다."
      consumes "multipart/form-data"
      produces "application/json"
      security [ bearer_auth: [] ]

      parameter name: :diary, in: :formData, schema: {
        type: :object,
        properties: {
          title: { type: :string, description: "일기 제목" },
          content: { type: :string, description: "일기 내용" }
        }
      }

      parameter name: :images, in: :formData, type: :array, items: { type: :file }, description: "추가할 이미지", required: false
      parameter name: :delete_images, in: :formData, type: :array, items: { type: :string }, description: "삭제할 이미지 ID 목록", required: false

      response "200", "수정 성공" do
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 title: { type: :string },
                 content: { type: :string },
                 thumbnailImage: { type: :string, nullable: true, description: "썸네일 이미지 URL" },
                 author: {
                   type: :object,
                   properties: {
                     id: { type: :integer },
                     name: { type: :string },
                     profileImage: { type: :string, nullable: true }
                   }
                 },
                 isOwner: { type: :boolean },
                 createdAt: { type: :string, format: "date-time" },
                 updatedAt: { type: :string, format: "date-time" }
               }

        let(:diary_record) { Diary.create!(user: user, title: "테스트 일기", content: "테스트 내용") }
        let(:id) { diary_record.id }
        let(:diary) { { title: "수정된 제목", content: "수정된 내용" } }
        run_test!
      end

      response "403", "권한 없음" do
        let(:diary_record) { Diary.create!(user: other_user, title: "다른 사람 일기", content: "내용") }
        let(:id) { diary_record.id }
        let(:diary) { { title: "수정 시도" } }
        run_test!
      end

      response "404", "일기 없음" do
        let(:id) { 99999 }
        let(:diary) { { title: "수정 시도" } }
        run_test!
      end
    end

    delete "일기 삭제" do
      tags "일기"
      description "일기를 삭제합니다. 소유자만 삭제 가능합니다."
      produces "application/json"
      security [ bearer_auth: [] ]

      response "204", "삭제 성공" do
        let(:diary_record) { Diary.create!(user: user, title: "테스트 일기", content: "테스트 내용") }
        let(:id) { diary_record.id }
        run_test!
      end

      response "403", "권한 없음" do
        let(:diary_record) { Diary.create!(user: other_user, title: "다른 사람 일기", content: "내용") }
        let(:id) { diary_record.id }
        run_test!
      end

      response "404", "일기 없음" do
        let(:id) { 99999 }
        run_test!
      end
    end
  end
end