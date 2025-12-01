# 네이버 로컬 검색 API를 호출하는 서비스 클래스
# 장소 검색 후 결과를 표준화된 형식으로 변환
class NaverSearchService
  include HTTParty
  base_uri "https://openapi.naver.com"

  # 네이버 검색 API로 장소를 검색합니다
  # @param query [String] 검색 키워드 (예: "스타벅스 강남역")
  # @param display [Integer] 검색 결과 개수 (기본: 5, 최대: 5)
  # @return [Array<Hash>] 검색 결과 배열
  def self.search_places(query:, display: 5)
    response = get(
      "/v1/search/local.json",
      query: { query: query, display: display },
      headers: {
        "X-Naver-Client-Id" => Rails.application.credentials.dig(Rails.env.to_sym, :naver, :client_id),
        "X-Naver-Client-Secret" => Rails.application.credentials.dig(Rails.env.to_sym, :naver, :client_secret)
      }
    )

    if response.success?
      parse_response(response.parsed_response)
    else
      Rails.logger.error "Naver API Error: #{response.code} - #{response.message}"
      []
    end
  rescue StandardError => e
    Rails.logger.error "Naver Search Service Error: #{e.message}"
    []
  end

  private

  # 네이버 API 응답을 표준 Place 형식으로 변환
  # @param response [Hash] 네이버 API 응답
  # @return [Array<Hash>] 변환된 장소 데이터
  def self.parse_response(response)
    items = response["items"] || []

    items.map do |item|
      latitude = convert_coordinate(item["mapy"])
      longitude = convert_coordinate(item["mapx"])

      {
        title: remove_html_tags(item["title"]),
        address: item["address"],
        road_address: item["roadAddress"],
        category: item["category"],
        description: remove_html_tags(item["description"]),
        telephone: item["telephone"],
        latitude: latitude,
        longitude: longitude,
        naver_map_url: "https://map.naver.com/p/search/#{ERB::Util.url_encode(remove_html_tags(item['title']))}?c=#{longitude},#{latitude},15,0,0,0,dh"
      }
    end
  end

  # HTML 태그 제거
  # @param text [String] HTML 태그가 포함된 텍스트
  # @return [String] 태그가 제거된 텍스트
  def self.remove_html_tags(text)
    return "" if text.nil?
    text.gsub(/<\/?b>/, "")
  end

  # 네이버 좌표계 → WGS84 좌표계 변환
  # 네이버는 KATECH 좌표계를 10^7배 한 값을 반환하므로
  # 10^7로 나누어 원래 좌표로 변환
  # @param coord [String, Integer] 네이버 좌표값
  # @return [Float] WGS84 좌표값
  def self.convert_coordinate(coord)
    return 0.0 if coord.nil?
    coord.to_f / 10_000_000.0
  end
end
