class CreateImages < ActiveRecord::Migration[8.1]
  def change
    create_table :images do |t|
      t.references :user, null: true, foreign_key: true  # 로그인 없이도 업로드 가능
      t.string :purpose, comment: "이미지 용도 (place_thumbnail, profile, etc.)"

      t.timestamps
    end

    add_index :images, :created_at
  end
end
