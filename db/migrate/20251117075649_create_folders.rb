class CreateFolders < ActiveRecord::Migration[8.1]
  def change
    create_table :folders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.references :parent, foreign_key: { to_table: :folders }
      t.text :description

      t.timestamps
    end

    # 사용자별 폴더 조회 성능 최적화를 위한 인덱스
    add_index :folders, [ :user_id, :parent_id ]
    # 폴더명 검색을 위한 인덱스
    add_index :folders, :name
  end
end
