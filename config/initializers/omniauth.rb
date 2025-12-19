# Kakao OAuth 커스텀 전략 로드
# lib/omniauth/strategies/kakao.rb 파일을 require
require Rails.root.join("lib", "omniauth", "strategies", "kakao")

# OmniAuth 전역 설정
OmniAuth.config.allowed_request_methods = [ :get, :post ]  # GET과 POST 요청 모두 허용
OmniAuth.config.silence_get_warning = true               # GET 요청에 대한 경고 메시지 숨기기

# Rails 미들웨어 스택에 OmniAuth 추가
Rails.application.config.middleware.use OmniAuth::Builder do
  # Rails credentials에서 Kakao OAuth 설정 읽기
  # 환경별 credentials 파일 (development.yml.enc, production.yml.enc)에서 자동으로 읽음
  client_id = Rails.application.credentials.kakao&.client_id
  client_secret = Rails.application.credentials.kakao&.client_secret

  # Kakao OAuth 프로바이더 등록
  # 첫 번째 인자: 전략 이름 (:kakao)
  # 두 번째 인자: 클라이언트 ID
  # 세 번째 인자: 클라이언트 시크릿
  provider :kakao, client_id, client_secret
end
