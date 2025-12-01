class Course < ApplicationRecord
  belongs_to :user
  has_many :course_places, -> { order(:position) }, dependent: :destroy
  has_many :places, through: :course_places

  validates :name, presence: true

  # 장소들과 함께 코스 생성
  def self.create_with_places(user:, name:, places_data:)
    transaction do
      course = user.courses.create!(name: name)

      places_data.each_with_index do |place_data, index|
        # 장소를 독립적으로 저장 (이미 있으면 기존 것 사용)
        place = Place.find_or_create_from_data(user: user, place_data: place_data)

        # 코스-장소 연결 (순서 포함)
        course.course_places.create!(place: place, position: index)
      end

      course
    end
  end
end
