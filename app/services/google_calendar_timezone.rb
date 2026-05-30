# frozen_string_literal: true

module GoogleCalendarTimezone
  ALIASES = {
    "asia-kolkata" => "Asia/Kolkata",
    "utc" => "UTC",
    "america-new_york" => "America/New_York",
    "europe-london" => "Europe/London",
    "asia-singapore" => "Asia/Singapore"
  }.freeze

  module_function

  def normalize(value)
    raw = value.to_s.strip
    return ENV.fetch("GOOGLE_CALENDAR_TIME_ZONE", "UTC") if raw.blank?

    key = raw.downcase.tr(" ", "_")
    ALIASES[key] || raw
  end
end
