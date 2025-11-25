require 'swagger_helper'

RSpec.describe 'api/v1/search', type: :request do
  path '/api/v1/search' do
    get('장소 검색') do
      tags '장소 검색'
      description '네이버 로컬 검색 API를 통해 장소를 검색합니다'
      produces 'application/json'

      parameter name: :query, in: :query, type: :string, required: true, description: '검색 키워드 (예: "스타벅스 강남역")'
      parameter name: :display, in: :query, type: :integer, required: false, description: '검색 결과 개수 (1-5, 기본값: 5)'

      response(200, 'successful') do
        schema type: :object,
          properties: {
            query: { type: :string, description: '검색한 키워드' },
            count: { type: :integer, description: '검색 결과 개수' },
            places: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  title: { type: :string, description: '장소명' },
                  address: { type: :string, description: '지번 주소' },
                  road_address: { type: :string, description: '도로명 주소' },
                  category: { type: :string, description: '카테고리' },
                  telephone: { type: :string, description: '전화번호' },
                  latitude: { type: :number, format: :float, description: '위도 (WGS84)' },
                  longitude: { type: :number, format: :float, description: '경도 (WGS84)' },
                  link: { type: :string, description: '네이버 플레이스 링크' }
                }
              }
            }
          },
          required: ['query', 'count', 'places']

        let(:query) { '스타벅스 강남역' }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('query')
          expect(data).to have_key('count')
          expect(data).to have_key('places')
        end
      end

      response(400, 'query parameter missing') do
        schema type: :object,
          properties: {
            error: { type: :string },
            message: { type: :string }
          }

        let(:query) { nil }

        run_test!
      end
    end
  end
end
