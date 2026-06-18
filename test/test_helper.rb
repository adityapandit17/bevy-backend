ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Load support files
Dir[Rails.root.join("test", "support", "**", "*.rb")].each { |f| require f }

module ActiveSupport
  class TestCase
    # Run tests sequentially to avoid pg gem segfaults with parallel workers on Ruby 4.x
    parallelize(workers: 1)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    include TestHelpers

    setup do
      ActsAsTenant.current_tenant = companies(:one)
    end

    teardown do
      ActsAsTenant.current_tenant = nil
    end

    # BDD-style helpers for Given/When/Then readability
    alias_method :given, :setup
    alias_method :when_i, :tap
    alias_method :then_it, :tap
  end
end

# Avoid accidental Google Calendar API calls (individual tests may enable explicitly)
ENV["GOOGLE_CALENDAR_ENABLED"] = "false"
