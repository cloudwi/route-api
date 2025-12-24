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

      # 외부 장소 검색 (네이버 API, 로그인 필요)
      get "external/search", to: "external#search"  # GET /api/v1/external/search?query=스타벅스 강남역

      # 내 장소/코스 검색 (로그인 불필요)
      get "my_search", to: "my_search#index"  # GET /api/v1/my_search?q=카페&category=카페
      get "my_search/categories", to: "my_search#categories"  # GET /api/v1/my_search/categories

      # 코스 관리
      resources :courses, only: [ :index, :show, :create, :destroy ]

      # 장소 관리
      resources :places, only: [ :index, :show ] do
        resource :likes, only: [ :create ], controller: "place_likes"  # POST /api/v1/places/:id/likes - 좋아요 토글
        collection do
          get :liked    # GET /api/v1/places/liked - 좋아요한 장소 목록
        end
      end
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
