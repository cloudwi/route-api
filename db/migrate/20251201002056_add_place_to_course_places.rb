class AddPlaceToCoursePlaces < ActiveRecord::Migration[8.1]
  def change
    # place_id 추가 (기존 데이터가 있을 수 있으므로 nullable로)
    add_reference :course_places, :place, null: true, foreign_key: true

    # 기존 장소 정보 컬럼들은 제거 (Place 테이블로 이동)
    remove_column :course_places, :naver_place_id, :string
    remove_column :course_places, :name, :string
    remove_column :course_places, :address, :string
    remove_column :course_places, :road_address, :string
    remove_column :course_places, :latitude, :decimal
    remove_column :course_places, :longitude, :decimal
    remove_column :course_places, :category, :string
    remove_column :course_places, :telephone, :string
    remove_column :course_places, :naver_map_url, :string
  end
end
