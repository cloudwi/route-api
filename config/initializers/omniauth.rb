# 젬 전체를 로드하는 표준 방식입니다.
require "omniauth-kakao"

# Credentials에서 Client ID와 Secret을 안전하게 불러옵니다.
KAKAO_CLIENT_ID = Rails.application.credentials.kakao[:client_id]
KAKAO_CLIENT_SECRET = Rails.application.credentials.kakao[:client_secret]

Rails.application.config.middleware.use OmniAuth::Builder do
  # Client ID와 Client Secret을 전달합니다.
  provider :kakao,
           KAKAO_CLIENT_ID,
           KAKAO_CLIENT_SECRET
end