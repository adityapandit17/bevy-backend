require "test_helper"

class PerformanceGoalTest < ActiveSupport::TestCase
  def setup
    @employee = employees(:one)
    @goal = PerformanceGoal.new(
      employee: @employee,
      title: "Improve Code Coverage",
      description: "Increase test coverage from 60% to 90%",
      target: "90% test coverage",
      progress: 0,
      status: "not_started",
      due_date: 3.months.from_now.to_date
    )
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @goal.valid?
  end

  # ── Presence validations ──────────────────────────────────────────────────
  test "should require title" do
    @goal.title = nil
    assert_not @goal.valid?
    assert_includes @goal.errors[:title], "can't be blank"
  end

  test "should require description" do
    @goal.description = nil
    assert_not @goal.valid?
    assert_includes @goal.errors[:description], "can't be blank"
  end

  test "should require target" do
    @goal.target = nil
    assert_not @goal.valid?
    assert_includes @goal.errors[:target], "can't be blank"
  end

  test "should require progress" do
    @goal.progress = nil
    assert_not @goal.valid?
    assert_includes @goal.errors[:progress], "can't be blank"
  end

  test "should require status" do
    @goal.status = nil
    assert_not @goal.valid?
    assert_includes @goal.errors[:status], "can't be blank"
  end

  test "should require due_date" do
    @goal.due_date = nil
    assert_not @goal.valid?
    assert_includes @goal.errors[:due_date], "can't be blank"
  end

  # ── Inclusion / numericality validations ──────────────────────────────────
  test "should reject invalid status" do
    @goal.status = "unknown"
    assert_not @goal.valid?
    assert_includes @goal.errors[:status], "is not included in the list"
  end

  test "should accept all valid statuses" do
    %w[not_started in_progress completed overdue cancelled].each do |s|
      @goal.status = s
      @goal.progress = s == "completed" ? 100 : 0
      assert @goal.valid?, "#{s} should be valid"
    end
  end

  test "should reject progress below 0" do
    @goal.progress = -1
    assert_not @goal.valid?
  end

  test "should reject progress above 100" do
    @goal.progress = 101
    assert_not @goal.valid?
  end

  test "should accept progress at boundaries 0 and 100" do
    @goal.progress = 0
    assert @goal.valid?
    @goal.progress = 100
    assert @goal.valid?
  end

  # ── Associations ──────────────────────────────────────────────────────────
  test "should belong to employee" do
    assert_respond_to @goal, :employee
  end

  test "should require employee" do
    @goal.employee = nil
    assert_not @goal.valid?
  end

  # ── Callbacks ─────────────────────────────────────────────────────────────
  test "sets status to completed when progress reaches 100" do
    @goal.progress = 100
    @goal.save!
    assert_equal "completed", @goal.reload.status
  end

  test "sets status to in_progress when progress is between 1 and 99" do
    @goal.progress = 50
    @goal.status = "not_started"
    @goal.save!
    assert_equal "in_progress", @goal.reload.status
  end

  test "sets status to overdue for past due_date non-completed goals" do
    @goal.due_date = 1.day.ago.to_date
    @goal.progress = 30
    @goal.status = "in_progress"
    @goal.save!
    assert_equal "overdue", @goal.reload.status
  end

  # ── Scopes ────────────────────────────────────────────────────────────────
  test "completed scope returns only completed goals" do
    @goal.progress = 100
    @goal.save!
    assert_includes PerformanceGoal.completed, @goal
  end

  test "in_progress scope returns in_progress goals" do
    @goal.progress = 50
    @goal.status = "in_progress"
    @goal.save!
    assert_includes PerformanceGoal.in_progress, @goal
  end

  test "overdue scope returns goals with past due_date that are not completed" do
    @goal.due_date = 5.days.ago.to_date
    @goal.progress = 20
    @goal.status = "in_progress"
    @goal.save!
    # After callback, status becomes 'overdue'
    assert_includes PerformanceGoal.overdue, @goal
  end

  test "by_employee scope filters by employee" do
    @goal.save!
    other = PerformanceGoal.create!(
      employee: employees(:two),
      title: "Other Goal",
      description: "Other",
      target: "Done",
      progress: 0,
      status: "not_started",
      due_date: 1.month.from_now.to_date
    )
    assert_includes PerformanceGoal.by_employee(@employee.id), @goal
    assert_not_includes PerformanceGoal.by_employee(@employee.id), other
  end

  # ── Instance methods ──────────────────────────────────────────────────────
  test "not_started? returns true when status is not_started" do
    @goal.status = "not_started"
    assert @goal.not_started?
  end

  test "in_progress? returns true when status is in_progress" do
    @goal.status = "in_progress"
    assert @goal.in_progress?
  end

  test "completed? returns true when status is completed" do
    @goal.status = "completed"
    assert @goal.completed?
  end

  test "is_overdue? returns true when due_date is past and not completed" do
    @goal.due_date = 1.day.ago.to_date
    @goal.status = "in_progress"
    assert @goal.is_overdue?
  end

  test "is_overdue? returns false when due_date is in the future" do
    @goal.due_date = 1.month.from_now.to_date
    assert_not @goal.is_overdue?
  end

  test "days_until_due returns nil for completed goals" do
    @goal.status = "completed"
    assert_nil @goal.days_until_due
  end

  test "days_until_due returns positive integer for future due_date" do
    @goal.due_date = 10.days.from_now.to_date
    assert @goal.days_until_due > 0
  end

  test "status_color returns green for completed" do
    @goal.status = "completed"
    assert_equal "green", @goal.status_color
  end

  test "status_color returns red for overdue" do
    @goal.status = "overdue"
    assert_equal "red", @goal.status_color
  end

  test "status_color returns blue for in_progress" do
    @goal.status = "in_progress"
    assert_equal "blue", @goal.status_color
  end

  test "formatted_due_date returns readable date" do
    @goal.due_date = Date.new(2024, 12, 31)
    assert_equal "December 31, 2024", @goal.formatted_due_date
  end

  test "employee_name delegates to employee" do
    assert_equal @employee.name, @goal.employee_name
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create performance goal" do
    assert_difference("PerformanceGoal.count") { @goal.save! }
  end

  test "should update performance goal" do
    @goal.save!
    @goal.update!(title: "Updated Title")
    assert_equal "Updated Title", @goal.reload.title
  end

  test "should destroy performance goal" do
    @goal.save!
    assert_difference("PerformanceGoal.count", -1) { @goal.destroy }
  end
end
