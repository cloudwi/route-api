class PlaceLike < ApplicationRecord
  belongs_to :user
  belongs_to :place, counter_cache: :likes_count

  validates :user_id, uniqueness: { scope: :place_id, message: "이미 좋아요한 장소입니다" }
end
