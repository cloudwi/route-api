module Api
  # 애플리케이션 상태를 확인하는 헬스체크 컨트롤러
  # 로드밸런서나 모니터링 시스템에서 서버 상태 확인 용도
  class HealthController < ApplicationController
    # JWT 인증을 건너뛰기 (헬스체크는 인증 불필요)
    skip_before_action :authenticate_request

    # 기본 헬스체크 엔드포인트
    # GET /api/health
    # 서버가 정상적으로 응답 가능한지 확인
    def index
      render json: {
        status: "ok",
        timestamp: Time.current.iso8601,
        service: "Route API"
      }, status: :ok
    end

    # 상세 헬스체크 엔드포인트
    # GET /api/health/detailed
    # 데이터베이스 연결 상태까지 확인
    def detailed
      # 데이터베이스 연결 확인
      db_status = check_database_connection

      # 전체 상태 결정 (모든 체크가 통과해야 healthy)
      overall_status = db_status[:status] == "ok" ? "healthy" : "unhealthy"
      http_status = overall_status == "healthy" ? :ok : :service_unavailable

      render json: {
        status: overall_status,
        timestamp: Time.current.iso8601,
        service: "Route API",
        checks: {
          database: db_status
        }
      }, status: http_status
    end

    private

    # 데이터베이스 연결 상태 확인
    def check_database_connection
      # 간단한 쿼리로 DB 연결 테스트
      ActiveRecord::Base.connection.execute("SELECT 1")
      {
        status: "ok",
        message: "Database connection successful"
      }
    rescue StandardError => e
      # DB 연결 실패 시
      {
        status: "error",
        message: "Database connection failed: #{e.message}"
      }
    end
  end
end