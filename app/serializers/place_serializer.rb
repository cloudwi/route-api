# PlaceSerializer - 장소 데이터를 JSON 형식으로 직렬화
# 컨트롤러 전반에서 일관된 장소 데이터 형식을 제공
class PlaceSerializer
  # 기본 장소 정보를 JSON으로 변환
  # @param place [Place] 직렬화할 장소 객체
  # @param current_user [User, nil] 현재 로그인한 사용자 (좋아요 상태 확인용, 선택사항)
  # @return [Hash] JSON 형식의 장소 데이터
  def self.serialize(place, current_user: nil)
    base_data = {
      id: place.id,
      naverPlaceId: place.naver_place_id,
      name: place.name,
      address: place.address,
      roadAddress: place.road_address,
      lat: place.latitude.to_f,
      lng: place.longitude.to_f,
      category: place.category,
      telephone: place.telephone,
      naverMapUrl: place.naver_map_url,
      viewsCount: place.views_count,
      likesCount: place.likes_count,
      createdAt: place.created_at.iso8601
    }

    # 현재 사용자가 있는 경우 좋아요 상태 추가
    if current_user
      base_data[:liked] = place.liked_by?(current_user)
    end

    base_data
  end

  # 여러 장소를 한 번에 직렬화
  # @param places [Array<Place>] 직렬화할 장소 배열
  # @param current_user [User, nil] 현재 로그인한 사용자
  # @return [Array<Hash>] JSON 형식의 장소 데이터 배열
  def self.serialize_collection(places, current_user: nil)
    places.map { |place| serialize(place, current_user: current_user) }
  end

  # 인기 점수를 포함한 장소 정보 직렬화 (인기 장소 API용)
  # @param place [Place] 직렬화할 장소 객체
  # @return [Hash] 인기 점수가 포함된 JSON 형식의 장소 데이터
  def self.serialize_with_popularity(place)
    data = serialize(place)
    data[:popularityScore] = place.respond_to?(:popularity_score) ? place.popularity_score : nil
    data
  end
end
