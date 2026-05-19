require "test_helper"

class AttendanceComplianceTest < ActionDispatch::IntegrationTest
  setup do
    travel_to Time.zone.parse("2025-07-29 10:00:00")
    @employee = employees(:one)
    setup_manager_team!

    company = Company.first || Company.create!(
      name: "Test Co",
      code: "TCMP",
      industry: "Technology",
      employee_count: "50",
      timezone: "UTC",
      currency: "USD"
    )
    company.update!(weekly_working_hours: 40, work_start_time: "09:00", work_end_time: "18:00")

    @month_start = Date.current.beginning_of_month.iso8601
    @month_end = Date.current.end_of_month.iso8601
  end

  teardown do
    travel_back
  end

  # --- calendar ---

  test "calendar requires authentication" do
    without_authentication do
      get calendar_attendance_records_url, params: {
        employee_id: @employee.id,
        start_date: @month_start,
        end_date: @month_end
      }
    end
    assert_json_unauthorized
  end

  test "calendar forbidden for another employee" do
    sign_in_as(@employee_user)

    get calendar_attendance_records_url, params: {
      employee_id: employees(:two).id,
      start_date: @month_start,
      end_date: @month_end
    }
    assert_json_forbidden
  end

  test "calendar returns days and compliance for own employee" do
    sign_in_as(@employee_user)

    get calendar_attendance_records_url, params: {
      employee_id: @report_employee.id,
      start_date: @month_start,
      end_date: @month_end
    }

    assert_response :success
    assert json_response["days"].is_a?(Array)
    assert json_response["compliance"].present?
    assert json_response["compliance"]["weekly_working_hours"].present?
    assert json_response["compliance"]["total_hours_worked"].present?
    assert json_response["compliance"]["hours_behind_schedule"].present?

    present_day = json_response["days"].find { |d| d["date"] == "2025-07-29" }
    assert_equal "present", present_day["indicator"]
  end

  # --- stats ---

  test "stats includes compliance block" do
    sign_in_as(@employee_user)

    get stats_attendance_records_url, params: {
      employee_id: @report_employee.id,
      start_date: @month_start,
      end_date: @month_end
    }

    assert_response :success
    assert json_response["compliance"].present?
    assert_equal json_response["compliance"]["total_hours_worked"], json_response["total_working_hours"]
    assert_equal json_response["compliance"]["average_daily_hours"], json_response["average_working_hours"]
  end

  # --- compliance_report ---

  test "compliance_report requires authentication" do
    without_authentication do
      get compliance_report_attendance_records_url, params: {
        start_date: @month_start,
        end_date: @month_end
      }
    end
    assert_json_unauthorized
  end

  test "compliance_report forbidden without admin or reports permission" do
    sign_in_as(@employee_user)

    get compliance_report_attendance_records_url, params: {
      start_date: @month_start,
      end_date: @month_end
    }
    assert_json_forbidden
  end

  test "compliance_report succeeds for hr user" do
    sign_in_as(@hr_user)

    get compliance_report_attendance_records_url, params: {
      start_date: @month_start,
      end_date: @month_end
    }

    assert_response :success
    assert json_response["employees"].is_a?(Array)
    assert json_response["summary"].present?
    assert_equal 40.0, json_response["weekly_working_hours"]
    assert json_response["summary"]["total_employees"].positive?

    employee_row = json_response["employees"].find { |e| e["employee_id"] == @report_employee.id }
    assert employee_row.present?
    assert employee_row.key?("hours_behind_schedule")
    assert employee_row.key?("compliance_percent")
  end

  test "compliance_report succeeds with reports.index permission" do
    reporter = create_api_user(permissions: %w[reports.index])
    sign_in_as(reporter)

    get compliance_report_attendance_records_url, params: {
      start_date: @month_start,
      end_date: @month_end
    }
    assert_response :success
  end

  test "default admin can access compliance_report" do
    get compliance_report_attendance_records_url, params: {
      start_date: @month_start,
      end_date: @month_end
    }
    assert_response :success
  end
end
