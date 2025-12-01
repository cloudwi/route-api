class CreatePlaces < ActiveRecord::Migration[8.1]
  def change
    create_table :places do |t|
      t.references :user, null: false, foreign_key: true
      t.string :naver_place_id
      t.string :name
      t.string :address
      t.string :road_address
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7
      t.string :category
      t.string :telephone
      t.string :naver_map_url

      t.timestamps
    end

    # 같은 사용자가 같은 네이버 장소를 중복 저장하지 않도록
    add_index :places, [ :user_id, :naver_place_id ], unique: true
  end
end
