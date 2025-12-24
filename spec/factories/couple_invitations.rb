FactoryBot.define do
  factory :couple_invitation do
    inviter_id { 1 }
    token { "MyString" }
    expires_at { "2025-12-24 15:48:38" }
    used { false }
  end
end
