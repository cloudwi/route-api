Rails.application.routes.draw do
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

    # 폴더 관리 엔드포인트
    resources :folders do
      member do
        get :children  # GET /api/folders/:id/children - 특정 폴더의 직속 하위 폴더 조회
      end
      collection do
        get :flat      # GET /api/folders/flat - 모든 폴더를 평면 리스트로 조회
      end
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
