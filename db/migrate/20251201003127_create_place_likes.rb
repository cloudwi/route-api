class CreatePlaceLikes < ActiveRecord::Migration[8.1]
  def change
    create_table :place_likes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :place, null: false, foreign_key: true

      t.timestamps
    end

    # 같은 사용자가 같은 장소에 중복 좋아요 방지
    add_index :place_likes, [:user_id, :place_id], unique: true
  end
end
