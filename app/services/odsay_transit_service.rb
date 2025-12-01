# ODsay 대중교통 길찾기 API 서비스
# 출발지와 도착지 좌표를 기반으로 대중교통 경로를 검색
class OdsayTransitService
  include HTTParty
  base_uri "https://api.odsay.com/v1/api"

  # 대중교통 경로 검색
  # @param start_lat [Float] 출발지 위도
  # @param start_lng [Float] 출발지 경도
  # @param end_lat [Float] 도착지 위도
  # @param end_lng [Float] 도착지 경도
  # @param options [Hash] 추가 옵션
  # @return [Hash] 경로 정보
  def self.search_route(start_lat:, start_lng:, end_lat:, end_lng:, **options)
    response = get(
      "/searchPubTransPathT",
      query: build_query(start_lat, start_lng, end_lat, end_lng, options),
      timeout: 10
    )

    if response.success?
      parse_response(response.parsed_response)
    else
      Rails.logger.error "ODsay API Error: #{response.code} - #{response.body}"
      { error: "Failed to fetch transit route", code: response.code }
    end
  rescue StandardError => e
    Rails.logger.error "ODsay Transit Service Error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    { error: "Internal error occurred", message: e.message }
  end

  private

  def self.build_query(start_lat, start_lng, end_lat, end_lng, options)
    {
      apiKey: api_key,
      SX: start_lng,  # 출발지 경도
      SY: start_lat,  # 출발지 위도
      EX: end_lng,    # 도착지 경도
      EY: end_lat,    # 도착지 위도
      OPT: options[:sort_type] || 0,  # 0: 추천경로, 1: 타입별 정렬
      SearchType: options[:search_type] || 0,  # 0: 도시내
      SearchPathType: options[:path_type] || 0  # 0: 모두, 1: 지하철, 2: 버스
    }
  end

  def self.api_key
    Rails.application.credentials.dig(Rails.env.to_sym, :odsay, :api_key)
  end

  def self.parse_response(response)
    # ODsay 에러 응답 처리: {"error": [{"code": "500", "message": "..."}]}
    if response["error"].present?
      error_info = response["error"]
      error_msg = if error_info.is_a?(Array)
        error_info.first&.dig("message") || "Unknown error"
      else
        error_info["msg"] || "Unknown error"
      end
      return { error: error_msg, paths: [] }
    end

    result = response["result"]

    # 결과 없음 처리
    if result.nil? || result["path"].nil?
      return { error: "No route found", paths: [] }
    end

    paths = result["path"].map { |path| parse_path(path) }

    {
      search_type: result["searchType"],  # 도시내/도시간
      count: paths.length,
      paths: paths
    }
  end

  def self.parse_path(path)
    info = path["info"]
    sub_paths = path["subPath"]&.map { |sub| parse_sub_path(sub) } || []

    {
      path_type: path["pathType"],  # 1: 지하철, 2: 버스, 3: 버스+지하철
      total_time: info["totalTime"],  # 총 소요시간 (분)
      total_distance: info["totalDistance"],  # 총 거리 (m)
      total_walk: info["totalWalk"],  # 총 도보 거리 (m)
      total_walk_time: info["totalWalkTime"],  # 총 도보 시간 (분)
      transfer_count: info["busTransitCount"].to_i + info["subwayTransitCount"].to_i - 1,
      bus_transit_count: info["busTransitCount"],
      subway_transit_count: info["subwayTransitCount"],
      payment: info["payment"],  # 총 요금
      first_start_station: info["firstStartStation"],
      last_end_station: info["lastEndStation"],
      sub_paths: sub_paths
    }
  end

  def self.parse_sub_path(sub)
    {
      traffic_type: sub["trafficType"],  # 1: 지하철, 2: 버스, 3: 도보
      distance: sub["distance"],  # 거리 (m)
      section_time: sub["sectionTime"],  # 소요시간 (분)
      station_count: sub["stationCount"],  # 정거장 수
      # 대중교통인 경우
      lane: parse_lane(sub["lane"]),
      start_name: sub["startName"],
      start_x: sub["startX"],
      start_y: sub["startY"],
      end_name: sub["endName"],
      end_x: sub["endX"],
      end_y: sub["endY"],
      # 도보인 경우
      way: sub["way"],
      way_code: sub["wayCode"]
    }.compact
  end

  def self.parse_lane(lanes)
    return nil if lanes.nil?

    lanes.map do |lane|
      {
        name: lane["name"],
        bus_no: lane["busNo"],
        type: lane["type"],
        bus_id: lane["busID"],
        subway_code: lane["subwayCode"]
      }.compact
    end
  end
end
