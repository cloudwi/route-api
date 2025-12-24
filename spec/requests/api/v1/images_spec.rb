# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Images API", type: :request do
  # 테스트용 사용자 및 토큰 생성
  let(:user) { User.create!(provider: "kakao", uid: "test123", name: "Test User", email: "test@test.com") }
  let(:token) { JsonWebToken.encode(user_id: user.id) }
  let(:Authorization) { "Bearer #{token}" }

  path "/api/v1/images" do
    post "이미지 업로드" do
      tags "이미지"
      description "이미지를 업로드하고 URL을 반환합니다. 로그인 없이도 업로드 가능합니다."
      consumes "multipart/form-data"
      produces "application/json"

      parameter name: :image, in: :formData, type: :file, description: "업로드할 이미지 파일", required: true
      parameter name: :purpose, in: :formData, type: :string, description: "이미지 용도 (예: place_thumbnail, profile)", required: false

      response "201", "업로드 성공" do
        schema type: :object,
               properties: {
                 id: { type: :integer, description: "이미지 ID" },
                 url: { type: :string, description: "이미지 공개 URL" },
                 purpose: { type: :string, nullable: true, description: "이미지 용도" },
                 createdAt: { type: :string, format: "date-time", description: "업로드 시각" }
               }

        let(:image) { fixture_file_upload(Rails.root.join("spec", "fixtures", "test_image.jpg"), "image/jpeg") }
        run_test!
      end

      response "400", "이미지 누락" do
        let(:image) { nil }
        run_test!
      end
    end
  end

  path "/api/v1/images/{id}" do
    parameter name: :id, in: :path, type: :integer, description: "이미지 ID"

    get "이미지 정보 조회" do
      tags "이미지"
      description "이미지 정보 및 URL을 조회합니다"
      produces "application/json"

      response "200", "조회 성공" do
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 url: { type: :string },
                 purpose: { type: :string, nullable: true },
                 createdAt: { type: :string, format: "date-time" }
               }

        let(:image_record) do
          img = Image.new(user: user)
          img.file.attach(
            io: File.open(Rails.root.join("spec", "fixtures", "test_image.jpg")),
            filename: "test_image.jpg",
            content_type: "image/jpeg"
          )
          img.save!
          img
        end
        let(:id) { image_record.id }
        run_test!
      end

      response "404", "이미지 없음" do
        let(:id) { 99999 }
        run_test!
      end
    end

    delete "이미지 삭제" do
      tags "이미지"
      description "이미지를 삭제합니다. 본인이 업로드한 이미지만 삭제 가능합니다."
      security [ bearer_auth: [] ]

      response "204", "삭제 성공" do
        let(:image_record) do
          img = Image.new(user: user)
          img.file.attach(
            io: File.open(Rails.root.join("spec", "fixtures", "test_image.jpg")),
            filename: "test_image.jpg",
            content_type: "image/jpeg"
          )
          img.save!
          img
        end
        let(:id) { image_record.id }
        run_test!
      end

      response "404", "이미지 없음" do
        let(:id) { 99999 }
        run_test!
      end
    end
  end
end