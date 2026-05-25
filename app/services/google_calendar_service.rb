# frozen_string_literal: true

require "google/apis/calendar_v3"
require "googleauth"

# Schedules interview events: platform Gmail (env) first, then company OAuth from Settings.
class GoogleCalendarService
  CALENDAR_SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR
  SEND_UPDATES = "all"
  DEFAULT_DURATION = 1.hour

  class Error < StandardError; end

  class << self
    def enabled?
      return false unless oauth_app_configured?

      platform_mode_active? || company_connected?
    end

    def platform_mode_active?
      env_fallback_configured?
    end

    def connection_mode
      return "platform" if platform_mode_active?
      return "company" if company_connected?

      "disconnected"
    end

    def platform_email
      ENV["GOOGLE_CALENDAR_PLATFORM_EMAIL"].presence ||
        ENV["GMAIL_USERNAME"].presence
    end

    def sync_interview(interview)
      return { skipped: true, reason: "disabled" } unless enabled?

      if interview.status == "scheduled"
        upsert_event(interview)
      elsif interview.google_calendar_event_id.present?
        delete_event(interview)
      else
        { skipped: true, reason: "no_event" }
      end
    rescue Google::Apis::Error, Error => e
      Rails.logger.error "[GoogleCalendar] sync failed for interview #{interview.id}: #{e.message}"
      { success: false, error: e.message }
    end

    def delete_event_by_id(event_id)
      return { skipped: true, reason: "disabled" } unless enabled?
      return { skipped: true, reason: "no_event_id" } if event_id.blank?

      client.delete_event(calendar_id, event_id, send_updates: SEND_UPDATES)
      { success: true, deleted: true }
    rescue Google::Apis::ClientError => e
      return { success: true, deleted: true } if e.status_code == 404

      Rails.logger.error "[GoogleCalendar] delete failed for event #{event_id}: #{e.message}"
      { success: false, error: e.message }
    end

    private

    def oauth_app_configured?
      ENV["GOOGLE_CALENDAR_CLIENT_ID"].present? &&
        ENV["GOOGLE_CALENDAR_CLIENT_SECRET"].present?
    end

    def company_connected?
      company&.google_calendar_connected?
    end

    def env_fallback_configured?
      ENV["GOOGLE_CALENDAR_ENABLED"] == "true" && ENV["GOOGLE_CALENDAR_REFRESH_TOKEN"].present?
    end

    def company
      @company ||= Company.first
    end

    def upsert_event(interview)
      event = build_event(interview)
      event_options = {
        conference_data_version: conference_data_version(interview),
        send_updates: SEND_UPDATES
      }

      if interview.google_calendar_event_id.present?
        result = client.update_event(
          calendar_id,
          interview.google_calendar_event_id,
          event,
          **event_options
        )
      else
        result = client.insert_event(
          calendar_id,
          event,
          **event_options
        )
      end

      meet_link = extract_meet_link(result)
      interview.update_columns(
        google_calendar_event_id: result.id,
        google_calendar_html_link: result.html_link,
        google_meet_link: meet_link
      )

      { success: true, event_id: result.id, html_link: result.html_link, meet_link: meet_link }
    end

    def delete_event(interview)
      event_id = interview.google_calendar_event_id
      result = delete_event_by_id(event_id)
      interview.update_columns(
        google_calendar_event_id: nil,
        google_calendar_html_link: nil,
        google_meet_link: nil
      ) if result[:success]
      result
    end

    def build_event(interview)
      start_at, end_at = event_window(interview)
      tz = time_zone

      Google::Apis::CalendarV3::Event.new(
        summary: event_summary(interview),
        description: event_description(interview),
        location: event_location(interview),
        start: Google::Apis::CalendarV3::EventDateTime.new(
          date_time: start_at.iso8601,
          time_zone: tz
        ),
        end: Google::Apis::CalendarV3::EventDateTime.new(
          date_time: end_at.iso8601,
          time_zone: tz
        ),
        attendees: build_attendees(interview),
        reminders: Google::Apis::CalendarV3::Event::Reminders.new(
          use_default: true
        ),
        conference_data: conference_data(interview)
      )
    end

    def event_summary(interview)
      candidate_name = interview.candidate&.name || "Candidate"
      "#{candidate_name} — #{interview.interview_type.titleize} Interview"
    end

    def event_description(interview)
      candidate = interview.candidate
      lines = [
        "Interview scheduled via BevyHR.",
        "",
        "Candidate: #{candidate&.name}",
        "Type: #{interview.interview_type.titleize}",
        "Interviewer: #{interview.interviewer}",
        "Status: #{interview.status.titleize}"
      ]
      lines << "Notes: #{interview.notes}" if interview.notes.present?
      lines << ""
      lines << "Interview ID: #{interview.id}"
      lines.join("\n")
    end

    def event_location(interview)
      case interview.interview_type
      when "onsite"
        "On-site"
      when "phone"
        "Phone"
      when "video"
        "Google Meet (link in calendar invite)"
      end
    end

    def event_window(interview)
      start_at = interview.scheduled_datetime.in_time_zone(time_zone)
      duration = ENV.fetch("GOOGLE_CALENDAR_EVENT_DURATION_MINUTES", "60").to_i.minutes
      [ start_at, start_at + duration ]
    end

    def build_attendees(interview)
      emails = []
      candidate_email = interview.candidate&.email
      emails << candidate_email if candidate_email.present?

      interviewer_email = interviewer_employee_email(interview)
      emails << interviewer_email if interviewer_email.present?

      emails.uniq.map do |email|
        Google::Apis::CalendarV3::EventAttendee.new(email: email)
      end
    end

    def interviewer_employee_email(interview)
      if interview.respond_to?(:interviewer_employee_id) && interview.interviewer_employee_id.present?
        return Employee.find_by(id: interview.interviewer_employee_id)&.email
      end

      Employee.where(
        "LOWER(TRIM(first_name || ' ' || last_name)) = ?",
        interview.interviewer&.downcase&.strip
      ).first&.email
    end

    def conference_data(interview)
      return nil unless interview.interview_type == "video"

      Google::Apis::CalendarV3::ConferenceData.new(
        create_request: Google::Apis::CalendarV3::CreateConferenceRequest.new(
          request_id: "bevyhr-interview-#{interview.id}-#{SecureRandom.hex(4)}",
          conference_solution_key: Google::Apis::CalendarV3::ConferenceSolutionKey.new(
            type: "hangoutsMeet"
          )
        )
      )
    end

    def conference_data_version(interview)
      interview.interview_type == "video" ? 1 : 0
    end

    def extract_meet_link(event)
      entry_points = event.conference_data&.entry_points
      return nil unless entry_points

      video = entry_points.find { |ep| ep.entry_point_type == "video" }
      video&.uri
    end

    def client
      service = Google::Apis::CalendarV3::CalendarService.new
      service.authorization = build_authorizer
      service
    end

    def build_authorizer
      if platform_mode_active?
        build_env_authorizer
      elsif company&.google_calendar_connected?
        build_company_authorizer(company)
      else
        raise Error, "Google Calendar is not connected"
      end
    end

    def build_company_authorizer(company_record)
      creds = Google::Auth::UserRefreshCredentials.new(
        client_id: ENV["GOOGLE_CALENDAR_CLIENT_ID"],
        client_secret: ENV["GOOGLE_CALENDAR_CLIENT_SECRET"],
        scope: CALENDAR_SCOPE,
        refresh_token: company_record.google_calendar_refresh_token,
        access_token: company_record.google_calendar_access_token,
        expiration_time_millis: company_record.google_calendar_token_expires_at&.to_i&.*(1000)
      )
      creds.on_refresh = proc { |refreshed| persist_company_tokens(company_record, refreshed) }
      creds
    end

    def build_env_authorizer
      Google::Auth::UserRefreshCredentials.new(
        client_id: ENV["GOOGLE_CALENDAR_CLIENT_ID"],
        client_secret: ENV["GOOGLE_CALENDAR_CLIENT_SECRET"],
        scope: CALENDAR_SCOPE,
        refresh_token: ENV["GOOGLE_CALENDAR_REFRESH_TOKEN"]
      )
    end

    def persist_company_tokens(company_record, creds)
      company_record.update_columns(
        google_calendar_access_token: creds.access_token,
        google_calendar_token_expires_at: creds.expires_at ? Time.zone.at(creds.expires_at) : nil
      )
    end

    def calendar_id
      ENV.fetch("GOOGLE_CALENDAR_ID", "primary")
    end

    def time_zone
      if platform_mode_active?
        return ENV.fetch("GOOGLE_CALENDAR_TIME_ZONE", Time.zone.tzinfo.name)
      end

      company&.timezone.presence ||
        ENV.fetch("GOOGLE_CALENDAR_TIME_ZONE", Time.zone.tzinfo.name)
    end
  end
end
