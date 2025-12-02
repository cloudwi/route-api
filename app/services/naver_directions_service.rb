# 네이버 Directions 5 API 서비스
# 출발지와 도착지 좌표를 기반으로 자동차 경로를 검색
class NaverDirectionsService
  include HTTParty
  base_uri "https://maps.apigw.ntruss.com/map-direction/v1"

  # 경로 옵션 상수
  OPTIONS = {
    fastest: "trafast",      # 실시간 빠른길
    comfortable: "tracomfort",  # 실시간 편한길
    optimal: "traoptimal",    # 실시간 최적
    avoid_toll: "traavoidtoll",  # 무료 우선
    avoid_car_only: "traavoidcaronly"  # 자동차 전용도로 회피
  }.freeze

  # 자동차 경로 검색
  # @param start_lat [Float] 출발지 위도
  # @param start_lng [Float] 출발지 경도
  # @param end_lat [Float] 도착지 위도
  # @param end_lng [Float] 도착지 경도
  # @param options [Hash] 추가 옵션 (waypoints, option, cartype 등)
  # @return [Hash] 경로 정보
  def self.search_route(start_lat:, start_lng:, end_lat:, end_lng:, **options)
    response = get(
      "/driving",
      query: build_query(start_lat, start_lng, end_lat, end_lng, options),
      headers: headers,
      timeout: 10
    )

    if response.success?
      parse_response(response.parsed_response)
    else
      Rails.logger.error "Naver Directions API Error: #{response.code} - #{response.body}"
      { error: "Failed to fetch driving route", code: response.code }
    end
  rescue StandardError => e
    Rails.logger.error "Naver Directions Service Error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    { error: "Internal error occurred", message: e.message }
  end

  private

  def self.headers
    {
      "X-NCP-APIGW-API-KEY-ID" => client_id,
      "X-NCP-APIGW-API-KEY" => client_secret
    }
  end

  def self.client_id
    Rails.application.credentials.dig(Rails.env.to_sym, :naver_cloud, :client_id)
  end

  def self.client_secret
    Rails.application.credentials.dig(Rails.env.to_sym, :naver_cloud, :client_secret)
  end

  def self.build_query(start_lat, start_lng, end_lat, end_lng, options)
    query = {
      start: "#{start_lng},#{start_lat}",  # 경도,위도 순서
      goal: "#{end_lng},#{end_lat}",
      option: OPTIONS[options[:route_option]&.to_sym] || OPTIONS[:optimal]
    }

    # 경유지 처리 (최대 5개)
    if options[:waypoints].present?
      waypoints = options[:waypoints].take(5).map do |wp|
        "#{wp[:lng]},#{wp[:lat]}"
      end.join("|")
      query[:waypoints] = waypoints
    end

    # 차량 타입 (1: 일반, 2: 소형, 3: 중형, 4: 대형, 5: 이륜, 6: 경차)
    query[:cartype] = options[:car_type] if options[:car_type].present?

    # 연료 타입 (gasoline, diesel, lpg)
    query[:fueltype] = options[:fuel_type] if options[:fuel_type].present?

    query
  end

  def self.parse_response(response)
    # 에러 응답 처리
    if response["code"] != 0
      return {
        error: response["message"] || "Route search failed",
        code: response["code"]
      }
    end

    route = response.dig("route", "traoptimal", 0) ||
            response.dig("route", "trafast", 0) ||
            response.dig("route", "tracomfort", 0) ||
            response.dig("route")&.values&.first&.first

    return { error: "No route found", paths: [] } if route.nil?

    parse_route(route)
  end

  def self.parse_route(route)
    summary = route["summary"]
    sections = route["section"]&.map { |section| parse_section(section) } || []

    {
      summary: {
        start: parse_location(summary["start"]),
        goal: parse_location(summary["goal"]),
        waypoints: summary["waypoints"]&.map { |wp| parse_location(wp) } || [],
        distance: summary["distance"],  # 총 거리 (m)
        duration: summary["duration"],  # 총 소요시간 (ms)
        duration_minutes: (summary["duration"] / 60_000.0).round,  # 분 단위 (정수)
        departure_time: summary["departureTime"],
        bbox: summary["bbox"],  # 경로 바운딩 박스
        toll_fare: summary["tollFare"],  # 통행료
        taxi_fare: summary["taxiFare"],  # 예상 택시비
        fuel_price: summary["fuelPrice"]  # 예상 유류비
      },
      sections: sections,
      path: route["path"]  # 경로 좌표 배열 [[lng, lat], ...]
    }
  end

  def self.parse_location(location)
    return nil if location.nil?
    {
      location: location["location"],  # [lng, lat]
      dir: location["dir"]  # 방향
    }
  end

  def self.parse_section(section)
    {
      point_index: section["pointIndex"],
      point_count: section["pointCount"],
      distance: section["distance"],
      name: section["name"],
      congestion: section["congestion"],  # 혼잡도 (0: 원활, 1: 서행, 2: 지체, 3: 정체)
      speed: section["speed"]
    }
  end
end
