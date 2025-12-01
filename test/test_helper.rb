ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # FactoryBot methods (create, build, build_stubbed, attributes_for)
    include FactoryBot::Syntax::Methods

    # 각 테스트 전에 DB를 정리 (테스트 격리)
    setup do
      DatabaseCleaner.strategy = :transaction if defined?(DatabaseCleaner)
    end

    # Add more helper methods to be used by all tests here...
  end
end
