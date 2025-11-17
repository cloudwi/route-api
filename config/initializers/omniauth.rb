# Load Kakao OAuth Strategy
require Rails.root.join("lib", "omniauth", "strategies", "kakao")

# OmniAuth configuration
OmniAuth.config.allowed_request_methods = [:get, :post]
OmniAuth.config.silence_get_warning = true

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :kakao,
           Rails.application.credentials.dig(Rails.env.to_sym, :kakao, :client_id),
           Rails.application.credentials.dig(Rails.env.to_sym, :kakao, :client_secret)
end