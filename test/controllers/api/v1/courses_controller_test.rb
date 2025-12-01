require "test_helper"
require "minitest/mock"

class Api::V1::CoursesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:user)
    @other_user = create(:user)

    # 테스트용 장소 생성 (서로 다른 좌표)
    @place1 = create(:place, user: @user, name: "서울역", latitude: 37.5546, longitude: 126.9706)
    @place2 = create(:place, user: @user, name: "강남역", latitude: 37.4979, longitude: 127.0276)
    @place3 = create(:place, user: @user, name: "잠실역", latitude: 37.5133, longitude: 127.1001)

    # 테스트용 코스 생성
    @course = create(:course, user: @user, name: "서울 투어")
    create(:course_place, course: @course, place: @place1, position: 0)
    create(:course_place, course: @course, place: @place2, position: 1)
    create(:course_place, course: @course, place: @place3, position: 2)

    # 장소가 1개인 코스
    @single_place_course = create(:course, user: @user, name: "한 장소 코스")
    create(:course_place, course: @single_place_course, place: @place1, position: 0)
  end

  # === 코스 경로 검색 테스트 ===

  test "should return error without authentication" do
    get directions_api_v1_course_url(@course), params: { mode: "transit" }
    assert_response :unauthorized
  end

  test "should return error when mode is missing" do
    get directions_api_v1_course_url(@course),
        headers: auth_headers(@user)

    assert_response :bad_request
    json = JSON.parse(response.body)
    assert_includes json["error"], "mode"
  end

  test "should return error for invalid mode" do
    get directions_api_v1_course_url(@course),
        params: { mode: "bicycle" },
        headers: auth_headers(@user)

    assert_response :bad_request
    json = JSON.parse(response.body)
    assert_includes json["error"], "Invalid mode"
  end

  test "should return error for course with only one place" do
    mock_response = { count: 0, paths: [] }

    OdsayTransitService.stub :search_route, mock_response do
      get directions_api_v1_course_url(@single_place_course),
          params: { mode: "transit" },
          headers: auth_headers(@user)

      assert_response :unprocessable_entity
      json = JSON.parse(response.body)
      assert_includes json["error"], "at least 2 places"
    end
  end

  test "should return error for course not found" do
    get directions_api_v1_course_url(id: 99999),
        params: { mode: "transit" },
        headers: auth_headers(@user)

    assert_response :not_found
  end

  test "should return error for other users course" do
    other_course = create(:course, user: @other_user)

    get directions_api_v1_course_url(other_course),
        params: { mode: "transit" },
        headers: auth_headers(@user)

    assert_response :not_found
  end

  test "should return transit directions for course" do
    mock_response = {
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
    }

    OdsayTransitService.stub :search_route, mock_response do
      get directions_api_v1_course_url(@course),
          params: { mode: "transit" },
          headers: auth_headers(@user)

      assert_response :success
      json = JSON.parse(response.body)

      assert_equal @course.id, json["course_id"]
      assert_equal "서울 투어", json["course_name"]
      assert_equal "transit", json["mode"]
      assert_equal 2, json["total_segments"]  # 3개 장소 → 2개 구간

      # 구간 확인
      segments = json["segments"]
      assert_equal 2, segments.length

      # 첫 번째 구간: 서울역 → 강남역
      assert_equal "서울역", segments[0]["from"]["name"]
      assert_equal "강남역", segments[0]["to"]["name"]

      # 두 번째 구간: 강남역 → 잠실역
      assert_equal "강남역", segments[1]["from"]["name"]
      assert_equal "잠실역", segments[1]["to"]["name"]

      # 요약 정보
      assert json["summary"].present?
      assert_equal 50, json["summary"]["total_time"]  # 25분 * 2구간
    end
  end

  test "should return driving directions for course" do
    mock_response = {
      summary: {
        distance: 9500,
        duration: 1200000,
        duration_minutes: 20.0,
        toll_fare: 1000,
        fuel_price: 1500
      },
      sections: [],
      path: []
    }

    NaverDirectionsService.stub :search_route, mock_response do
      get directions_api_v1_course_url(@course),
          params: { mode: "driving" },
          headers: auth_headers(@user)

      assert_response :success
      json = JSON.parse(response.body)

      assert_equal "driving", json["mode"]
      assert_equal 2, json["total_segments"]

      # 요약 정보 확인
      summary = json["summary"]
      assert summary.present?
      assert_equal 19000, summary["total_distance"]  # 9500 * 2
      assert_equal 2000, summary["total_toll_fare"]  # 1000 * 2
    end
  end

  private

  def auth_headers(user)
    token = JsonWebToken.encode(user_id: user.id)
    { "Authorization" => "Bearer #{token}" }
  end
end
