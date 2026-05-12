require "test_helper"

class AttendanceRecordTest < ActiveSupport::TestCase
  def setup
    @employee = employees(:one)
    @record = AttendanceRecord.new(
      employee: @employee,
      date: Date.current,
      status: "present"
    )
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @record.valid?
  end

  # ── Presence validations ──────────────────────────────────────────────────
  test "should require date" do
    @record.date = nil
    assert_not @record.valid?
    assert_includes @record.errors[:date], "can't be blank"
  end

  test "should require status" do
    @record.status = nil
    assert_not @record.valid?
    assert_includes @record.errors[:status], "can't be blank"
  end

  test "should require employee" do
    @record.employee = nil
    assert_not @record.valid?
  end

  # ── Inclusion validations ─────────────────────────────────────────────────
  test "should reject invalid status" do
    @record.status = "on_vacation"
    assert_not @record.valid?
    assert_includes @record.errors[:status], "is not included in the list"
  end

  test "should accept all valid statuses" do
    %w[present absent late half_day work_from_home early_departure].each do |s|
      @record.status = s
      assert @record.valid?, "#{s} should be valid"
    end
  end

  # ── Date validations ──────────────────────────────────────────────────────
  test "should reject future dates" do
    @record.date = Date.tomorrow
    assert_not @record.valid?
    assert_includes @record.errors[:date], "cannot be in the future"
  end

  test "should accept today's date" do
    @record.date = Date.current
    assert @record.valid?
  end

  test "should accept past dates" do
    @record.date = 1.week.ago.to_date
    assert @record.valid?
  end

  # ── Uniqueness: one record per employee per day ───────────────────────────
  test "should enforce one record per employee per day" do
    @record.save!
    dup = AttendanceRecord.new(employee: @employee, date: @record.date, status: "absent")
    assert_not dup.valid?
    assert_includes dup.errors[:employee_id], "can only have one attendance record per day"
  end

  test "should allow different employees on the same date" do
    @record.save!
    other_record = AttendanceRecord.new(
      employee: employees(:two),
      date: @record.date,
      status: "present"
    )
    assert other_record.valid?
  end

  test "should allow same employee on different dates" do
    @record.save!
    other_day = AttendanceRecord.new(
      employee: @employee,
      date: 1.day.ago.to_date,
      status: "present"
    )
    assert other_day.valid?
  end

  # ── Associations ──────────────────────────────────────────────────────────
  test "should belong to employee" do
    assert_respond_to @record, :employee
  end

  test "should have many attendance_sessions" do
    assert_respond_to @record, :attendance_sessions
  end

  # ── Scopes ────────────────────────────────────────────────────────────────
  test "present scope returns present records" do
    @record.status = "present"
    @record.save!
    absent_record = AttendanceRecord.create!(employee: employees(:two), date: Date.current, status: "absent")
    assert_includes AttendanceRecord.present, @record
    assert_not_includes AttendanceRecord.present, absent_record
  end

  test "absent scope returns absent records" do
    @record.status = "absent"
    @record.save!
    assert_includes AttendanceRecord.absent, @record
  end

  test "late scope returns late records" do
    @record.status = "late"
    @record.save!
    assert_includes AttendanceRecord.late, @record
  end

  test "half_day scope returns half_day records" do
    @record.status = "half_day"
    @record.save!
    assert_includes AttendanceRecord.half_day, @record
  end

  test "work_from_home scope returns wfh records" do
    @record.status = "work_from_home"
    @record.save!
    assert_includes AttendanceRecord.work_from_home, @record
  end

  test "by_date scope filters records by date" do
    @record.save!
    old_record = AttendanceRecord.create!(
      employee: employees(:two),
      date: 5.days.ago.to_date,
      status: "present"
    )
    results = AttendanceRecord.by_date(Date.current)
    assert_includes results, @record
    assert_not_includes results, old_record
  end

  test "by_employee scope filters by employee" do
    @record.save!
    other = AttendanceRecord.create!(employee: employees(:two), date: Date.current, status: "present")
    assert_includes AttendanceRecord.by_employee(@employee.id), @record
    assert_not_includes AttendanceRecord.by_employee(@employee.id), other
  end

  test "current_month scope includes records from this month" do
    @record.save!
    old = AttendanceRecord.create!(
      employee: employees(:two),
      date: 2.months.ago.to_date,
      status: "present"
    )
    assert_includes AttendanceRecord.current_month, @record
    assert_not_includes AttendanceRecord.current_month, old
  end

  test "recent scope includes records from last 30 days" do
    @record.save!
    assert_includes AttendanceRecord.recent, @record
  end

  # ── Instance methods ──────────────────────────────────────────────────────
  test "present? returns true when status is present" do
    @record.status = "present"
    assert @record.present?
  end

  test "absent? returns true when status is absent" do
    @record.status = "absent"
    assert @record.absent?
  end

  test "late? returns true when status is late" do
    @record.status = "late"
    assert @record.late?
  end

  test "half_day? returns true when status is half_day" do
    @record.status = "half_day"
    assert @record.half_day?
  end

  test "work_from_home? returns true when status is work_from_home" do
    @record.status = "work_from_home"
    assert @record.work_from_home?
  end

  test "overtime_hours returns 0 when working_hours is 8 or less" do
    @record.working_hours = 8.0
    assert_equal 0, @record.overtime_hours
  end

  test "overtime_hours returns excess hours over 8" do
    @record.working_hours = 10.0
    assert_equal 2, @record.overtime_hours
  end

  test "status_color returns green for present" do
    @record.status = "present"
    assert_equal "green", @record.status_color
  end

  test "status_color returns red for absent" do
    @record.status = "absent"
    assert_equal "red", @record.status_color
  end

  test "status_color returns yellow for late" do
    @record.status = "late"
    assert_equal "yellow", @record.status_color
  end

  test "status_color returns blue for half_day" do
    @record.status = "half_day"
    assert_equal "blue", @record.status_color
  end

  test "status_color returns purple for work_from_home" do
    @record.status = "work_from_home"
    assert_equal "purple", @record.status_color
  end

  test "status_label returns human-readable label" do
    {
      "present" => "Present",
      "absent" => "Absent",
      "late" => "Late",
      "half_day" => "Half Day",
      "work_from_home" => "Work from Home"
    }.each do |status, label|
      @record.status = status
      assert_equal label, @record.status_label
    end
  end

  test "employee_name delegates to employee" do
    assert_equal @employee.name, @record.employee_name
  end

  test "employee_email delegates to employee" do
    assert_equal @employee.email, @record.employee_email
  end

  # ── Class methods ─────────────────────────────────────────────────────────
  test "total_hours_for_day returns 0 when no record exists" do
    assert_equal 0.0, AttendanceRecord.total_hours_for_day(@employee.id, 10.days.ago.to_date)
  end

  test "total_hours_for_day returns stored working_hours when present" do
    @record.working_hours = 7.5
    @record.save!
    assert_equal 7.5, AttendanceRecord.total_hours_for_day(@employee.id, Date.current)
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create attendance record" do
    assert_difference("AttendanceRecord.count") { @record.save! }
  end

  test "should update attendance record" do
    @record.save!
    @record.update!(status: "late")
    assert_equal "late", @record.reload.status
  end

  test "should destroy attendance record" do
    @record.save!
    assert_difference("AttendanceRecord.count", -1) { @record.destroy }
  end
end
