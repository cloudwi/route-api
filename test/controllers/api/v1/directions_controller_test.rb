require "test_helper"
require "minitest/mock"

class Api::V1::DirectionsControllerTest < ActionDispatch::IntegrationTest
  # 테스트 좌표 (서울역 -> 강남역)
  SEOUL_STATION = { lat: 37.5546, lng: 126.9706 }.freeze
  GANGNAM_STATION = { lat: 37.4979, lng: 127.0276 }.freeze

  # === 파라미터 검증 테스트 ===

  test "should return error when start_lat is missing" do
    get api_v1_directions_url, params: {
      start_lng: SEOUL_STATION[:lng],
      end_lat: GANGNAM_STATION[:lat],
      end_lng: GANGNAM_STATION[:lng],
      mode: "transit"
    }

    assert_response :bad_request
    json = JSON.parse(response.body)
    assert_includes json["error"], "start_lat"
  end

  test "should return error when mode is missing" do
    get api_v1_directions_url, params: {
      start_lat: SEOUL_STATION[:lat],
      start_lng: SEOUL_STATION[:lng],
      end_lat: GANGNAM_STATION[:lat],
      end_lng: GANGNAM_STATION[:lng]
    }

    assert_response :bad_request
    json = JSON.parse(response.body)
    assert_includes json["error"], "mode"
  end

  test "should return error for invalid mode" do
    get api_v1_directions_url, params: {
      start_lat: SEOUL_STATION[:lat],
      start_lng: SEOUL_STATION[:lng],
      end_lat: GANGNAM_STATION[:lat],
      end_lng: GANGNAM_STATION[:lng],
      mode: "bicycle"
    }

    assert_response :bad_request
    json = JSON.parse(response.body)
    assert_includes json["error"], "Invalid mode"
  end

  test "should return error for coordinates outside Korean peninsula" do
    get api_v1_directions_url, params: {
      start_lat: 50.0,  # 한국 영역 밖
      start_lng: SEOUL_STATION[:lng],
      end_lat: GANGNAM_STATION[:lat],
      end_lng: GANGNAM_STATION[:lng],
      mode: "transit"
    }

    assert_response :bad_request
    json = JSON.parse(response.body)
    assert_includes json["error"], "Latitude"
  end

  # === 대중교통 경로 검색 테스트 (Mock) ===

  test "should call OdsayTransitService for transit mode" do
    mock_response = {
      search_type: 0,
      count: 1,
      paths: [
        {
          path_type: 3,
          total_time: 25,
          total_distance: 8500,
          payment: 1400,
          transfer_count: 1
        }
      ]
    }

    OdsayTransitService.stub :search_route, mock_response do
      get api_v1_directions_url, params: {
        start_lat: SEOUL_STATION[:lat],
        start_lng: SEOUL_STATION[:lng],
        end_lat: GANGNAM_STATION[:lat],
        end_lng: GANGNAM_STATION[:lng],
        mode: "transit"
      }

      assert_response :success
      json = JSON.parse(response.body)
      assert_equal "transit", json["mode"]
      assert_equal 1, json["result"]["count"]
    end
  end

  test "should accept path_type parameter for transit mode" do
    mock_response = { count: 0, paths: [] }

    OdsayTransitService.stub :search_route, mock_response do
      get api_v1_directions_url, params: {
        start_lat: SEOUL_STATION[:lat],
        start_lng: SEOUL_STATION[:lng],
        end_lat: GANGNAM_STATION[:lat],
        end_lng: GANGNAM_STATION[:lng],
        mode: "transit",
        path_type: 1  # 지하철만
      }

      assert_response :success
    end
  end

  # === 자동차 경로 검색 테스트 (Mock) ===

  test "should call NaverDirectionsService for driving mode" do
    mock_response = {
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
    }

    NaverDirectionsService.stub :search_route, mock_response do
      get api_v1_directions_url, params: {
        start_lat: SEOUL_STATION[:lat],
        start_lng: SEOUL_STATION[:lng],
        end_lat: GANGNAM_STATION[:lat],
        end_lng: GANGNAM_STATION[:lng],
        mode: "driving"
      }

      assert_response :success
      json = JSON.parse(response.body)
      assert_equal "driving", json["mode"]
      assert json["result"]["summary"].present?
    end
  end

  test "should accept route_option parameter for driving mode" do
    mock_response = { summary: {}, sections: [], path: [] }

    NaverDirectionsService.stub :search_route, mock_response do
      get api_v1_directions_url, params: {
        start_lat: SEOUL_STATION[:lat],
        start_lng: SEOUL_STATION[:lng],
        end_lat: GANGNAM_STATION[:lat],
        end_lng: GANGNAM_STATION[:lng],
        mode: "driving",
        route_option: "fastest"
      }

      assert_response :success
    end
  end

  test "should accept waypoints parameter for driving mode" do
    mock_response = { summary: {}, sections: [], path: [] }
    waypoints = [ { lat: 37.52, lng: 127.0 } ].to_json

    NaverDirectionsService.stub :search_route, mock_response do
      get api_v1_directions_url, params: {
        start_lat: SEOUL_STATION[:lat],
        start_lng: SEOUL_STATION[:lng],
        end_lat: GANGNAM_STATION[:lat],
        end_lng: GANGNAM_STATION[:lng],
        mode: "driving",
        waypoints: waypoints
      }

      assert_response :success
    end
  end

  # === 에러 핸들링 테스트 ===

  test "should return error when external API fails" do
    error_response = { error: "API call failed" }

    OdsayTransitService.stub :search_route, error_response do
      get api_v1_directions_url, params: {
        start_lat: SEOUL_STATION[:lat],
        start_lng: SEOUL_STATION[:lng],
        end_lat: GANGNAM_STATION[:lat],
        end_lng: GANGNAM_STATION[:lng],
        mode: "transit"
      }

      assert_response :unprocessable_entity
      json = JSON.parse(response.body)
      assert json["error"].present?
    end
  end

  # === 응답 형식 테스트 ===

  test "should include start and destination in response" do
    mock_response = { count: 0, paths: [] }

    OdsayTransitService.stub :search_route, mock_response do
      get api_v1_directions_url, params: {
        start_lat: SEOUL_STATION[:lat],
        start_lng: SEOUL_STATION[:lng],
        end_lat: GANGNAM_STATION[:lat],
        end_lng: GANGNAM_STATION[:lng],
        mode: "transit"
      }

      assert_response :success
      json = JSON.parse(response.body)

      assert_equal SEOUL_STATION[:lat], json["start"]["lat"]
      assert_equal SEOUL_STATION[:lng], json["start"]["lng"]
      assert_equal GANGNAM_STATION[:lat], json["destination"]["lat"]
      assert_equal GANGNAM_STATION[:lng], json["destination"]["lng"]
    end
  end
end
