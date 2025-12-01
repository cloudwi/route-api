FactoryBot.define do
  factory :user do
    sequence(:uid) { |n| "user_#{n}" }
    provider { "kakao" }
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:name) { |n| "User #{n}" }
    profile_image { "https://example.com/profile.jpg" }
  end
end
