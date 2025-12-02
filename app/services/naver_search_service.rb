# 네이버 로컬 검색 API를 호출하는 서비스 클래스
# 장소 검색 후 결과를 표준화된 형식으로 변환
class NaverSearchService
  include HTTParty

  # 네이버 검색 API로 장소를 검색합니다
  # 로컬 검색 결과가 없으면 주소 검색(Geocoding)도 시도합니다
  # @param query [String] 검색 키워드 (예: "스타벅스 강남역" 또는 "언남길 71")
  # @param display [Integer] 검색 결과 개수 (기본: 5, 최대: 5)
  # @return [Array<Hash>] 검색 결과 배열
  def self.search_places(query:, display: 5)
    # 1. 로컬 검색 (상호명/장소명)
    local_results = search_local(query: query, display: display)

    # 2. 로컬 검색 결과가 없으면 주소 검색(Geocoding) 시도
    if local_results.empty?
      geocode_results = search_address(query: query)
      return geocode_results
    end

    local_results
  rescue StandardError => e
    Rails.logger.error "Naver Search Service Error: #{e.message}"
    []
  end

  # 로컬 검색 API (상호명/장소명 검색)
  def self.search_local(query:, display: 5)
    response = HTTParty.get(
      "https://openapi.naver.com/v1/search/local.json",
      query: { query: query, display: display },
      headers: {
        "X-Naver-Client-Id" => Rails.application.credentials.dig(Rails.env.to_sym, :naver, :client_id),
        "X-Naver-Client-Secret" => Rails.application.credentials.dig(Rails.env.to_sym, :naver, :client_secret)
      }
    )

    if response.success?
      parse_local_response(response.parsed_response)
    else
      Rails.logger.error "Naver Local API Error: #{response.code} - #{response.message}"
      []
    end
  end

  # Geocoding API (주소 검색)
  def self.search_address(query:)
    response = HTTParty.get(
      "https://maps.apigw.ntruss.com/map-geocode/v2/geocode",
      query: { query: query },
      headers: {
        "X-NCP-APIGW-API-KEY-ID" => Rails.application.credentials.dig(Rails.env.to_sym, :naver_cloud, :client_id),
        "X-NCP-APIGW-API-KEY" => Rails.application.credentials.dig(Rails.env.to_sym, :naver_cloud, :client_secret)
      }
    )

    if response.success?
      parse_geocode_response(response.parsed_response)
    else
      Rails.logger.error "Naver Geocode API Error: #{response.code} - #{response.body}"
      []
    end
  end

  private

  # 로컬 검색 API 응답을 표준 Place 형식으로 변환
  def self.parse_local_response(response)
    items = response["items"] || []

    items.map do |item|
      latitude = convert_coordinate(item["mapy"])
      longitude = convert_coordinate(item["mapx"])

      {
        title: remove_html_tags(item["title"]),
        address: item["address"],
        road_address: item["roadAddress"],
        category: extract_main_category(item["category"]),
        description: remove_html_tags(item["description"]),
        telephone: item["telephone"],
        latitude: latitude,
        longitude: longitude,
        naver_map_url: "https://map.naver.com/p/search/#{ERB::Util.url_encode(remove_html_tags(item['title']))}?c=#{longitude},#{latitude},15,0,0,0,dh"
      }
    end
  end

  # Geocoding API 응답을 표준 Place 형식으로 변환
  def self.parse_geocode_response(response)
    return [] if response["status"] != "OK"

    addresses = response["addresses"] || []

    addresses.map do |addr|
      latitude = addr["y"].to_f
      longitude = addr["x"].to_f

      {
        title: addr["roadAddress"].presence || addr["jibunAddress"],
        address: addr["jibunAddress"],
        road_address: addr["roadAddress"],
        category: "주소",
        description: "",
        telephone: "",
        latitude: latitude,
        longitude: longitude,
        naver_map_url: "https://map.naver.com/p/search/#{ERB::Util.url_encode(addr['roadAddress'] || addr['jibunAddress'])}?c=#{longitude},#{latitude},15,0,0,0,dh"
      }
    end
  end

  # 카테고리에서 대분류만 추출
  # 예: "카페,디저트>카페" → "카페,디저트"
  #     "음식점>일식>일식당" → "음식점"
  def self.extract_main_category(category)
    return "" if category.blank?
    category.split(">").first
  end

  # HTML 태그 제거
  def self.remove_html_tags(text)
    return "" if text.nil?
    text.gsub(/<\/?b>/, "")
  end

  # 네이버 좌표계 → WGS84 좌표계 변환
  # 네이버는 KATECH 좌표계를 10^7배 한 값을 반환하므로
  # 10^7로 나누어 원래 좌표로 변환
  def self.convert_coordinate(coord)
    return 0.0 if coord.nil?
    coord.to_f / 10_000_000.0
  end
end
