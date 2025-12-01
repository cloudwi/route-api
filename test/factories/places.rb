FactoryBot.define do
  factory :place do
    user
    sequence(:naver_place_id) { |n| "place_#{n}" }
    sequence(:name) { |n| "장소 #{n}" }
    address { "서울시 강남구 테스트동 123" }
    road_address { "서울시 강남구 테스트로 456" }
    latitude { 37.123456 }
    longitude { 127.123456 }
    category { "카페" }
    telephone { "02-1234-5678" }
    naver_map_url { "https://map.naver.com/p/search/test" }
    views_count { 0 }
    likes_count { 0 }

    trait :popular do
      views_count { 100 }
      likes_count { 50 }
    end

    trait :with_high_likes do
      likes_count { 100 }
    end

    trait :with_high_views do
      views_count { 200 }
    end
  end
end
