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
      # 인기 장소 (로그인 불필요)
      get "popular_places", to: "popular_places#index"  # GET /api/v1/popular_places

      # 장소 검색
      get "search", to: "search#index"  # GET /api/v1/search?query=스타벅스 강남역

      # 경로 검색 (대중교통/자동차)
      get "directions", to: "directions#index"  # GET /api/v1/directions?mode=transit|driving

      # 폴더 관리
      resources :folders do
        member do
          get :children  # GET /api/v1/folders/:id/children - 특정 폴더의 직속 하위 폴더 조회
        end
        collection do
          get :flat      # GET /api/v1/folders/flat - 모든 폴더를 평면 리스트로 조회
        end
      end

      # 코스 관리
      resources :courses, only: [ :index, :show, :create, :destroy ] do
        member do
          get :directions  # GET /api/v1/courses/:id/directions?mode=transit|driving
        end
      end

      # 장소 관리
      resources :places, only: [ :index, :show ] do
        member do
          post :like    # POST /api/v1/places/:id/like
          delete :like, action: :unlike  # DELETE /api/v1/places/:id/like
        end
        collection do
          get :liked    # GET /api/v1/places/liked - 좋아요한 장소 목록
        end
      end
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
