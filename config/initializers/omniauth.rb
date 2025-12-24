# Kakao OAuth 커스텀 전략 로드
# lib/omniauth/strategies/kakao.rb 파일을 require
require Rails.root.join("lib", "omniauth", "strategies", "kakao")

# OmniAuth 전역 설정
OmniAuth.config.allowed_request_methods = [ :get, :post ]  # GET과 POST 요청 모두 허용
OmniAuth.config.silence_get_warning = true               # GET 요청에 대한 경고 메시지 숨기기

# Rails 미들웨어 스택에 OmniAuth 추가
Rails.application.config.middleware.use OmniAuth::Builder do
  # Rails credentials에서 환경별 Kakao OAuth 설정 읽기
  # credentials가 없는 경우 개발용 기본값 사용
  client_id = "development_client_id"
  client_secret = "development_client_secret"

  begin
    if defined?(Rails.application.credentials) && Rails.application.credentials.config.present?
      credentials = Rails.application.credentials
      client_id = credentials.dig(Rails.env.to_sym, :kakao, :client_id) ||
                  credentials.dig(:kakao, :client_id) ||
                  client_id
      client_secret = credentials.dig(Rails.env.to_sym, :kakao, :client_secret) ||
                      credentials.dig(:kakao, :client_secret) ||
                      client_secret
    end
  rescue StandardError => e
    # credentials 파일이 없거나 손상된 경우 기본값 사용
    puts "Warning: Could not read credentials (#{e.message}). Using default values."
  end

  # Kakao OAuth 프로바이더 등록
  provider :kakao, client_id, client_secret
end
