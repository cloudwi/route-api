class AddPerformanceIndexes < ActiveRecord::Migration[8.1]
  def change
    # Places 테이블 인덱스
    # 카테고리 검색 최적화 (my_search_controller.rb:59)
    add_index :places, :category unless index_exists?(:places, :category)

    # 장소 이름 검색 최적화 (my_search_controller.rb:66)
    add_index :places, :name unless index_exists?(:places, :name)

    # views_count 인덱스 추가 (인기도 계산용)
    add_index :places, :views_count unless index_exists?(:places, :views_count)
  end
end
