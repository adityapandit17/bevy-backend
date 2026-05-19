require "test_helper"

class AttendanceRecordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    travel_to Time.zone.parse("2025-07-29 09:30:00")
    @attendance_record = attendance_records(:one)
    @employee = employees(:one)
    @other_employee = employees(:two)
    setup_manager_team!
  end

  teardown do
    travel_back
  end

  # --- Authentication ---

  test "index requires authentication" do
    without_authentication do
      get attendance_records_url
    end
    assert_json_unauthorized
  end

  test "clock_in requires authentication" do
    without_authentication do
      post "/employees/#{@employee.id}/attendance_records/clock_in"
    end
    assert_json_unauthorized
  end

  test "today requires authentication" do
    without_authentication do
      get today_attendance_records_url, params: { employee_id: @employee.id }
    end
    assert_json_unauthorized
  end

  # --- Authorization: index ---

  test "index forbidden without attendance_records.index permission" do
    user = create_api_user(permissions: [])
    sign_in_as(user)

    get attendance_records_url
    assert_json_forbidden
  end

  test "employee index returns only own attendance records" do
    sign_in_as(@employee_user)

    get attendance_records_url
    assert_response :success

    ids = json_response.map { |r| r["employee_id"] }.uniq
    assert_equal [@report_employee.id], ids
  end

  test "employee cannot index another employee via employee_id param" do
    sign_in_as(@employee_user)

    get attendance_records_url, params: { employee_id: @other_employee.id }
    assert_response :success
    assert_empty json_response
  end

  test "hr user can view all attendance and filter by employee" do
    sign_in_as(@hr_user)

    get attendance_records_url, params: { employee_id: @other_employee.id }
    assert_response :success

    ids = json_response.map { |r| r["employee_id"] }.uniq
    assert_includes ids, @other_employee.id
  end

  # --- Authorization: clock in / out ---

  test "employee can clock in for self" do
    sign_in_as(@employee_user)

    post "/employees/#{@report_employee.id}/attendance_records/clock_in"
    assert_response :success
    assert_equal "Clock-in successful", json_response["message"]
  end

  test "employee cannot clock in for another employee" do
    sign_in_as(@employee_user)

    post "/employees/#{@other_employee.id}/attendance_records/clock_in"
    assert_json_forbidden
    assert_match(/own attendance/i, json_response["error"])
  end

  test "employee can clock out for self after clock in" do
    sign_in_as(@employee_user)

    post "/employees/#{@report_employee.id}/attendance_records/clock_in"
    assert_response :success

    post "/employees/#{@report_employee.id}/attendance_records/clock_out"
    assert_response :success
    assert_equal "Clock-out successful", json_response["message"]
  end

  test "clock_in returns not found for invalid employee" do
    sign_in_as(@employee_user)

    post "/employees/0/attendance_records/clock_in"
    assert_response :not_found
  end

  # --- Authorization: today / stats / calendar ---

  test "employee can view own today attendance" do
    sign_in_as(@employee_user)

    get today_attendance_records_url, params: { employee_id: @report_employee.id }
    assert_response :success
    assert_equal @report_employee.id, json_response["employee_id"]
  end

  test "employee cannot view another employee today attendance" do
    sign_in_as(@employee_user)

    get today_attendance_records_url, params: { employee_id: @other_employee.id }
    assert_json_forbidden
  end

  test "employee can view own stats" do
    sign_in_as(@employee_user)

    get stats_attendance_records_url, params: {
      employee_id: @report_employee.id,
      start_date: Date.current.beginning_of_month,
      end_date: Date.current.end_of_month
    }
    assert_response :success
    assert json_response.key?("total_days")
  end

  test "employee cannot view another employee stats" do
    sign_in_as(@employee_user)

    get stats_attendance_records_url, params: { employee_id: @other_employee.id }
    assert_json_forbidden
  end

  test "employee can view own calendar with days and compliance" do
    sign_in_as(@employee_user)

    get calendar_attendance_records_url, params: {
      employee_id: @report_employee.id,
      start_date: Date.current.beginning_of_month,
      end_date: Date.current.end_of_month
    }
    assert_response :success
    assert json_response["days"].is_a?(Array)
    assert json_response["compliance"].present?
  end

  test "hr can view any employee today attendance" do
    sign_in_as(@hr_user)

    get today_attendance_records_url, params: { employee_id: @other_employee.id }
    assert_response :success
  end

  # --- CRUD (admin default auth) ---

  test "admin can get index" do
    get attendance_records_url
    assert_response :success
  end

  test "admin can get show" do
    get attendance_record_url(@attendance_record)
    assert_response :success
  end

  test "admin can create attendance record" do
    assert_difference("AttendanceRecord.count") do
      post attendance_records_url, params: {
        attendance_record: {
          employee_id: @employee.id,
          date: Date.current - 1.day,
          status: "present"
        }
      }
    end
    assert_response :created
  end

  test "admin can update attendance record" do
    patch attendance_record_url(@attendance_record), params: {
      attendance_record: { status: "late" }
    }
    assert_response :success
    assert_equal "late", @attendance_record.reload.status
  end

  test "admin can destroy attendance record" do
    record = AttendanceRecord.create!(
      employee: @employee,
      date: Date.current - 3.days,
      status: "present"
    )

    assert_difference("AttendanceRecord.count", -1) do
      delete attendance_record_url(record)
    end
    assert_response :success
  end

  test "index rejects invalid date format" do
    sign_in_as(@hr_user)

    get attendance_records_url, params: { date: "not-a-date" }
    assert_response :bad_request
    assert_match(/invalid date/i, json_response["error"])
  end
end
