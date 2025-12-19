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
  # @param options [Hash] 추가 옵션 (include_graph_info: true로 노선 좌표 포함)
  # @return [Hash] 경로 정보
  def self.search_route(start_lat:, start_lng:, end_lat:, end_lng:, **options)
    response = get(
      "/searchPubTransPathT",
      query: build_query(start_lat, start_lng, end_lat, end_lng, options),
      timeout: 10
    )

    if response.success?
      result = parse_response(response.parsed_response)

      # 노선 그래프 정보 포함 옵션
      if options[:include_graph_info] && result[:paths].present?
        result[:paths] = result[:paths].map do |path|
          add_graph_info(path, start_lat: start_lat, start_lng: start_lng, end_lat: end_lat, end_lng: end_lng)
        end
      end

      result
    else
      Rails.logger.error "ODsay API Error: #{response.code} - #{response.body}"
      { error: "Failed to fetch transit route", code: response.code }
    end
  rescue StandardError => e
    Rails.logger.error "ODsay Transit Service Error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    { error: "Internal error occurred", message: e.message }
  end

  # loadLane API: 노선 그래픽 데이터 조회
  # @param map_obj [String] searchPubTransPathT에서 받은 mapObj 값
  # @return [Hash] 노선 좌표 정보
  def self.load_lane(map_obj)
    response = get(
      "/loadLane",
      query: { apiKey: api_key, mapObject: map_obj },
      timeout: 10
    )

    if response.success?
      parse_lane_response(response.parsed_response)
    else
      Rails.logger.error "ODsay loadLane API Error: #{response.code} - #{response.body}"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "ODsay loadLane Error: #{e.message}"
    nil
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

  # loadLane API 응답 파싱
  def self.parse_lane_response(response)
    return nil if response["error"].present?

    result = response["result"]
    return nil if result.nil? || result["lane"].nil?

    result["lane"].map do |lane|
      {
        class_type: lane["class"],  # 1: 지하철, 2: 버스
        type: lane["type"],
        section: parse_lane_section(lane["section"])
      }
    end
  end

  # 노선 구간별 좌표 파싱
  def self.parse_lane_section(sections)
    return [] if sections.nil?

    sections.map do |section|
      {
        start_name: section["startName"],
        end_name: section["endName"],
        graph_pos: parse_graph_pos(section["graphPos"])
      }
    end
  end

  # 좌표를 배열로 변환 ([{x:, y:}, ...] -> [[lng, lat], ...])
  def self.parse_graph_pos(graph_pos)
    return [] if graph_pos.blank?

    # graphPos가 객체 배열인 경우: [{x: lng, y: lat}, ...]
    if graph_pos.is_a?(Array) && graph_pos.first.is_a?(Hash)
      return graph_pos.map { |coord| [ coord["x"].to_f, coord["y"].to_f ] }
    end

    # graphPos가 문자열인 경우: "x1 y1 x2 y2 ..."
    if graph_pos.is_a?(String)
      coords = graph_pos.strip.split(/\s+/)
      return coords.each_slice(2).map { |lng, lat| [ lng.to_f, lat.to_f ] }
    end

    []
  end

  # 경로에 노선 그래프 정보 추가 (각 subPath별로)
  def self.add_graph_info(path, start_lat:, start_lng:, end_lat:, end_lng:)
    return path if path[:sub_paths].blank?

    # 각 구간에 그래프 정보 추가 (도보 제외)
    path[:sub_paths] = path[:sub_paths].map do |sub_path|
      add_sub_path_graph(sub_path)
    end

    path
  end

  # 도보 구간의 출발/도착 좌표를 인접 구간에서 추론
  def self.infer_walking_coordinates(sub_paths, origin_lat:, origin_lng:, dest_lat:, dest_lng:)
    sub_paths.each_with_index do |sub_path, i|
      next unless sub_path[:traffic_type] == 3  # 도보만

      # 첫 번째 도보 구간: 출발지 → 첫 대중교통
      if i == 0
        sub_path[:start_x] = origin_lng
        sub_path[:start_y] = origin_lat
      # 이전 구간 (대중교통)의 도착지 = 도보의 출발지
      elsif i > 0
        prev = sub_paths[i - 1]
        if prev[:end_x].present?
          sub_path[:start_x] = prev[:end_x]
          sub_path[:start_y] = prev[:end_y]
        end
      end

      # 마지막 도보 구간: 마지막 대중교통 → 목적지
      if i == sub_paths.length - 1
        sub_path[:end_x] = dest_lng
        sub_path[:end_y] = dest_lat
      # 다음 구간 (대중교통)의 출발지 = 도보의 도착지
      elsif i < sub_paths.length - 1
        next_sub = sub_paths[i + 1]
        if next_sub[:start_x].present?
          sub_path[:end_x] = next_sub[:start_x]
          sub_path[:end_y] = next_sub[:start_y]
        end
      end
    end

    sub_paths
  end

  # subPath에 그래프 정보 추가
  def self.add_sub_path_graph(sub_path)
    # 도보(3)는 그래프 정보 없음
    return sub_path if sub_path[:traffic_type] == 3

    lane_info = sub_path[:lane]&.first
    return sub_path if lane_info.nil?

    # 1. ODsay loadLane API 시도 (지하철/버스)
    map_obj = build_map_object(sub_path, lane_info)
    if map_obj.present?
      graph_info = load_lane(map_obj)
      if graph_info.present?
        coords = extract_coords_from_graph(graph_info)
        if coords.present?
          sub_path[:graph_pos] = coords
          return sub_path
        end
      end
    end

    # 2. loadLane 실패 시 (특히 버스) 네이버 Directions API로 도로 경로 가져오기
    if sub_path[:start_x].present? && sub_path[:end_x].present?
      road_coords = fetch_road_path(sub_path)
      sub_path[:graph_pos] = road_coords if road_coords.present?
    end

    sub_path
  end

  # 네이버 Directions API로 정류장 간 도로 경로 가져오기
  def self.fetch_road_path(sub_path)
    result = NaverDirectionsService.search_route(
      start_lat: sub_path[:start_y],
      start_lng: sub_path[:start_x],
      end_lat: sub_path[:end_y],
      end_lng: sub_path[:end_x]
    )

    return nil if result[:error].present? || result[:path].blank?

    # 네이버 Directions path는 [[lng, lat], ...] 형식
    result[:path]
  rescue StandardError => e
    Rails.logger.error "Failed to fetch road path: #{e.message}"
    nil
  end

  # loadLane API용 mapObject 문자열 생성
  def self.build_map_object(sub_path, lane_info)
    traffic_type = sub_path[:traffic_type]
    start_id = sub_path[:start_id]
    end_id = sub_path[:end_id]

    return nil if start_id.nil? || end_id.nil?

    if traffic_type == 1  # 지하철
      subway_code = lane_info[:subway_code]
      return nil if subway_code.nil?
      "0:0@#{subway_code}:2:#{start_id}:#{end_id}"
    elsif traffic_type == 2  # 버스
      bus_id = lane_info[:bus_id]
      return nil if bus_id.nil?
      "0:0@#{bus_id}:1:#{start_id}:#{end_id}"
    end
  end

  # graph_info에서 좌표 배열 추출
  def self.extract_coords_from_graph(graph_info)
    return [] if graph_info.blank?

    coords = []
    graph_info.each do |lane|
      lane[:section]&.each do |section|
        coords.concat(section[:graph_pos]) if section[:graph_pos].present?
      end
    end
    coords
  end

  def self.parse_path(path)
    info = path["info"]
    sub_paths = path["subPath"]&.map { |sub| parse_sub_path(sub) } || []

    {
      path_type: path["pathType"],  # 1: 지하철, 2: 버스, 3: 버스+지하철
      map_obj: info["mapObj"],  # loadLane API 호출용 값
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
      start_id: sub["startID"],  # 출발 정류장/역 ID (loadLane용)
      end_id: sub["endID"],  # 도착 정류장/역 ID (loadLane용)
      start_name: sub["startName"],
      start_x: sub["startX"],
      start_y: sub["startY"],
      end_name: sub["endName"],
      end_x: sub["endX"],
      end_y: sub["endY"],
      # 경유 정류장 목록 (지도에 경로 표시용)
      pass_stop_list: parse_pass_stop_list(sub["passStopList"]),
      # 도보인 경우
      way: sub["way"],
      way_code: sub["wayCode"]
    }.compact
  end

  def self.parse_pass_stop_list(pass_stop_list)
    return nil if pass_stop_list.nil? || pass_stop_list["stations"].nil?

    pass_stop_list["stations"].map do |station|
      {
        index: station["index"],
        station_name: station["stationName"],
        x: station["x"].to_f,
        y: station["y"].to_f,
        is_non_stop: station["isNonStop"]
      }
    end
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
