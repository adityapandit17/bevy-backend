# frozen_string_literal: true

require "test_helper"
require "ostruct"

class GoogleCalendarServiceTest < ActiveSupport::TestCase
  setup do
    @interview = interviews(:one)
    ENV["GOOGLE_CALENDAR_ENABLED"] = "true"
    ENV["GOOGLE_CALENDAR_CLIENT_ID"] = "test-client-id"
    ENV["GOOGLE_CALENDAR_CLIENT_SECRET"] = "test-secret"
    ENV["GOOGLE_CALENDAR_REFRESH_TOKEN"] = "platform-refresh-token"
    ENV["GOOGLE_CALENDAR_TIME_ZONE"] = "UTC"
    ENV["GMAIL_USERNAME"] = "platform@gmail.com"
    reset_calendar_client!
  end

  teardown do
    reset_calendar_client!
  end

  test "enabled? requires oauth app and platform or company token" do
    assert GoogleCalendarService.enabled?

    ENV.delete("GOOGLE_CALENDAR_REFRESH_TOKEN")
    ENV["GOOGLE_CALENDAR_ENABLED"] = "false"
    Company.first&.update_columns(google_calendar_refresh_token: nil)
    assert_not GoogleCalendarService.enabled?
  end

  test "platform mode takes priority over company tokens" do
    company = companies(:one)
    company.update_columns(
      google_calendar_refresh_token: "company-refresh-token",
      google_calendar_email: "company@example.com"
    )

    assert_equal "platform", GoogleCalendarService.connection_mode
    assert GoogleCalendarService.platform_mode_active?
    assert_equal "platform@gmail.com", GoogleCalendarService.platform_email
  end

  test "connection_mode is company when only company connected" do
    ENV["GOOGLE_CALENDAR_ENABLED"] = "false"
    ENV.delete("GOOGLE_CALENDAR_REFRESH_TOKEN")
    GoogleCalendarService.send(:remove_instance_variable, :@company) if GoogleCalendarService.instance_variable_defined?(:@company)

    company = Company.first
    company.update_columns(
      google_calendar_refresh_token: "company-refresh-token",
      google_calendar_email: "company@example.com"
    )

    assert_equal "company", GoogleCalendarService.connection_mode
  end

  test "sync_interview skips when disabled" do
    ENV["GOOGLE_CALENDAR_ENABLED"] = "false"
    result = GoogleCalendarService.sync_interview(@interview)
    assert result[:skipped]
  end

  test "sync_interview inserts event with send_updates all" do
    mock_event = OpenStruct.new(
      id: "evt_123",
      html_link: "https://calendar.google.com/event/123",
      conference_data: OpenStruct.new(
        entry_points: [ OpenStruct.new(entry_point_type: "video", uri: "https://meet.google.com/abc-defg-hij") ]
      )
    )

    captured = {}
    fake_client = Object.new
    fake_client.define_singleton_method(:insert_event) do |_calendar_id, _event, **kwargs|
      captured[:send_updates] = kwargs[:send_updates]
      captured[:conference_data_version] = kwargs[:conference_data_version]
      mock_event
    end

    with_fake_calendar_client(fake_client) do
      @interview.update_columns(
        google_calendar_event_id: nil,
        status: "scheduled",
        interview_type: "video",
        duration_minutes: 30
      )
      result = GoogleCalendarService.sync_interview(@interview.reload)
      assert result[:success]
      assert_equal "all", captured[:send_updates]
      assert_equal 1, captured[:conference_data_version]
      assert_equal "evt_123", @interview.reload.google_calendar_event_id
    end
  end

  test "sync_interview deletes event with send_updates all" do
    @interview.update_columns(
      google_calendar_event_id: "evt_old",
      google_calendar_html_link: "https://calendar.google.com/old",
      google_meet_link: "https://meet.google.com/old",
      status: "cancelled"
    )

    captured = {}
    fake_client = Object.new
    fake_client.define_singleton_method(:delete_event) do |_calendar_id, event_id, **kwargs|
      captured[:event_id] = event_id
      captured[:send_updates] = kwargs[:send_updates]
    end

    with_fake_calendar_client(fake_client) do
      result = GoogleCalendarService.sync_interview(@interview.reload)
      assert result[:success]
      assert_equal "evt_old", captured[:event_id]
      assert_equal "all", captured[:send_updates]
      assert_nil @interview.reload.google_calendar_event_id
    end
  end

  private

  def with_fake_calendar_client(fake_client)
    GoogleCalendarService.define_singleton_method(:client) { fake_client }
    yield
  ensure
    reset_calendar_client!
  end

  def reset_calendar_client!
    GoogleCalendarService.send(:remove_instance_variable, :@company) if GoogleCalendarService.instance_variable_defined?(:@company)
    GoogleCalendarService.singleton_class.send(:remove_method, :client) if GoogleCalendarService.singleton_class.method_defined?(:client, false)
  end
end
