# frozen_string_literal: true

require "test_helper"

class SyncInterviewCalendarJobTest < ActiveJob::TestCase
  test "delegates to GoogleCalendarService for interview id" do
    interview = interviews(:one)
    called = false

    singleton = GoogleCalendarService.singleton_class
    original = singleton.instance_method(:sync_interview)
    singleton.define_method(:sync_interview) { |i| called = (i.id == interview.id) }
    SyncInterviewCalendarJob.perform_now(interview.id)
    singleton.define_method(:sync_interview, original)
    assert called
  end

  test "deletes by event id when interview is gone" do
    called = false

    singleton = GoogleCalendarService.singleton_class
    original = singleton.instance_method(:delete_event_by_id)
    singleton.define_method(:delete_event_by_id) { |id| called = (id == "evt_99") }
    SyncInterviewCalendarJob.perform_now(nil, google_calendar_event_id: "evt_99")
    singleton.define_method(:delete_event_by_id, original)
    assert called
  end
end
