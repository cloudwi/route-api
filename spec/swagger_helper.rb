# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  config.openapi_root = Rails.root.join("swagger").to_s

  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.1",
      info: {
        title: "Route API",
        version: "v1",
        description: "장소 검색, 코스 관리, 폴더 관리 API"
      },
      paths: {},
      servers: [
        {
          url: "http://localhost:3000",
          description: "Development server"
        },
        {
          url: "https://{defaultHost}",
          variables: {
            defaultHost: {
              default: "api.example.com"
            }
          },
          description: "Production server"
        }
      ],
      components: {
        securitySchemes: {
          bearer_auth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: "JWT"
          }
        },
        schemas: {
          Place: {
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
            }
          }
        }
      }
    }
  }

  config.openapi_format = :yaml
end
