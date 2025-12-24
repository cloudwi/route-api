class DropCourseTables < ActiveRecord::Migration[8.1]
  def up
    # course_places 테이블 삭제 (외래 키가 있으므로 먼저 삭제)
    drop_table :course_places if table_exists?(:course_places)

    # courses 테이블 삭제
    drop_table :courses if table_exists?(:courses)
  end

  def down
    # 되돌리기 (rollback) 시 테이블 재생성
    # 주의: 데이터는 복구되지 않음
    create_table :courses, comment: "코스 고유 식별자", charset: "utf8mb4", collation: "utf8mb4_unicode_ci" do |t|
      t.references :user, null: false, foreign_key: true, comment: "코스 소유자"
      t.string :name, null: false, comment: "코스 이름"
      t.timestamps
    end

    create_table :course_places, comment: "코스-장소 연결 고유 식별자", charset: "utf8mb4", collation: "utf8mb4_unicode_ci" do |t|
      t.references :course, null: false, foreign_key: true, comment: "코스"
      t.references :place, null: false, foreign_key: true, comment: "장소"
      t.integer :position, null: false, comment: "코스 내 순서"
      t.timestamps
    end
  end
end
