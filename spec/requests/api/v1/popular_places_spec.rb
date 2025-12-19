# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Popular Places API", type: :request do
  path "/api/v1/popular_places" do
    get "인기 장소 조회" do
      tags "장소"
      description "인기 장소 Top 5를 조회합니다 (조회수 + 좋아요 * 3 기준)"
      produces "application/json"

      response "200", "조회 성공" do
        schema type: :object,
               properties: {
                 places: {
                   type: :array,
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
                       popularityScore: { type: :number, description: "인기 점수" },
                       createdAt: { type: :string, format: "date-time", description: "생성일시" }
                     }
                   }
                 }
               },
               required: [ "places" ]

        run_test!
      end
    end
  end
end
