require "test_helper"

class AttendanceSessionTest < ActiveSupport::TestCase
  def setup
    @employee = employees(:one)
    @attendance_record = AttendanceRecord.create!(
      employee: @employee,
      date: Date.current,
      status: "present"
    )
    @session = AttendanceSession.new(
      attendance_record: @attendance_record,
      check_in: Time.current.change(hour: 9, min: 0),
      check_out: Time.current.change(hour: 17, min: 0)
    )
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @session.valid?
  end

  test "should be valid with only check_in (active session)" do
    @session.check_out = nil
    assert @session.valid?
  end

  # ── Associations ──────────────────────────────────────────────────────────
  test "should belong to attendance_record" do
    assert_respond_to @session, :attendance_record
  end

  test "should require attendance_record" do
    @session.attendance_record = nil
    assert_not @session.valid?
  end

  # ── Callbacks: session_hours calculation ─────────────────────────────────
  test "calculates session_hours on save when both check_in and check_out present" do
    @session.save!
    assert_in_delta 8.0, @session.reload.session_hours.to_f, 0.05
  end

  test "does not calculate session_hours when check_out is nil" do
    @session.check_out = nil
    @session.save!
    assert_nil @session.reload.session_hours
  end

  test "stores minimum session_hours of 0.01 for very short sessions" do
    @session.check_in = Time.current
    @session.check_out = @session.check_in + 30.seconds
    @session.save!
    assert_equal 0.01, @session.reload.session_hours.to_f
  end

  # ── Callback: updates parent attendance_record working_hours ─────────────
  test "after_save updates parent attendance_record working_hours" do
    @session.save!
    @attendance_record.reload
    assert @attendance_record.working_hours.to_f > 0
  end

  test "multiple sessions sum into parent working_hours" do
    morning = AttendanceSession.create!(
      attendance_record: @attendance_record,
      check_in: Time.current.change(hour: 9),
      check_out: Time.current.change(hour: 13)
    )
    afternoon = AttendanceSession.create!(
      attendance_record: @attendance_record,
      check_in: Time.current.change(hour: 14),
      check_out: Time.current.change(hour: 18)
    )
    @attendance_record.reload
    total = morning.session_hours.to_f + afternoon.session_hours.to_f
    assert_in_delta total, @attendance_record.working_hours.to_f, 0.1
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create attendance session" do
    assert_difference("AttendanceSession.count") { @session.save! }
  end

  test "should update check_out" do
    @session.check_out = nil
    @session.save!
    @session.update!(check_out: Time.current.change(hour: 18))
    assert_not_nil @session.reload.check_out
  end

  test "should destroy attendance session" do
    @session.save!
    assert_difference("AttendanceSession.count", -1) { @session.destroy }
  end
end
