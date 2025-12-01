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

  path "/api/v1/courses/{id}/directions" do
    parameter name: :id, in: :path, type: :integer, description: "코스 ID"

    get "코스 경로 검색" do
      tags "코스 관리"
      description "코스 내 장소들 간의 경로를 검색합니다. A → B → C 코스라면 A→B, B→C 경로를 모두 반환합니다."
      produces "application/json"
      security [ bearer_auth: [] ]

      parameter name: :mode, in: :query, type: :string, required: true,
                enum: %w[transit driving],
                description: "이동 수단 (transit: 대중교통, driving: 자동차)"

      response "200", "경로 검색 성공" do
        schema type: :object,
               properties: {
                 course_id: { type: :integer, description: "코스 ID" },
                 course_name: { type: :string, description: "코스 이름" },
                 mode: { type: :string, description: "이동 수단" },
                 total_segments: { type: :integer, description: "총 구간 수" },
                 segments: {
                   type: :array,
                   description: "구간별 경로 정보",
                   items: {
                     type: :object,
                     properties: {
                       segment: { type: :integer, description: "구간 번호" },
                       from: {
                         type: :object,
                         properties: {
                           name: { type: :string },
                           lat: { type: :number },
                           lng: { type: :number }
                         }
                       },
                       to: {
                         type: :object,
                         properties: {
                           name: { type: :string },
                           lat: { type: :number },
                           lng: { type: :number }
                         }
                       },
                       route: { type: :object, description: "경로 상세 정보" }
                     }
                   }
                 },
                 summary: {
                   type: :object,
                   description: "전체 경로 요약",
                   properties: {
                     total_time: { type: :integer, description: "[대중교통] 총 소요시간 (분)" },
                     total_time_text: { type: :string, description: "[대중교통] 총 소요시간 텍스트" },
                     total_distance: { type: :integer, description: "총 거리 (m)" },
                     total_distance_text: { type: :string, description: "총 거리 텍스트" },
                     total_payment: { type: :integer, description: "[대중교통] 총 요금" },
                     total_duration_minutes: { type: :number, description: "[자동차] 총 소요시간 (분)" },
                     total_toll_fare: { type: :integer, description: "[자동차] 총 통행료" },
                     total_fuel_price: { type: :integer, description: "[자동차] 총 유류비" }
                   }
                 }
               },
               required: %w[course_id course_name mode total_segments segments summary]

        let(:place1) { Place.create!(user: user, naver_place_id: "p1", name: "서울역", latitude: 37.5546, longitude: 126.9706, address: "서울") }
        let(:place2) { Place.create!(user: user, naver_place_id: "p2", name: "강남역", latitude: 37.4979, longitude: 127.0276, address: "강남") }
        let(:course) do
          c = Course.create!(user: user, name: "테스트 코스")
          c.course_places.create!(place: place1, position: 0)
          c.course_places.create!(place: place2, position: 1)
          c
        end
        let(:id) { course.id }
        let(:mode) { "transit" }

        before do
          allow(OdsayTransitService).to receive(:search_route).and_return({
            search_type: 0,
            count: 1,
            paths: [ { path_type: 3, total_time: 25, total_distance: 8500, payment: 1400, sub_paths: [] } ]
          })
        end

        run_test!
      end

      response "400", "잘못된 이동 수단" do
        let(:course) { Course.create!(user: user, name: "테스트") }
        let(:id) { course.id }
        let(:mode) { "bicycle" }
        run_test!
      end

      response "404", "코스 없음" do
        let(:id) { 99999 }
        let(:mode) { "transit" }
        run_test!
      end

      response "422", "장소가 2개 미만" do
        let(:place1) { Place.create!(user: user, naver_place_id: "p1", name: "서울역", latitude: 37.5546, longitude: 126.9706, address: "서울") }
        let(:course) do
          c = Course.create!(user: user, name: "한 장소 코스")
          c.course_places.create!(place: place1, position: 0)
          c
        end
        let(:id) { course.id }
        let(:mode) { "transit" }
        run_test!
      end
    end
  end
end
