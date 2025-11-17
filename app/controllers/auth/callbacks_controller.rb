module Auth
  class CallbacksController < ApplicationController
    skip_before_action :authenticate_request
    def kakao
      auth = request.env["omniauth.auth"]
      user = User.from_omniauth(auth)

      if user.persisted?
        token = JsonWebToken.encode(user_id: user.id)
        render json: {
          token: token,
          user: {
            id: user.id,
            email: user.email,
            name: user.name,
            profile_image: user.profile_image
          }
        }, status: :ok
      else
        render json: { error: "Authentication failed" }, status: :unauthorized
      end
    end

    def failure
      render json: { error: params[:message] }, status: :unauthorized
    end
  end
end
