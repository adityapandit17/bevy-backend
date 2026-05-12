require "test_helper"

class TimesheetTest < ActiveSupport::TestCase
  def setup
    @employee = employees(:one)
    @timesheet = Timesheet.new(
      employee: @employee,
      date: Date.current,
      hours: 8.0,
      project: "Project Alpha",
      task: "Implement feature X",
      status: "pending"
    )
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @timesheet.valid?
  end

  # ── Presence validations ──────────────────────────────────────────────────
  test "should require date" do
    @timesheet.date = nil
    assert_not @timesheet.valid?
    assert_includes @timesheet.errors[:date], "can't be blank"
  end

  test "should require hours" do
    @timesheet.hours = nil
    assert_not @timesheet.valid?
    assert_includes @timesheet.errors[:hours], "can't be blank"
  end

  test "should require project" do
    @timesheet.project = nil
    assert_not @timesheet.valid?
    assert_includes @timesheet.errors[:project], "can't be blank"
  end

  test "should require task" do
    @timesheet.task = nil
    assert_not @timesheet.valid?
    assert_includes @timesheet.errors[:task], "can't be blank"
  end

  test "should require status" do
    @timesheet.status = nil
    assert_not @timesheet.valid?
    assert_includes @timesheet.errors[:status], "can't be blank"
  end

  # ── Numericality validations ──────────────────────────────────────────────
  test "should reject hours of 0 or less" do
    @timesheet.hours = 0
    assert_not @timesheet.valid?
  end

  test "should reject hours greater than 24" do
    @timesheet.hours = 25
    assert_not @timesheet.valid?
  end

  test "should accept hours at boundary values" do
    @timesheet.hours = 0.5
    assert @timesheet.valid?
    @timesheet.hours = 24
    assert @timesheet.valid?
  end

  # ── Inclusion validations ─────────────────────────────────────────────────
  test "should reject invalid status" do
    @timesheet.status = "draft"
    assert_not @timesheet.valid?
    assert_includes @timesheet.errors[:status], "is not included in the list"
  end

  test "should accept all valid statuses" do
    %w[pending approved rejected].each do |s|
      @timesheet.status = s
      assert @timesheet.valid?, "#{s} should be valid"
    end
  end

  # ── Associations ──────────────────────────────────────────────────────────
  test "should belong to employee" do
    assert_respond_to @timesheet, :employee
  end

  test "should require employee" do
    @timesheet.employee = nil
    assert_not @timesheet.valid?
  end

  # ── Callback: default status ──────────────────────────────────────────────
  test "sets status to pending by default on create" do
    @timesheet.status = nil
    @timesheet.save!
    assert_equal "pending", @timesheet.reload.status
  end

  # ── Scopes ────────────────────────────────────────────────────────────────
  test "approved scope returns only approved timesheets" do
    @timesheet.status = "approved"
    @timesheet.save!
    pending_ts = Timesheet.create!(
      employee: employees(:two),
      date: Date.current,
      hours: 7,
      project: "Other",
      task: "Other task",
      status: "pending"
    )
    assert_includes Timesheet.approved, @timesheet
    assert_not_includes Timesheet.approved, pending_ts
  end

  test "pending scope returns only pending timesheets" do
    @timesheet.save!
    assert_includes Timesheet.pending, @timesheet
  end

  test "rejected scope returns only rejected timesheets" do
    @timesheet.status = "rejected"
    @timesheet.save!
    assert_includes Timesheet.rejected, @timesheet
  end

  test "this_week scope includes timesheets from current week" do
    @timesheet.date = Date.current
    @timesheet.save!
    assert_includes Timesheet.this_week, @timesheet
  end

  test "this_month scope includes timesheets from current month" do
    @timesheet.date = Date.current
    @timesheet.save!
    assert_includes Timesheet.this_month, @timesheet
  end

  test "by_employee scope filters by employee" do
    @timesheet.save!
    other = Timesheet.create!(
      employee: employees(:two),
      date: Date.current,
      hours: 6,
      project: "Beta",
      task: "Bug fix",
      status: "pending"
    )
    assert_includes Timesheet.by_employee(@employee.id), @timesheet
    assert_not_includes Timesheet.by_employee(@employee.id), other
  end

  test "by_project scope filters by project name" do
    @timesheet.save!
    assert_includes Timesheet.by_project("Project Alpha"), @timesheet
  end

  # ── Instance methods ──────────────────────────────────────────────────────
  test "approved? returns true when status is approved" do
    @timesheet.status = "approved"
    assert @timesheet.approved?
  end

  test "pending? returns true when status is pending" do
    @timesheet.status = "pending"
    assert @timesheet.pending?
  end

  test "rejected? returns true when status is rejected" do
    @timesheet.status = "rejected"
    assert @timesheet.rejected?
  end

  test "status_color returns green for approved" do
    @timesheet.status = "approved"
    assert_equal "green", @timesheet.status_color
  end

  test "status_color returns yellow for pending" do
    @timesheet.status = "pending"
    assert_equal "yellow", @timesheet.status_color
  end

  test "status_color returns red for rejected" do
    @timesheet.status = "rejected"
    assert_equal "red", @timesheet.status_color
  end

  test "formatted_date returns readable date string" do
    @timesheet.date = Date.new(2024, 3, 15)
    assert_equal "March 15, 2024", @timesheet.formatted_date
  end

  test "formatted_hours returns hours with unit" do
    @timesheet.hours = 8.0
    assert_equal "8.0 hours", @timesheet.formatted_hours
  end

  test "project_task_summary returns project - task" do
    assert_equal "Project Alpha - Implement feature X", @timesheet.project_task_summary
  end

  test "can_edit? returns true for pending timesheet" do
    @timesheet.status = "pending"
    assert @timesheet.can_edit?
  end

  test "can_delete? returns true only for pending" do
    @timesheet.status = "pending"
    assert @timesheet.can_delete?
    @timesheet.status = "approved"
    assert_not @timesheet.can_delete?
  end

  test "employee_name delegates to employee" do
    assert_equal @employee.name, @timesheet.employee_name
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create timesheet" do
    assert_difference("Timesheet.count") { @timesheet.save! }
  end

  test "should update timesheet" do
    @timesheet.save!
    @timesheet.update!(hours: 7.5)
    assert_equal 7.5, @timesheet.reload.hours.to_f
  end

  test "should destroy timesheet" do
    @timesheet.save!
    assert_difference("Timesheet.count", -1) { @timesheet.destroy }
  end
end
