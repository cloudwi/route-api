# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Courses API", type: :request do
  # 테스트용 사용자 및 토큰 생성
  let(:user) { User.create!(provider: "kakao", uid: "test123", name: "Test User", email: "test@test.com") }
  let(:token) { JsonWebToken.encode(user_id: user.id) }
  let(:Authorization) { "Bearer #{token}" }

  path "/api/v1/courses" do
    get "코스 목록 조회" do
      tags "코스 관리"
      description "현재 로그인한 사용자의 모든 코스를 조회합니다"
      produces "application/json"
      security [ bearer_auth: [] ]

      response "200", "조회 성공" do
        schema type: :array,
               items: {
                 type: :object,
                 properties: {
                   id: { type: :integer, description: "코스 ID" },
                   name: { type: :string, description: "코스 이름" },
                   places: {
                     type: :array,
                     items: { "$ref" => "#/components/schemas/Place" }
                   },
                   createdAt: { type: :string, format: "date-time", description: "생성일시" }
                 },
                 required: %w[id name places createdAt]
               }

        run_test!
      end

      response "401", "인증 실패" do
        let(:Authorization) { "" }
        run_test!
      end
    end

    post "코스 생성" do
      tags "코스 관리"
      description "새로운 코스를 생성합니다"
      consumes "application/json"
      produces "application/json"
      security [ bearer_auth: [] ]

      parameter name: :course_params, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string, description: "코스 이름" },
          places: {
            type: :array,
            items: {
              type: :object,
              properties: {
                id: { type: :string, description: "네이버 장소 ID" },
                name: { type: :string, description: "장소명" },
                address: { type: :string, description: "지번 주소" },
                roadAddress: { type: :string, description: "도로명 주소" },
                lat: { type: :number, description: "위도" },
                lng: { type: :number, description: "경도" },
                category: { type: :string, description: "카테고리" },
                telephone: { type: :string, description: "전화번호" },
                naverMapUrl: { type: :string, description: "네이버 지도 URL" }
              },
              required: %w[name lat lng]
            }
          }
        },
        required: %w[name places]
      }

      response "201", "생성 성공" do
        schema type: :object,
               properties: {
                 id: { type: :integer, description: "코스 ID" },
                 name: { type: :string, description: "코스 이름" },
                 places: {
                   type: :array,
                   items: { "$ref" => "#/components/schemas/Place" }
                 },
                 createdAt: { type: :string, format: "date-time", description: "생성일시" }
               },
               required: %w[id name places createdAt]

        let(:course_params) do
          {
            name: "강남 데이트 코스",
            places: [
              {
                id: "place1",
                name: "스타벅스 강남R점",
                address: "서울특별시 강남구 역삼동 825",
                roadAddress: "서울특별시 강남구 강남대로 390",
                lat: 37.497711,
                lng: 127.028439,
                category: "카페",
                telephone: "02-1234-5678",
                naverMapUrl: "https://map.naver.com/p/search/스타벅스"
              }
            ]
          }
        end

        run_test!
      end

      response "401", "인증 실패" do
        let(:Authorization) { "" }
        let(:course_params) { { name: "테스트", places: [] } }
        run_test!
      end

      response "422", "유효성 검사 실패" do
        let(:course_params) { { name: "", places: [] } }
        run_test!
      end
    end
  end

  path "/api/v1/courses/{id}" do
    parameter name: :id, in: :path, type: :integer, description: "코스 ID"

    get "코스 상세 조회" do
      tags "코스 관리"
      description "특정 코스의 상세 정보를 조회합니다"
      produces "application/json"
      security [ bearer_auth: [] ]

      response "200", "조회 성공" do
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 name: { type: :string },
                 places: {
                   type: :array,
                   items: { "$ref" => "#/components/schemas/Place" }
                 },
                 createdAt: { type: :string, format: "date-time" }
               }

        let(:course) { Course.create_with_places(user: user, name: "테스트 코스", places_data: []) }
        let(:id) { course.id }
        run_test!
      end

      response "404", "코스 없음" do
        let(:id) { 99999 }
        run_test!
      end
    end

    delete "코스 삭제" do
      tags "코스 관리"
      description "코스를 삭제합니다"
      produces "application/json"
      security [ bearer_auth: [] ]

      response "200", "삭제 성공" do
        schema type: :object,
               properties: {
                 message: { type: :string }
               }

        let(:course) { Course.create_with_places(user: user, name: "삭제할 코스", places_data: []) }
        let(:id) { course.id }
        run_test!
      end

      response "404", "코스 없음" do
        let(:id) { 99999 }
        run_test!
      end
    end
  end

end
