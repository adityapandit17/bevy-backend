# frozen_string_literal: true

require "google/apis/calendar_v3"
require "googleauth"

# Schedules interview events: platform Gmail (env) first, then company OAuth from Settings.
class GoogleCalendarService
  CALENDAR_SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR
  SEND_UPDATES = "all"
  DEFAULT_DURATION_MINUTES = 60

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

    def apply_sync_result!(interview, result)
      return result if result[:skipped]

      if result[:success]
        interview.update_columns(
          calendar_synced_at: Time.current,
          calendar_sync_error: nil
        )
        return result
      end

      error_message = result[:error].presence || "Calendar sync failed"
      interview.update_columns(
        calendar_sync_error: error_message,
        calendar_synced_at: nil
      )
      raise Error, error_message
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
      attendees = build_attendees(interview)
      if attendees.empty?
        Rails.logger.warn "[GoogleCalendar] interview #{interview.id}: no attendee emails — invites will only go to organizer calendar"
      end

      event = build_event(interview, attendees)
      event_options = {
        conference_data_version: conference_data_version(interview),
        send_updates: SEND_UPDATES
      }

      result = if interview.google_calendar_event_id.present?
        client.update_event(
          calendar_id,
          interview.google_calendar_event_id,
          event,
          **event_options
        )
      else
        client.insert_event(
          calendar_id,
          event,
          **event_options
        )
      end

      meet_link = extract_meet_link(result)
      interview.update_columns(
        google_calendar_event_id: result.id,
        google_calendar_html_link: result.html_link,
        google_meet_link: meet_link,
        calendar_synced_at: Time.current,
        calendar_sync_error: nil
      )

      Rails.logger.info "[GoogleCalendar] synced interview #{interview.id} event=#{result.id} attendees=#{attendees.size}"

      { success: true, event_id: result.id, html_link: result.html_link, meet_link: meet_link }
    end

    def delete_event(interview)
      event_id = interview.google_calendar_event_id
      result = delete_event_by_id(event_id)
      interview.update_columns(
        google_calendar_event_id: nil,
        google_calendar_html_link: nil,
        google_meet_link: nil,
        calendar_sync_error: nil
      ) if result[:success]
      result
    end

    def build_event(interview, attendees)
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
        attendees: attendees,
        organizer: event_organizer,
        guests_can_see_other_guests: true,
        reminders: Google::Apis::CalendarV3::Event::Reminders.new(
          use_default: true
        ),
        conference_data: conference_data(interview)
      )
    end

    def event_organizer
      email = calendar_owner_email
      return nil if email.blank?

      Google::Apis::CalendarV3::Event::Organizer.new(
        email: email,
        self: true
      )
    end

    def calendar_owner_email
      if platform_mode_active?
        platform_email
      else
        company&.google_calendar_email
      end
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
        "Duration: #{interview_duration_minutes(interview)} minutes",
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
        "Phone interview"
      when "video"
        "Google Meet (link in calendar invite)"
      end
    end

    def event_window(interview)
      start_at = interview.scheduled_datetime
      duration = interview_duration_minutes(interview).minutes
      [ start_at, start_at + duration ]
    end

    def interview_duration_minutes(interview)
      minutes = interview.duration_minutes.to_i
      minutes = DEFAULT_DURATION_MINUTES if minutes <= 0
      minutes
    end

    def build_attendees(interview)
      emails = []
      candidate_email = interview.candidate&.email&.strip
      emails << candidate_email if candidate_email.present?

      interviewer_email = interviewer_employee_email(interview)&.strip
      emails << interviewer_email if interviewer_email.present?

      owner = calendar_owner_email&.strip
      emails << owner if owner.present?

      emails.uniq.reject(&:blank?).map do |email|
        Google::Apis::CalendarV3::EventAttendee.new(
          email: email,
          response_status: "needsAction"
        )
      end
    end

    def interviewer_employee_email(interview)
      if interview.interviewer_employee_id.present?
        return interview.interviewer_employee&.email
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
      service.authorization = authorizer_with_fresh_token!
      service
    end

    def authorizer_with_fresh_token!
      creds = build_authorizer
      creds.fetch_access_token!
      creds
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
      expires_at = company_record.google_calendar_token_expires_at
      expiration_ms = expires_at ? (expires_at.to_f * 1000).to_i : nil

      creds = Google::Auth::UserRefreshCredentials.new(
        client_id: ENV["GOOGLE_CALENDAR_CLIENT_ID"],
        client_secret: ENV["GOOGLE_CALENDAR_CLIENT_SECRET"],
        scope: CALENDAR_SCOPE,
        refresh_token: company_record.google_calendar_refresh_token,
        access_token: company_record.google_calendar_access_token,
        expiration_time_millis: expiration_ms
      )
      creds.on_refresh do |refreshed|
        persist_company_tokens(company_record, refreshed)
      end
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
      raw = if platform_mode_active?
        ENV.fetch("GOOGLE_CALENDAR_TIME_ZONE", Time.zone.tzinfo.name)
      else
        company&.timezone.presence || ENV.fetch("GOOGLE_CALENDAR_TIME_ZONE", Time.zone.tzinfo.name)
      end

      GoogleCalendarTimezone.normalize(raw)
    end
  end
end
