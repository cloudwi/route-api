# 모든 API 컨트롤러의 베이스 컨트롤러
# ActionController::API를 상속받아 API 전용 기능만 사용
class ApplicationController < ActionController::API
  # 모든 액션 실행 전에 JWT 인증 수행
  # 특정 컨트롤러에서 skip_before_action으로 건너뛸 수 있음 (예: OAuth 콜백)
  before_action :authenticate_request

  # 전역 예외 처리
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActionController::ParameterMissing, with: :parameter_missing
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
  rescue_from StandardError, with: :internal_server_error if Rails.env.production?

  private

  # JWT 토큰을 검증하고 현재 사용자를 설정하는 메서드
  # Authorization 헤더에서 토큰을 추출하여 검증
  def authenticate_request
    # Authorization 헤더 가져오기 (형식: "Bearer <token>")
    header = request.headers["Authorization"]
    # 헤더가 없으면 인증하지 않고 리턴 (선택적 인증)
    return unless header

    # "Bearer " 부분을 제거하고 실제 토큰만 추출
    # 예: "Bearer abc123" -> "abc123"
    token = header.split(" ").last

    # JWT 토큰 디코드하여 페이로드 추출
    decoded = JsonWebToken.decode(token)

    # 디코드된 페이로드에서 user_id로 사용자 조회
    # decoded가 nil이 아닐 때만 실행
    @current_user = User.find(decoded[:user_id]) if decoded
  rescue ActiveRecord::RecordNotFound
    # user_id에 해당하는 사용자가 DB에 없는 경우
    # @current_user를 nil로 설정 (인증 실패)
    @current_user = nil
  end

  # 현재 로그인된 사용자 반환
  # 컨트롤러에서 current_user로 접근 가능
  def current_user
    @current_user
  end

  # 로그인이 필수인 액션에서 사용하는 헬퍼 메서드
  # current_user가 없으면 401 Unauthorized 에러 반환
  # 사용법: before_action :require_login (특정 컨트롤러에서)
  def require_login
    unless current_user
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end

  # 전역 예외 처리 메서드들

  # 리소스를 찾을 수 없을 때 (404)
  def record_not_found(exception)
    Rails.logger.error "Record not found: #{exception.message}"
    render json: {
      error: "Resource not found",
      message: exception.message
    }, status: :not_found
  end

  # 필수 파라미터가 누락되었을 때 (400)
  def parameter_missing(exception)
    Rails.logger.error "Parameter missing: #{exception.message}"
    render json: {
      error: "Bad request",
      message: exception.message
    }, status: :bad_request
  end

  # 유효성 검증 실패 (422)
  def record_invalid(exception)
    Rails.logger.error "Record invalid: #{exception.message}"
    render json: {
      error: "Validation failed",
      message: exception.record.errors.full_messages
    }, status: :unprocessable_entity
  end

  # 예상치 못한 서버 오류 (500)
  # 개발 환경에서는 원본 에러를 발생시키고, 프로덕션에서는 일반 메시지 반환
  def internal_server_error(exception)
    Rails.logger.error "Internal server error: #{exception.class} - #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")

    render json: {
      error: "Internal server error",
      message: "Something went wrong. Please try again later."
    }, status: :internal_server_error
  end
end
