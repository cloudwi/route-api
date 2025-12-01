FactoryBot.define do
  factory :course do
    user
    sequence(:name) { |n| "코스 #{n}" }
  end
end
