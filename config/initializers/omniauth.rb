# Kakao OAuth 커스텀 전략 로드
# lib/omniauth/strategies/kakao.rb 파일을 require
require Rails.root.join("lib", "omniauth", "strategies", "kakao")

# OmniAuth 전역 설정
OmniAuth.config.allowed_request_methods = [ :get, :post ]  # GET과 POST 요청 모두 허용
OmniAuth.config.silence_get_warning = true               # GET 요청에 대한 경고 메시지 숨기기

# Rails 미들웨어 스택에 OmniAuth 추가
Rails.application.config.middleware.use OmniAuth::Builder do
  # Rails credentials에서 환경별 Kakao OAuth 설정 읽기
  # credentials.yml.enc 파일의 development.kakao.client_id 또는 production.kakao.client_id
  # 테스트 환경에서는 더미 값 사용
  client_id = Rails.application.credentials.dig(Rails.env.to_sym, :kakao, :client_id) || "test_client_id"
  client_secret = Rails.application.credentials.dig(Rails.env.to_sym, :kakao, :client_secret) || "test_client_secret"

  # Kakao OAuth 프로바이더 등록
  # 첫 번째 인자: 전략 이름 (:kakao)
  # 두 번째 인자: 클라이언트 ID
  # 세 번째 인자: 클라이언트 시크릿
  provider :kakao, client_id, client_secret
end
