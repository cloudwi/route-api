FactoryBot.define do
  factory :course_place do
    course
    place
    sequence(:position) { |n| n }
  end
end
