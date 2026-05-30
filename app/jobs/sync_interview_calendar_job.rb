# frozen_string_literal: true

class SyncInterviewCalendarJob < ApplicationJob
  queue_as :default

  # google_calendar_event_id: used after interview destroy when the record is gone
  def perform(interview_id, google_calendar_event_id: nil)
    if google_calendar_event_id.present?
      GoogleCalendarService.delete_event_by_id(google_calendar_event_id)
      return
    end

    interview = Interview.includes(:candidate, :interviewer_employee).find_by(id: interview_id)
    return unless interview

    result = GoogleCalendarService.sync_interview(interview)
    GoogleCalendarService.apply_sync_result!(interview, result)
  end
end
