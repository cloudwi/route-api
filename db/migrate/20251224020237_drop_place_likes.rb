class DropPlaceLikes < ActiveRecord::Migration[8.1]
  def up
    # place_likes 테이블 삭제
    drop_table :place_likes if table_exists?(:place_likes)

    # places 테이블에서 likes_count 컬럼 제거
    remove_column :places, :likes_count if column_exists?(:places, :likes_count)

    # 인기도 인덱스 제거 (이미 존재하지 않을 수 있음)
    remove_index :places, name: "index_places_on_popularity" if index_exists?(:places, name: "index_places_on_popularity")
  end

  def down
    # 되돌리기 (rollback) 시 테이블 및 컬럼 재생성
    # 주의: 데이터는 복구되지 않음

    # likes_count 컬럼 추가
    add_column :places, :likes_count, :integer, default: 0, null: false unless column_exists?(:places, :likes_count)

    # place_likes 테이블 재생성
    unless table_exists?(:place_likes)
      create_table :place_likes, comment: "좋아요 고유 식별자", charset: "utf8mb4", collation: "utf8mb4_unicode_ci" do |t|
        t.references :user, null: false, foreign_key: true, comment: "좋아요 누른 사용자"
        t.references :place, null: false, foreign_key: true, comment: "좋아요 대상 장소"
        t.timestamps

        t.index [ :user_id, :place_id ], unique: true
      end
    end

    # 인기도 인덱스 재생성
    add_index :places, [ :likes_count, :created_at ], name: "index_places_on_popularity" unless index_exists?(:places, name: "index_places_on_popularity")
  end
end
