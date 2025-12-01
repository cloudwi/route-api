class CreateCoursePlaces < ActiveRecord::Migration[8.1]
  def change
    create_table :course_places do |t|
      t.references :course, null: false, foreign_key: true
      t.string :naver_place_id
      t.string :name
      t.string :address
      t.string :road_address
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7
      t.string :category
      t.string :telephone
      t.string :naver_map_url
      t.integer :position

      t.timestamps
    end
  end
end
