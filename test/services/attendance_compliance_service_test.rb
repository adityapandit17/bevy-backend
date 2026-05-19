require "test_helper"

class AttendanceComplianceServiceTest < ActiveSupport::TestCase
  setup do
    travel_to Time.zone.parse("2025-07-29 10:00:00")
    @employee = employees(:one)
    @as_of = Date.new(2025, 7, 29)
    @start = @as_of.beginning_of_month
    @end = @as_of.end_of_month

    @company = Company.first || Company.create!(
      name: "Test Co",
      code: "TST",
      industry: "Technology",
      employee_count: "50",
      timezone: "UTC",
      currency: "USD"
    )
    @company.update!(
      weekly_working_hours: 40,
      work_start_time: "09:00",
      work_end_time: "18:00",
      lunch_duration_minutes: 60
    )
  end

  teardown do
    travel_back
  end

  test "weekly and daily targets come from company settings" do
    service = AttendanceComplianceService.new(employee: @employee, as_of: @as_of)

    assert_equal 40.0, service.weekly_working_hours
    assert_equal 8.0, service.daily_target_hours
  end

  test "summary counts present day from fixture and working hours" do
    service = AttendanceComplianceService.new(
      employee: @employee,
      start_date: @start,
      end_date: @end,
      as_of: @as_of
    )
    summary = service.summary

    assert_equal 8.0, summary[:total_hours_worked]
    assert summary[:present_days] >= 1
    assert_equal 40.0, summary[:weekly_working_hours]
    assert summary[:required_hours_to_date].positive?
    assert summary[:compliance_percent] <= 100
  end

  test "summary marks absent and not_marked weekdays" do
    AttendanceRecord.create!(
      employee: @employee,
      date: Date.new(2025, 7, 28),
      status: "absent",
      working_hours: 0
    )

    service = AttendanceComplianceService.new(
      employee: @employee,
      start_date: @start,
      end_date: @end,
      as_of: @as_of
    )
    summary = service.summary

    assert summary[:absent_days] >= 1
    assert summary[:not_marked_days] >= 1
  end

  test "summary excludes approved leave days from absent and not_marked" do
    leave_start = Date.new(2025, 7, 21)
    leave_end = Date.new(2025, 7, 22)

    LeaveRequest.create!(
      employee: @employee,
      leave_type: "annual",
      start_date: leave_start,
      end_date: leave_end,
      reason: "Trip",
      status: "approved"
    )

    service = AttendanceComplianceService.new(
      employee: @employee,
      start_date: @start,
      end_date: @end,
      as_of: @as_of
    )
    summary = service.summary

    assert summary[:leave_days] >= 2
  end

  test "hours_behind_schedule increases when worked hours are below required" do
    @company.update!(weekly_working_hours: 40)

    service = AttendanceComplianceService.new(
      employee: @employee,
      start_date: @start,
      end_date: @end,
      as_of: @as_of
    )
    summary = service.summary

    assert summary[:required_hours_to_date] > summary[:total_hours_worked]
    assert summary[:hours_behind_schedule].positive?
  end

  test "calendar_days returns indicators for present absent leave and weekend" do
    LeaveRequest.create!(
      employee: @employee,
      leave_type: "sick",
      start_date: Date.new(2025, 7, 21),
      end_date: Date.new(2025, 7, 21),
      reason: "Sick",
      status: "approved"
    )

    AttendanceRecord.create!(
      employee: @employee,
      date: Date.new(2025, 7, 28),
      status: "absent",
      working_hours: 0
    )

    days = AttendanceComplianceService.new(
      employee: @employee,
      start_date: Date.new(2025, 7, 21),
      end_date: Date.new(2025, 7, 29),
      as_of: @as_of
    ).calendar_days

    by_date = days.index_by { |d| d[:date] }

    assert_equal "leave", by_date["2025-07-21"][:indicator]
    assert_equal "weekend", by_date["2025-07-27"][:indicator]
    assert_equal "absent", by_date["2025-07-28"][:indicator]
    assert_equal "present", by_date["2025-07-29"][:indicator]
  end

  test "calendar marks past weekday without record as not_marked" do
    days = AttendanceComplianceService.new(
      employee: @employee,
      start_date: Date.new(2025, 7, 1),
      end_date: Date.new(2025, 7, 3),
      as_of: @as_of
    ).calendar_days

    july_1 = days.find { |d| d[:date] == "2025-07-01" }
    assert_equal "not_marked", july_1[:indicator]
  end

  test "team_report returns employees sorted by hours behind descending" do
    AttendanceRecord.find_or_create_by!(employee: employees(:two), date: Date.new(2025, 7, 29)) do |r|
      r.status = "present"
      r.working_hours = 2.0
    end

    rows = AttendanceComplianceService.team_report(
      start_date: @start,
      end_date: @end,
      as_of: @as_of
    )

    assert rows.size >= 2
    assert rows.first[:hours_behind_schedule] >= rows.last[:hours_behind_schedule]
    assert rows.all? { |r| r.key?(:employee_name) }
    assert rows.all? { |r| r.key?(:compliance_percent) }
  end

  test "team_report filters by department when provided" do
    dept_id = @employee.department_id
    rows = AttendanceComplianceService.team_report(
      start_date: @start,
      end_date: @end,
      as_of: @as_of,
      department_id: dept_id
    )

    assert rows.all? { |r| r[:department_id] == dept_id }
  end
end
