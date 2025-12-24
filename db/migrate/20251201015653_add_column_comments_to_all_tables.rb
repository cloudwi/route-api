class AddColumnCommentsToAllTables < ActiveRecord::Migration[8.1]
  def up
    # users 테이블
    change_column_comment :users, :id, "사용자 고유 식별자"
    change_column_comment :users, :provider, "OAuth 제공자 (예: kakao)"
    change_column_comment :users, :uid, "OAuth 제공자에서 발급한 고유 ID"
    change_column_comment :users, :email, "사용자 이메일 주소"
    change_column_comment :users, :name, "사용자 이름"
    change_column_comment :users, :profile_image, "프로필 이미지 URL"
    change_column_comment :users, :created_at, "생성 일시"
    change_column_comment :users, :updated_at, "수정 일시"

    # folders 테이블
    change_column_comment :folders, :id, "폴더 고유 식별자"
    change_column_comment :folders, :user_id, "소유자 사용자 ID"
    change_column_comment :folders, :name, "폴더 이름"
    change_column_comment :folders, :parent_id, "상위 폴더 ID (null이면 루트 폴더)"
    change_column_comment :folders, :description, "폴더 설명"
    change_column_comment :folders, :created_at, "생성 일시"
    change_column_comment :folders, :updated_at, "수정 일시"

    # places 테이블
    change_column_comment :places, :id, "장소 고유 식별자"
    change_column_comment :places, :user_id, "소유자 사용자 ID"
    change_column_comment :places, :naver_place_id, "네이버 장소 고유 ID"
    change_column_comment :places, :name, "장소 이름"
    change_column_comment :places, :address, "지번 주소"
    change_column_comment :places, :road_address, "도로명 주소"
    change_column_comment :places, :latitude, "위도"
    change_column_comment :places, :longitude, "경도"
    change_column_comment :places, :category, "장소 카테고리 (예: 카페, 음식점)"
    change_column_comment :places, :telephone, "전화번호"
    change_column_comment :places, :naver_map_url, "네이버 지도 URL"
    change_column_comment :places, :views_count, "조회수"
    change_column_comment :places, :likes_count, "좋아요 수"
    change_column_comment :places, :created_at, "생성 일시"
    change_column_comment :places, :updated_at, "수정 일시"

    # place_likes 테이블
    change_column_comment :place_likes, :id, "좋아요 고유 식별자"
    change_column_comment :place_likes, :user_id, "좋아요 누른 사용자 ID"
    change_column_comment :place_likes, :place_id, "좋아요 대상 장소 ID"
    change_column_comment :place_likes, :created_at, "생성 일시"
    change_column_comment :place_likes, :updated_at, "수정 일시"
  end

  def down
    # users 테이블
    change_column_comment :users, :id, nil
    change_column_comment :users, :provider, nil
    change_column_comment :users, :uid, nil
    change_column_comment :users, :email, nil
    change_column_comment :users, :name, nil
    change_column_comment :users, :profile_image, nil
    change_column_comment :users, :created_at, nil
    change_column_comment :users, :updated_at, nil

    # folders 테이블
    change_column_comment :folders, :id, nil
    change_column_comment :folders, :user_id, nil
    change_column_comment :folders, :name, nil
    change_column_comment :folders, :parent_id, nil
    change_column_comment :folders, :description, nil
    change_column_comment :folders, :created_at, nil
    change_column_comment :folders, :updated_at, nil

    # places 테이블
    change_column_comment :places, :id, nil
    change_column_comment :places, :user_id, nil
    change_column_comment :places, :naver_place_id, nil
    change_column_comment :places, :name, nil
    change_column_comment :places, :address, nil
    change_column_comment :places, :road_address, nil
    change_column_comment :places, :latitude, nil
    change_column_comment :places, :longitude, nil
    change_column_comment :places, :category, nil
    change_column_comment :places, :telephone, nil
    change_column_comment :places, :naver_map_url, nil
    change_column_comment :places, :views_count, nil
    change_column_comment :places, :likes_count, nil
    change_column_comment :places, :created_at, nil
    change_column_comment :places, :updated_at, nil

    # place_likes 테이블
    change_column_comment :place_likes, :id, nil
    change_column_comment :place_likes, :user_id, nil
    change_column_comment :place_likes, :place_id, nil
    change_column_comment :place_likes, :created_at, nil
    change_column_comment :place_likes, :updated_at, nil
  end
end
