class Place < ApplicationRecord
  belongs_to :user
  has_many :place_likes, dependent: :destroy
  has_many :liked_by_users, through: :place_likes, source: :user

  validates :name, presence: true, length: { minimum: 1, maximum: 255 }
  validates :latitude, presence: true, numericality: {
    greater_than_or_equal_to: -90,
    less_than_or_equal_to: 90,
    message: "must be between -90 and 90"
  }
  validates :longitude, presence: true, numericality: {
    greater_than_or_equal_to: -180,
    less_than_or_equal_to: 180,
    message: "must be between -180 and 180"
  }
  validates :naver_place_id, uniqueness: { scope: :user_id }, allow_blank: true
  validates :views_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :likes_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  # 조회수 증가
  def increment_views!
    increment!(:views_count)
  end

  # 특정 사용자가 좋아요 했는지 확인
  def liked_by?(user)
    return false unless user
    place_likes.exists?(user: user)
  end

  # 네이버 장소 ID로 기존 장소 조회 또는 새로 생성
  def self.find_or_create_from_data(user:, place_data:)
    # naver_place_id가 있으면 기존 장소 조회
    if place_data[:id].present?
      existing = user.places.find_by(naver_place_id: place_data[:id])
      return existing if existing
    end

    # 새 장소 생성
    user.places.create!(
      naver_place_id: place_data[:id],
      name: place_data[:name],
      address: place_data[:address],
      road_address: place_data[:road_address],
      latitude: place_data[:lat],
      longitude: place_data[:lng],
      category: place_data[:category],
      telephone: place_data[:telephone],
      naver_map_url: place_data[:naver_map_url]
    )
  end
end
