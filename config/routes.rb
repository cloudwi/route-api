Rails.application.routes.draw do
  # Swagger UI - 운영 환경에서는 비활성화
  unless Rails.env.production?
    mount Rswag::Ui::Engine => "/api-docs"
    mount Rswag::Api::Engine => "/api-docs"
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # OAuth authentication routes
  get "/auth/:provider/callback", to: "auth/callbacks#kakao"
  get "/auth/failure", to: "auth/callbacks#failure"

  # API routes
  namespace :api do
    # 헬스체크 엔드포인트
    get "health", to: "health#index"           # 기본 헬스체크
    get "health/detailed", to: "health#detailed" # 상세 헬스체크 (DB 연결 포함)

    # v1 API 엔드포인트
    namespace :v1 do
      # 커플 관리
      resource :couple, only: [ :show, :destroy ]  # GET /api/v1/couple, DELETE /api/v1/couple
      resources :couple_invitations, only: [ :create ] do
        member do
          post :accept  # POST /api/v1/couple_invitations/:token/accept
        end
      end

      # 일기 관리
      resources :diaries
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
