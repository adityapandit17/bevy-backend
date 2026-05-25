# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class GoogleCalendarControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = find_or_create_test_admin
        @token = JwtService.generate_token(@user)
        @headers = { "Authorization" => "Bearer #{@token}", "Accept" => "application/json" }
        ENV["GOOGLE_CALENDAR_CLIENT_ID"] = "test-client-id"
        ENV["GOOGLE_CALENDAR_CLIENT_SECRET"] = "test-secret"
      end

      test "status returns connection info" do
        get api_v1_google_calendar_status_url, headers: @headers
        assert_response :success
        json = JSON.parse(response.body)
        assert json["success"]
        assert_includes json["data"].keys, "connected"
      end

      test "authorize_url requires settings update permission" do
        get api_v1_google_calendar_authorize_url_url, headers: @headers
        assert_response :success
        json = JSON.parse(response.body)
        assert json["data"]["authorization_url"].include?("accounts.google.com")
      end

      test "disconnect clears company tokens" do
        ENV.delete("GOOGLE_CALENDAR_ENABLED")
        ENV.delete("GOOGLE_CALENDAR_REFRESH_TOKEN")

        company = Company.first || companies(:one)
        company.update!(
          google_calendar_refresh_token: "rt_test",
          google_calendar_email: "hr@example.com",
          google_calendar_connected_at: Time.current
        )

        delete api_v1_google_calendar_disconnect_url, headers: @headers
        assert_response :success
        company.reload
        assert_not company.google_calendar_connected?
      end

      test "disconnect rejected when platform mode active" do
        ENV["GOOGLE_CALENDAR_ENABLED"] = "true"
        ENV["GOOGLE_CALENDAR_REFRESH_TOKEN"] = "platform-rt"

        delete api_v1_google_calendar_disconnect_url, headers: @headers
        assert_response :unprocessable_entity
        json = JSON.parse(response.body)
        assert_not json["success"]
        assert_includes json["error"], "platform"
      end
    end
  end
end
