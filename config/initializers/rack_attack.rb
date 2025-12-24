# Rack Attack 설정 - API 속도 제한 및 보안
# Read more: https://github.com/rack/rack-attack

class Rack::Attack
  ### Configure Cache ###

  # Rack::Attack가 기본적으로 Rails.cache를 사용하지만,
  # Redis를 사용하는 것이 프로덕션 환경에 권장됩니다.
  # Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  ### Throttle Spammy Clients ###

  # 모든 IP에서 들어오는 요청을 제한 (초당 5회, 1분간 300회)
  # 정상적인 사용자는 이 제한을 넘지 않을 것입니다.
  throttle("req/ip", limit: 300, period: 1.minute) do |req|
    req.ip
  end

  # OAuth 로그인 시도 제한 (IP당 5분에 5회)
  throttle("auth/login/ip", limit: 5, period: 5.minutes) do |req|
    if req.path.start_with?("/auth/") && req.post?
      req.ip
    end
  end

  # API 요청 제한 - 인증된 사용자 (사용자당 1분에 100회)
  throttle("api/authenticated", limit: 100, period: 1.minute) do |req|
    # Authorization 헤더에서 토큰 추출
    if req.env["HTTP_AUTHORIZATION"].present?
      token = req.env["HTTP_AUTHORIZATION"].split(" ").last
      decoded = JsonWebToken.decode(token) rescue nil
      decoded[:user_id] if decoded
    end
  end

  # 검색 API 제한 (IP당 1분에 30회)
  throttle("search/ip", limit: 30, period: 1.minute) do |req|
    if req.path.start_with?("/api/v1/external/search")
      req.ip
    end
  end

  ### Prevent Brute-Force Login Attacks ###

  # 로그인 실패 후 차단 (5회 실패 시 1시간 차단)
  # 주의: 이 기능을 사용하려면 실패한 로그인 시도를 추적해야 합니다
  # blocklist("fail2ban/login") do |req|
  #   Rack::Attack::Fail2Ban.filter("login-#{req.ip}", maxretry: 5, findtime: 10.minutes, bantime: 1.hour) do
  #     req.path == "/auth/callback" && req.post? && req.env["HTTP_AUTHORIZATION"].blank?
  #   end
  # end

  ### Custom Throttle Response ###

  # 속도 제한 초과 시 반환할 응답 커스터마이징
  self.throttled_responder = lambda do |env|
    match_data = env["rack.attack.match_data"]
    now = match_data[:epoch_time]

    headers = {
      "X-RateLimit-Limit" => match_data[:limit].to_s,
      "X-RateLimit-Remaining" => "0",
      "X-RateLimit-Reset" => (now + (match_data[:period] - (now % match_data[:period]))).to_s,
      "Content-Type" => "application/json"
    }

    body = {
      error: "Rate limit exceeded",
      message: "Too many requests. Please try again later.",
      retry_after: match_data[:period]
    }.to_json

    [ 429, headers, [ body ] ]
  end

  ### Logging ###

  # 속도 제한 발생 시 로깅
  ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _request_id, payload|
    req = payload[:request]
    Rails.logger.warn "[Rack::Attack] Throttled request: #{req.ip} to #{req.path}"
  end

  # 차단 발생 시 로깅
  ActiveSupport::Notifications.subscribe("blocklist.rack_attack") do |_name, _start, _finish, _request_id, payload|
    req = payload[:request]
    Rails.logger.error "[Rack::Attack] Blocked request: #{req.ip} to #{req.path}"
  end
end

# Rack::Attack 미들웨어 활성화
# 개발 환경에서는 비활성화하거나 제한을 느슨하게 설정할 수 있습니다
unless Rails.env.test?
  Rails.application.config.middleware.use Rack::Attack
end
