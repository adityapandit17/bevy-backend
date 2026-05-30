# frozen_string_literal: true

require "test_helper"

class GoogleCalendarTimezoneTest < ActiveSupport::TestCase
  test "normalize maps company setting aliases to IANA zones" do
    assert_equal "Asia/Kolkata", GoogleCalendarTimezone.normalize("asia-kolkata")
    assert_equal "America/New_York", GoogleCalendarTimezone.normalize("america-new_york")
  end

  test "normalize passes through valid IANA zones" do
    assert_equal "Asia/Kolkata", GoogleCalendarTimezone.normalize("Asia/Kolkata")
  end
end
