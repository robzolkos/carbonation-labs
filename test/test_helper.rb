ENV["RAILS_ENV"] ||= "test"

# Stub API credentials for tests - always use fake values
ENV["FIZZY_API_TOKEN"] = "test_token"
ENV["FIZZY_ACCOUNT_SLUG"] = "test_account"
ENV["OPENROUTER_API_KEY"] = "test_openrouter_key"

require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
