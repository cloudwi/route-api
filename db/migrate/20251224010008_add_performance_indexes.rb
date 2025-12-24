class AddPerformanceIndexes < ActiveRecord::Migration[8.1]
  def change
    # Places 테이블 인덱스
    # 카테고리 검색 최적화 (my_search_controller.rb:59)
    add_index :places, :category unless index_exists?(:places, :category)

    # 장소 이름 검색 최적화 (my_search_controller.rb:66)
    add_index :places, :name unless index_exists?(:places, :name)

    # 인기 장소 쿼리 최적화 - likes_count 및 created_at 복합 인덱스
    add_index :places, [ :likes_count, :created_at ], name: "index_places_on_popularity" unless index_exists?(:places, [ :likes_count, :created_at ], name: "index_places_on_popularity")

    # views_count 인덱스 추가 (인기도 계산용)
    add_index :places, :views_count unless index_exists?(:places, :views_count)

    # Courses 테이블 인덱스 (코스 기능이 있는 경우)
    if table_exists?(:courses)
      # 코스 이름 검색 최적화
      add_index :courses, :name unless index_exists?(:courses, :name)

      # 코스 생성일 정렬 최적화
      add_index :courses, :created_at unless index_exists?(:courses, :created_at)
    end

    # CoursePlace 테이블 인덱스
    if table_exists?(:course_places)
      # 코스 내 장소 순서 조회 최적화
      add_index :course_places, [ :course_id, :position ], name: "index_course_places_on_course_and_position" unless index_exists?(:course_places, [ :course_id, :position ], name: "index_course_places_on_course_and_position")
    end
  end
end
