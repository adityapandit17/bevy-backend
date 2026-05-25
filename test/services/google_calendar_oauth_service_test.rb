# frozen_string_literal: true

require "test_helper"

class GoogleCalendarOauthServiceTest < ActiveSupport::TestCase
  setup do
    ENV["GOOGLE_CALENDAR_CLIENT_ID"] = "test-client-id"
    ENV["GOOGLE_CALENDAR_CLIENT_SECRET"] = "test-secret"
    ENV.delete("GOOGLE_CALENDAR_ENABLED")
    ENV.delete("GOOGLE_CALENDAR_REFRESH_TOKEN")
    @user = find_or_create_test_admin
  end

  teardown do
    ENV.delete("GOOGLE_CALENDAR_ENABLED")
    ENV.delete("GOOGLE_CALENDAR_REFRESH_TOKEN")
    ENV.delete("GMAIL_USERNAME")
    GoogleCalendarService.send(:remove_instance_variable, :@company) if GoogleCalendarService.instance_variable_defined?(:@company)
  end

  test "oauth_configured? requires client id and secret" do
    assert GoogleCalendarOauthService.oauth_configured?
    ENV["GOOGLE_CALENDAR_CLIENT_ID"] = ""
    assert_not GoogleCalendarOauthService.oauth_configured?
  end

  test "authorization_url includes google accounts host" do
    url = GoogleCalendarOauthService.authorization_url(@user)
    assert_includes url, "accounts.google.com/o/oauth2/auth"
    assert_includes url, "state="
  end

  test "status_for reflects company connection" do
    company = companies(:one)
    company.update_columns(
      google_calendar_refresh_token: "rt",
      google_calendar_email: "cal@example.com",
      google_calendar_connected_at: Time.current
    )

    status = GoogleCalendarOauthService.status_for(company)
    assert status[:connected]
    assert_equal "company", status[:mode]
    assert_equal "cal@example.com", status[:email]
    assert_not status[:platform_managed]
  end

  test "status_for reflects platform mode from env" do
    ENV["GOOGLE_CALENDAR_ENABLED"] = "true"
    ENV["GOOGLE_CALENDAR_REFRESH_TOKEN"] = "platform-rt"
    ENV["GMAIL_USERNAME"] = "bevy@gmail.com"

    company = companies(:one)
    company.update_columns(google_calendar_refresh_token: nil)

    status = GoogleCalendarOauthService.status_for(company)
    assert status[:connected]
    assert_equal "platform", status[:mode]
    assert_equal "bevy@gmail.com", status[:email]
    assert status[:platform_managed]
  end
end
