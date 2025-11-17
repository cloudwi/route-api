module Auth
  class CallbacksController < ApplicationController
    skip_before_action :authenticate_request

    def kakao
      auth = request.env["omniauth.auth"]
      user = User.from_omniauth(auth)

      if user.persisted?
        token = JsonWebToken.encode(user_id: user.id)

        # Redirect to frontend with JWT token
        frontend_url = ENV["FRONTEND_URL"] || "http://localhost:3001"
        redirect_to "#{frontend_url}/auth/callback?token=#{token}", allow_other_host: true
      else
        frontend_url = ENV["FRONTEND_URL"] || "http://localhost:3001"
        redirect_to "#{frontend_url}/auth/callback?error=authentication_failed", allow_other_host: true
      end
    end

    def failure
      frontend_url = ENV["FRONTEND_URL"] || "http://localhost:3001"
      redirect_to "#{frontend_url}/auth/callback?error=#{params[:message]}", allow_other_host: true
    end
  end
end
