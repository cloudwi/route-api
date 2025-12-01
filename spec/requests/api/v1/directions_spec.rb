# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Directions API", type: :request do
  # 테스트용 사용자 및 토큰 생성
  let(:user) { User.create!(provider: "kakao", uid: "test_directions", name: "Test User", email: "test@test.com") }
  let(:token) { JsonWebToken.encode(user_id: user.id) }
  let(:Authorization) { "Bearer #{token}" }

  path "/api/v1/directions" do
    get "경로 검색" do
      tags "경로 검색"
      description "대중교통(ODsay) 또는 자동차(Naver Directions) 경로를 검색합니다"
      produces "application/json"
      security [ bearer_auth: [] ]

      parameter name: :start_lat, in: :query, type: :number, required: true,
                description: "출발지 위도 (예: 37.5546)"
      parameter name: :start_lng, in: :query, type: :number, required: true,
                description: "출발지 경도 (예: 126.9706)"
      parameter name: :end_lat, in: :query, type: :number, required: true,
                description: "도착지 위도 (예: 37.4979)"
      parameter name: :end_lng, in: :query, type: :number, required: true,
                description: "도착지 경도 (예: 127.0276)"
      parameter name: :mode, in: :query, type: :string, required: true,
                enum: %w[transit driving],
                description: "이동 수단 (transit: 대중교통, driving: 자동차)"

      # 대중교통 옵션
      parameter name: :path_type, in: :query, type: :integer, required: false,
                enum: [ 0, 1, 2 ],
                description: "[대중교통] 경로 유형 (0: 모두, 1: 지하철, 2: 버스)"

      # 자동차 옵션
      parameter name: :route_option, in: :query, type: :string, required: false,
                enum: %w[fastest comfortable optimal avoid_toll avoid_car_only],
                description: "[자동차] 경로 옵션 (fastest: 빠른길, comfortable: 편한길, optimal: 최적, avoid_toll: 무료우선, avoid_car_only: 자동차전용도로 회피)"
      parameter name: :car_type, in: :query, type: :integer, required: false,
                enum: [ 1, 2, 3, 4, 5, 6 ],
                description: "[자동차] 차량 타입 (1: 일반, 2: 소형, 3: 중형, 4: 대형, 5: 이륜, 6: 경차)"
      parameter name: :waypoints, in: :query, type: :string, required: false,
                description: '[자동차] 경유지 JSON 배열 (예: [{"lat":37.52,"lng":127.0}], 최대 5개)'

      response "200", "대중교통 경로 검색 성공" do
        schema type: :object,
               properties: {
                 mode: { type: :string, description: "이동 수단" },
                 start: {
                   type: :object,
                   properties: {
                     lat: { type: :number, description: "출발지 위도" },
                     lng: { type: :number, description: "출발지 경도" }
                   }
                 },
                 destination: {
                   type: :object,
                   properties: {
                     lat: { type: :number, description: "도착지 위도" },
                     lng: { type: :number, description: "도착지 경도" }
                   }
                 },
                 result: {
                   type: :object,
                   description: "경로 검색 결과 (mode에 따라 구조가 다름)",
                   properties: {
                     search_type: { type: :integer, description: "[대중교통] 검색 유형" },
                     count: { type: :integer, description: "[대중교통] 경로 수" },
                     paths: {
                       type: :array,
                       description: "[대중교통] 경로 목록",
                       items: {
                         type: :object,
                         properties: {
                           path_type: { type: :integer, description: "경로 유형 (1: 지하철, 2: 버스, 3: 버스+지하철)" },
                           total_time: { type: :integer, description: "총 소요시간 (분)" },
                           total_distance: { type: :integer, description: "총 거리 (m)" },
                           total_walk: { type: :integer, description: "총 도보 거리 (m)" },
                           transfer_count: { type: :integer, description: "환승 횟수" },
                           payment: { type: :integer, description: "총 요금" },
                           sub_paths: { type: :array, description: "세부 경로" }
                         }
                       }
                     },
                     summary: {
                       type: :object,
                       description: "[자동차] 경로 요약",
                       properties: {
                         distance: { type: :integer, description: "총 거리 (m)" },
                         duration: { type: :integer, description: "총 소요시간 (ms)" },
                         duration_minutes: { type: :number, description: "총 소요시간 (분)" },
                         toll_fare: { type: :integer, description: "통행료" },
                         taxi_fare: { type: :integer, description: "예상 택시비" },
                         fuel_price: { type: :integer, description: "예상 유류비" }
                       }
                     },
                     sections: { type: :array, description: "[자동차] 구간 정보" },
                     path: { type: :array, description: "[자동차] 경로 좌표 배열" }
                   }
                 }
               },
               required: %w[mode start destination result]

        let(:start_lat) { 37.5546 }
        let(:start_lng) { 126.9706 }
        let(:end_lat) { 37.4979 }
        let(:end_lng) { 127.0276 }
        let(:mode) { "transit" }

        before do
          allow(OdsayTransitService).to receive(:search_route).and_return({
            search_type: 0,
            count: 1,
            paths: [
              {
                path_type: 3,
                total_time: 25,
                total_distance: 8500,
                total_walk: 500,
                transfer_count: 1,
                payment: 1400,
                sub_paths: []
              }
            ]
          })
        end

        run_test!
      end

      response "200", "자동차 경로 검색 성공" do
        let(:start_lat) { 37.5546 }
        let(:start_lng) { 126.9706 }
        let(:end_lat) { 37.4979 }
        let(:end_lng) { 127.0276 }
        let(:mode) { "driving" }

        before do
          allow(NaverDirectionsService).to receive(:search_route).and_return({
            summary: {
              distance: 9500,
              duration: 1200000,
              duration_minutes: 20.0,
              toll_fare: 0,
              taxi_fare: 12000,
              fuel_price: 1500
            },
            sections: [],
            path: []
          })
        end

        run_test!
      end

      response "400", "필수 파라미터 누락" do
        schema type: :object,
               properties: {
                 error: { type: :string, description: "에러 메시지" },
                 mode: { type: :string, nullable: true }
               }

        let(:start_lat) { 37.5546 }
        let(:start_lng) { 126.9706 }
        let(:end_lat) { 37.4979 }
        let(:end_lng) { 127.0276 }
        let(:mode) { nil }

        run_test!
      end

      response "400", "잘못된 이동 수단" do
        let(:start_lat) { 37.5546 }
        let(:start_lng) { 126.9706 }
        let(:end_lat) { 37.4979 }
        let(:end_lng) { 127.0276 }
        let(:mode) { "bicycle" }

        run_test!
      end

      response "400", "잘못된 좌표" do
        let(:start_lat) { 50.0 }
        let(:start_lng) { 126.9706 }
        let(:end_lat) { 37.4979 }
        let(:end_lng) { 127.0276 }
        let(:mode) { "transit" }

        run_test!
      end

      response "401", "인증 실패" do
        let(:Authorization) { "" }
        let(:start_lat) { 37.5546 }
        let(:start_lng) { 126.9706 }
        let(:end_lat) { 37.4979 }
        let(:end_lng) { 127.0276 }
        let(:mode) { "transit" }

        run_test!
      end
    end
  end
end
