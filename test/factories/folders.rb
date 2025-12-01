FactoryBot.define do
  factory :folder do
    user
    sequence(:name) { |n| "폴더 #{n}" }
    description { "테스트 폴더 설명" }
    parent { nil }

    trait :with_parent do
      association :parent, factory: :folder
    end

    trait :root do
      parent { nil }
    end
  end
end
