require "test_helper"

class OffboardingTaskTest < ActiveSupport::TestCase
  def setup
    @emp = create_test_employee(
      email: "offt.test#{SecureRandom.hex(4)}@example.com",
      phone: "9876543216"
    )
    @offboarding = OffboardingEmployee.create!(
      employee: @emp,
      last_working_day: 2.weeks.from_now.to_date,
      status: "pending",
      progress: 0
    )
    @task = OffboardingTask.new(
      offboarding_employee: @offboarding,
      title: "Return company laptop",
      description: "Return laptop and accessories to IT department",
      category: "Equipment",
      priority: "high",
      due_date: 1.week.from_now.to_date,
      assigned_to: "IT Department"
    )
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @task.valid?
  end

  # ── Presence validations ──────────────────────────────────────────────────
  test "should require title" do
    @task.title = nil
    assert_not @task.valid?
    assert_includes @task.errors[:title], "can't be blank"
  end

  test "should require description" do
    @task.description = nil
    assert_not @task.valid?
    assert_includes @task.errors[:description], "can't be blank"
  end

  test "should require category" do
    @task.category = nil
    assert_not @task.valid?
    assert_includes @task.errors[:category], "can't be blank"
  end

  test "should require priority" do
    @task.priority = nil
    assert_not @task.valid?
    assert_includes @task.errors[:priority], "can't be blank"
  end

  test "should require due_date" do
    @task.due_date = nil
    assert_not @task.valid?
    assert_includes @task.errors[:due_date], "can't be blank"
  end

  test "should require assigned_to" do
    @task.assigned_to = nil
    assert_not @task.valid?
    assert_includes @task.errors[:assigned_to], "can't be blank"
  end

  # ── Inclusion validations ─────────────────────────────────────────────────
  test "should reject invalid priority" do
    @task.priority = "urgent"
    assert_not @task.valid?
    assert_includes @task.errors[:priority], "is not included in the list"
  end

  test "should accept all valid priorities" do
    %w[high medium low].each do |p|
      @task.priority = p
      assert @task.valid?, "#{p} should be valid"
    end
  end

  # ── Associations ──────────────────────────────────────────────────────────
  test "should belong to offboarding_employee" do
    assert_respond_to @task, :offboarding_employee
  end

  test "should require offboarding_employee" do
    @task.offboarding_employee = nil
    assert_not @task.valid?
  end

  # ── Scopes ────────────────────────────────────────────────────────────────
  test "completed scope returns completed tasks" do
    @task.is_completed = true
    @task.save!
    assert_includes OffboardingTask.completed, @task
  end

  test "pending scope returns incomplete tasks" do
    @task.is_completed = false
    @task.save!
    assert_includes OffboardingTask.pending, @task
  end

  test "overdue scope returns past-due incomplete tasks" do
    @task.due_date = 2.days.ago.to_date
    @task.is_completed = false
    @task.save!
    assert_includes OffboardingTask.overdue, @task
  end

  test "high_priority scope returns high priority tasks" do
    @task.priority = "high"
    @task.save!
    assert_includes OffboardingTask.high_priority, @task
  end

  test "by_category scope filters by category" do
    @task.save!
    hr_task = OffboardingTask.create!(
      offboarding_employee: @offboarding,
      title: "Exit Interview",
      description: "Complete exit interview",
      category: "HR",
      priority: "medium",
      due_date: 1.week.from_now.to_date,
      assigned_to: "HR"
    )
    assert_includes OffboardingTask.by_category("Equipment"), @task
    assert_not_includes OffboardingTask.by_category("Equipment"), hr_task
  end

  # ── Callbacks ─────────────────────────────────────────────────────────────
  test "set_completed_date sets today when marking complete" do
    @task.is_completed = true
    @task.save!
    assert_equal Date.current, @task.reload.completed_date
  end

  test "set_completed_date clears date when marking incomplete" do
    @task.is_completed = true
    @task.save!
    @task.update!(is_completed: false)
    assert_nil @task.reload.completed_date
  end

  # ── Instance methods ──────────────────────────────────────────────────────
  test "overdue? returns true for past due incomplete task" do
    @task.due_date = 1.day.ago.to_date
    @task.is_completed = false
    assert @task.overdue?
  end

  test "overdue? returns false for completed task past due" do
    @task.due_date = 1.day.ago.to_date
    @task.is_completed = true
    assert_not @task.overdue?
  end

  test "due_soon? returns true when due within 3 days" do
    @task.due_date = 2.days.from_now.to_date
    @task.is_completed = false
    assert @task.due_soon?
  end

  test "toggle_completion! flips is_completed" do
    @task.is_completed = false
    @task.save!
    @task.toggle_completion!
    assert @task.reload.is_completed
    @task.toggle_completion!
    assert_not @task.reload.is_completed
  end

  test "priority_color returns red for high" do
    @task.priority = "high"
    assert_equal "red", @task.priority_color
  end

  test "priority_color returns yellow for medium" do
    @task.priority = "medium"
    assert_equal "yellow", @task.priority_color
  end

  test "priority_color returns green for low" do
    @task.priority = "low"
    assert_equal "green", @task.priority_color
  end

  test "status_label returns Completed for completed task" do
    @task.is_completed = true
    assert_equal "Completed", @task.status_label
  end

  test "due_date_formatted returns readable date" do
    @task.due_date = Date.new(2024, 11, 30)
    assert_equal "November 30, 2024", @task.due_date_formatted
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create offboarding task" do
    assert_difference("OffboardingTask.count") { @task.save! }
  end

  test "should update offboarding task" do
    @task.save!
    @task.update!(title: "Return all equipment")
    assert_equal "Return all equipment", @task.reload.title
  end

  test "should destroy offboarding task" do
    @task.save!
    assert_difference("OffboardingTask.count", -1) { @task.destroy }
  end
end
