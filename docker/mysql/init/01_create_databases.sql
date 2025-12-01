-- 테스트 데이터베이스 생성
CREATE DATABASE IF NOT EXISTS route_api_test;

-- 사용자에게 권한 부여
GRANT ALL PRIVILEGES ON route_api_development.* TO 'route_api'@'%';
GRANT ALL PRIVILEGES ON route_api_test.* TO 'route_api'@'%';
FLUSH PRIVILEGES;
