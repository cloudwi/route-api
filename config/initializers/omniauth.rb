# Load Kakao OAuth Strategy
require Rails.root.join("lib", "omniauth", "strategies", "kakao")

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :kakao, ENV["KAKAO_CLIENT_ID"], ENV["KAKAO_CLIENT_SECRET"]
end