module Auth
  # OAuth 인증 콜백을 처리하는 컨트롤러
  class CallbacksController < ApplicationController
    # JWT 인증을 건너뛰기 (OAuth 콜백은 인증 전이므로)
    skip_before_action :authenticate_request

    # Kakao OAuth 콜백 처리
    # URL: /auth/kakao/callback
    def kakao
      # OmniAuth가 설정한 인증 정보 가져오기
      # omniauth.auth에는 사용자 정보, 토큰 등이 포함됨
      auth = request.env["omniauth.auth"]

      # OmniAuth 데이터를 기반으로 사용자 조회 또는 생성
      user = User.from_omniauth(auth)

      # 사용자가 성공적으로 DB에 저장되었는지 확인
      if user.persisted?
        # JWT 토큰 생성 (user_id를 페이로드에 포함)
        token = JsonWebToken.encode(user_id: user.id)

        # 프론트엔드 URL 설정 (환경변수 또는 기본값)
        frontend_url = ENV["FRONTEND_URL"] || "http://localhost:3001"

        # JWT 토큰과 함께 프론트엔드로 리다이렉트
        # allow_other_host: true - 다른 도메인으로의 리다이렉트 허용
        redirect_to "#{frontend_url}/auth/callback?token=#{token}", allow_other_host: true
      else
        # 사용자 저장 실패 시 에러와 함께 프론트엔드로 리다이렉트
        frontend_url = ENV["FRONTEND_URL"] || "http://localhost:3001"
        redirect_to "#{frontend_url}/auth/callback?error=authentication_failed", allow_other_host: true
      end
    end

    # OAuth 인증 실패 시 호출되는 액션
    # OmniAuth가 자동으로 /auth/failure로 리다이렉트
    def failure
      # 프론트엔드 URL 설정
      frontend_url = ENV["FRONTEND_URL"] || "http://localhost:3001"

      # 에러 메시지와 함께 프론트엔드로 리다이렉트
      # params[:message]에는 OmniAuth가 전달한 에러 메시지가 포함됨
      redirect_to "#{frontend_url}/auth/callback?error=#{params[:message]}", allow_other_host: true
    end
  end
end
