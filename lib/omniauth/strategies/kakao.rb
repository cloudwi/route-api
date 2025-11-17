require "omniauth-oauth2"

module OmniAuth
  module Strategies
    # Kakao OAuth2 인증 전략 클래스
    # OmniAuth::Strategies::OAuth2를 상속받아 Kakao API에 맞게 커스터마이징
    class Kakao < OmniAuth::Strategies::OAuth2
      # 전략 이름 설정 (URL: /auth/kakao)
      option :name, "kakao"

      # Kakao OAuth2 엔드포인트 설정
      option :client_options,
             site: "https://kauth.kakao.com",                       # 기본 사이트 URL
             authorize_url: "https://kauth.kakao.com/oauth/authorize", # 인증 요청 URL
             token_url: "https://kauth.kakao.com/oauth/token"          # 토큰 요청 URL

      # 인증 요청 시 파라미터 설정
      option :authorize_params, response_type: "code"

      # 사용자 고유 식별자(uid) 반환
      # Kakao API에서 받은 사용자 id를 문자열로 변환
      uid { raw_info["id"].to_s }

      # 액세스 토큰 생성 메서드 오버라이드
      # Kakao API는 client_id와 client_secret을 POST body에 포함시켜야 하므로
      # 기본 omniauth-oauth2 동작(HTTP Basic Auth 사용)을 오버라이드
      def build_access_token
        # Kakao로부터 받은 인증 코드
        verifier = request.params["code"]

        # 인증 코드를 액세스 토큰으로 교환
        # client_id와 client_secret을 명시적으로 POST body에 포함
        client.auth_code.get_token(
          verifier,
          {
            redirect_uri: callback_url,           # 콜백 URL
            client_id: options.client_id,         # 클라이언트 ID (POST body에 포함)
            client_secret: options.client_secret  # 클라이언트 시크릿 (POST body에 포함)
          }.merge(token_params.to_hash(symbolize_keys: true)),
          deep_symbolize(options.auth_token_params)
        )
      end

      # OmniAuth Auth Hash의 info 부분 구성
      # 사용자 기본 정보를 표준 형식으로 반환
      info do
        {
          name: raw_info.dig("kakao_account", "profile", "nickname"),           # 닉네임
          email: raw_info.dig("kakao_account", "email"),                        # 이메일
          image: raw_info.dig("kakao_account", "profile", "profile_image_url")  # 프로필 이미지
        }
      end

      # OmniAuth Auth Hash의 extra 부분 구성
      # Kakao API로부터 받은 원본 데이터 전체를 포함
      extra do
        { raw_info: raw_info }
      end

      # Kakao API를 통해 사용자 정보 조회
      # 결과를 메모이제이션하여 중복 요청 방지
      def raw_info
        @raw_info ||= access_token.get("https://kapi.kakao.com/v2/user/me").parsed
      end

      # OAuth 콜백 URL 생성
      # 전체 호스트 + 스크립트 이름 + 콜백 경로를 조합
      def callback_url
        full_host + script_name + callback_path
      end
    end
  end
end
