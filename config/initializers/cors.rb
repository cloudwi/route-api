# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # 환경별로 허용할 origin을 다르게 설정
    # 프로덕션: Rails credentials에서 allowed_origins를 읽어옴
    # 개발/테스트: 모든 origin 허용
    origins_list = if Rails.env.production?
      # credentials.yml.enc에서 allowed_origins 읽기 (배열 형태)
      # 예: production.allowed_origins: ["https://example.com", "https://app.example.com"]
      Rails.application.credentials.allowed_origins || []
    else
      "*"
    end

    origins origins_list

    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ]
  end
end
