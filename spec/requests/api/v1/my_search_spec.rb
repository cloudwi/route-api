# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "My Search API", type: :request do
  path "/api/v1/my_search" do
    get "내부 장소 검색" do
      tags "검색"
      description "저장된 장소를 검색합니다"
      produces "application/json"

      parameter name: :q, in: :query, type: :string, required: false, description: "검색 키워드"
      parameter name: :category, in: :query, type: :string, required: false, description: "카테고리 필터 (장소 검색에만 적용)"
      parameter name: :type, in: :query, type: :string, required: false,
                enum: [ "places" ],
                description: "검색 타입 (places: 장소만 검색)"
      parameter name: :limit, in: :query, type: :integer, required: false, description: "결과 개수 제한 (1-100, 기본값: 20)"

      response "200", "검색 성공" do
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
                       createdAt: { type: :string, format: "date-time", description: "생성일시" }
                     }
                   }
                 }
               }

        run_test!
      end
    end
  end

  path "/api/v1/my_search/categories" do
    get "카테고리 목록 조회" do
      tags "검색"
      description "사용 가능한 장소 카테고리 목록을 조회합니다"
      produces "application/json"

      response "200", "조회 성공" do
        schema type: :object,
               properties: {
                 categories: {
                   type: :array,
                   items: { type: :string },
                   description: "카테고리 목록"
                 }
               },
               required: [ "categories" ]

        run_test!
      end
    end
  end
end
