# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Places API", type: :request do
  # 테스트용 사용자 및 토큰 생성
  let(:user) { User.create!(provider: "kakao", uid: "test123", name: "Test User", email: "test@test.com") }
  let(:token) { JsonWebToken.encode(user_id: user.id) }
  let(:Authorization) { "Bearer #{token}" }

  path "/api/v1/places" do
    get "장소 목록 조회" do
      tags "장소"
      description "현재 로그인한 사용자의 장소 목록을 조회합니다"
      produces "application/json"
      security [ bearer_auth: [] ]

      response "200", "조회 성공" do
        schema type: :array,
               items: {
                 type: :object,
                 properties: {
                   id: { type: :integer, description: "내부 장소 ID" },
                   naverPlaceId: { type: :string, description: "네이버 장소 ID" },
                   name: { type: :string, description: "장소명" },
                   address: { type: :string, description: "지번 주소" },
                   roadAddress: { type: :string, description: "도로명 주소" },
                   lat: { type: :number, description: "위도" },
                   lng: { type: :number, description: "경도" },
                   category: { type: :string, description: "카테고리" },
                   telephone: { type: :string, description: "전화번호" },
                   naverMapUrl: { type: :string, description: "네이버 지도 URL" },
                   viewsCount: { type: :integer, description: "조회수" },
                   likesCount: { type: :integer, description: "좋아요 수" },
                   liked: { type: :boolean, description: "좋아요 여부" },
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
  end

  path "/api/v1/places/liked" do
    get "좋아요한 장소 목록" do
      tags "장소"
      description "현재 사용자가 좋아요한 장소 목록을 조회합니다"
      produces "application/json"
      security [ bearer_auth: [] ]

      response "200", "조회 성공" do
        schema type: :array,
               items: {
                 type: :object,
                 properties: {
                   id: { type: :integer },
                   naverPlaceId: { type: :string },
                   name: { type: :string },
                   address: { type: :string },
                   roadAddress: { type: :string },
                   lat: { type: :number },
                   lng: { type: :number },
                   category: { type: :string },
                   telephone: { type: :string },
                   naverMapUrl: { type: :string },
                   viewsCount: { type: :integer },
                   likesCount: { type: :integer },
                   liked: { type: :boolean },
                   createdAt: { type: :string, format: "date-time" }
                 }
               }

        run_test!
      end

      response "401", "인증 실패" do
        let(:Authorization) { "" }
        run_test!
      end
    end
  end

  path "/api/v1/places/{id}" do
    parameter name: :id, in: :path, type: :integer, description: "장소 ID"

    get "장소 상세 조회" do
      tags "장소"
      description "특정 장소의 상세 정보를 조회합니다 (조회수 증가)"
      produces "application/json"
      security [ bearer_auth: [] ]

      response "200", "조회 성공" do
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 naverPlaceId: { type: :string, nullable: true },
                 name: { type: :string },
                 address: { type: :string },
                 roadAddress: { type: :string, nullable: true },
                 lat: { type: :number },
                 lng: { type: :number },
                 category: { type: :string, nullable: true },
                 telephone: { type: :string, nullable: true },
                 naverMapUrl: { type: :string, nullable: true },
                 viewsCount: { type: :integer },
                 likesCount: { type: :integer },
                 liked: { type: :boolean },
                 createdAt: { type: :string, format: "date-time" }
               }

        let(:place) { Place.create!(user: user, naver_place_id: "place123", name: "테스트 장소", latitude: 37.5, longitude: 127.0, address: "서울") }
        let(:id) { place.id }
        run_test!
      end

      response "404", "장소 없음" do
        let(:id) { 99999 }
        run_test!
      end

      response "401", "인증 실패" do
        let(:Authorization) { "" }
        let(:place) { Place.create!(user: user, naver_place_id: "place123", name: "테스트 장소", latitude: 37.5, longitude: 127.0, address: "서울") }
        let(:id) { place.id }
        run_test!
      end
    end
  end

  path "/api/v1/places/{place_id}/likes" do
    parameter name: :place_id, in: :path, type: :integer, description: "장소 ID"

    post "좋아요 토글" do
      tags "장소"
      description "장소에 좋아요를 추가하거나 취소합니다"
      produces "application/json"
      security [ bearer_auth: [] ]

      response "200", "성공" do
        schema type: :object,
               properties: {
                 message: { type: :string, description: "결과 메시지" },
                 likes_count: { type: :integer, description: "현재 좋아요 수" },
                 liked: { type: :boolean, description: "좋아요 상태" }
               }

        let(:place) { Place.create!(user: user, naver_place_id: "place123", name: "테스트 장소", latitude: 37.5, longitude: 127.0, address: "서울") }
        let(:place_id) { place.id }
        run_test!
      end

      response "404", "장소 없음" do
        let(:place_id) { 99999 }
        run_test!
      end

      response "401", "인증 실패" do
        let(:Authorization) { "" }
        let(:place) { Place.create!(user: user, naver_place_id: "place123", name: "테스트 장소", latitude: 37.5, longitude: 127.0, address: "서울") }
        let(:place_id) { place.id }
        run_test!
      end
    end
  end
end
