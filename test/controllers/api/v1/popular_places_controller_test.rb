require "test_helper"

class Api::V1::PopularPlacesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:user)

    # 테스트용 장소 생성 (가중치: views_count * 1 + likes_count * 3)
    @place1 = create(:place, user: @user, name: "인기장소1", views_count: 100, likes_count: 50)  # 250
    @place2 = create(:place, user: @user, name: "인기장소2", views_count: 200, likes_count: 10)  # 230
    @place3 = create(:place, user: @user, name: "인기장소3", views_count: 50, likes_count: 100)  # 350
  end

  test "should get popular places without authentication" do
    get api_v1_popular_places_url
    assert_response :success

    json = JSON.parse(response.body)
    assert json["places"].is_a?(Array)
    assert json["places"].length <= 5
  end

  test "should return places sorted by popularity score" do
    get api_v1_popular_places_url
    assert_response :success

    json = JSON.parse(response.body)
    places = json["places"]

    # 순서: place3(350) > place1(250) > place2(230)
    assert_equal "인기장소3", places[0]["name"]
    assert_equal "인기장소1", places[1]["name"]
    assert_equal "인기장소2", places[2]["name"]
  end

  test "should return popularity score in response" do
    get api_v1_popular_places_url
    assert_response :success

    json = JSON.parse(response.body)
    places = json["places"]

    assert places[0]["popularityScore"].present?
    assert_equal 350, places[0]["popularityScore"]
  end

  test "should limit results to 5 places" do
    # 추가 장소 생성
    6.times do |i|
      create(:place, user: @user, name: "추가장소#{i}", views_count: 10, likes_count: 10)
    end

    get api_v1_popular_places_url
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 5, json["places"].length
  end

  test "should return place details" do
    get api_v1_popular_places_url
    assert_response :success

    json = JSON.parse(response.body)
    place = json["places"].first

    assert place.key?("id")
    assert place.key?("name")
    assert place.key?("viewsCount")
    assert place.key?("likesCount")
    assert place.key?("popularityScore")
  end
end
