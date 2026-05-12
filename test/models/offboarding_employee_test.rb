require "test_helper"

class OffboardingEmployeeTest < ActiveSupport::TestCase
  def setup
    @employee = create_test_employee(
      email: "offboard.test#{SecureRandom.hex(4)}@example.com",
      phone: "9876543215"
    )
    @offboarding = OffboardingEmployee.new(
      employee: @employee,
      last_working_day: 2.weeks.from_now.to_date,
      status: "pending",
      progress: 0,
      reason: "Resignation"
    )
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @offboarding.valid?
  end

  # ── Presence validations ──────────────────────────────────────────────────
  test "should require last_working_day" do
    @offboarding.last_working_day = nil
    assert_not @offboarding.valid?
    assert_includes @offboarding.errors[:last_working_day], "can't be blank"
  end

  test "should require status" do
    @offboarding.status = nil
    assert_not @offboarding.valid?
    assert_includes @offboarding.errors[:status], "can't be blank"
  end

  # ── Inclusion validations ─────────────────────────────────────────────────
  test "should reject invalid status" do
    @offboarding.status = "archived"
    assert_not @offboarding.valid?
    assert_includes @offboarding.errors[:status], "is not included in the list"
  end

  test "should accept all valid statuses" do
    %w[pending in_progress completed cancelled].each do |s|
      @offboarding.status = s
      assert @offboarding.valid?, "#{s} should be valid"
    end
  end

  # ── Numericality ──────────────────────────────────────────────────────────
  test "should reject progress below 0" do
    @offboarding.progress = -1
    assert_not @offboarding.valid?
  end

  test "should reject progress above 100" do
    @offboarding.progress = 101
    assert_not @offboarding.valid?
  end

  # ── Custom validation: single active offboarding per employee ─────────────
  test "should reject second active offboarding for same employee" do
    @offboarding.save!
    dup = OffboardingEmployee.new(
      employee: @employee,
      last_working_day: 3.weeks.from_now.to_date,
      status: "pending",
      progress: 0
    )
    assert_not dup.valid?
    assert dup.errors[:employee_id].any?
  end

  test "should allow new offboarding after previous was cancelled" do
    @offboarding.status = "cancelled"
    @offboarding.save!
    new_offboarding = OffboardingEmployee.new(
      employee: @employee,
      last_working_day: 3.weeks.from_now.to_date,
      status: "pending",
      progress: 0
    )
    assert new_offboarding.valid?
  end

  # ── Associations ──────────────────────────────────────────────────────────
  test "should belong to employee" do
    assert_respond_to @offboarding, :employee
  end

  test "should have many offboarding_tasks" do
    assert_respond_to @offboarding, :offboarding_tasks
  end

  # ── Scopes ────────────────────────────────────────────────────────────────
  test "pending scope returns pending records" do
    @offboarding.status = "pending"
    @offboarding.save!
    assert_includes OffboardingEmployee.pending, @offboarding
  end

  test "completed scope returns completed records" do
    @offboarding.status = "completed"
    @offboarding.progress = 100
    @offboarding.save!
    assert_includes OffboardingEmployee.completed, @offboarding
  end

  test "active scope returns pending and in_progress" do
    @offboarding.status = "pending"
    @offboarding.save!
    assert_includes OffboardingEmployee.active, @offboarding
  end

  test "cancelled scope returns cancelled records" do
    @offboarding.status = "cancelled"
    @offboarding.save!
    assert_includes OffboardingEmployee.cancelled, @offboarding
  end

  # ── Instance methods ──────────────────────────────────────────────────────
  test "active? returns true for pending or in_progress" do
    @offboarding.status = "pending"
    assert @offboarding.active?
    @offboarding.status = "in_progress"
    assert @offboarding.active?
  end

  test "completed? returns true when status is completed" do
    @offboarding.status = "completed"
    assert @offboarding.completed?
  end

  test "cancelled? returns true when status is cancelled" do
    @offboarding.status = "cancelled"
    assert @offboarding.cancelled?
  end

  test "days_remaining returns positive integer for future last_working_day" do
    @offboarding.last_working_day = 10.days.from_now.to_date
    assert @offboarding.days_remaining > 0
  end

  test "days_remaining returns 0 when last_working_day has passed" do
    @offboarding.last_working_day = 1.day.ago.to_date
    assert_equal 0, @offboarding.days_remaining
  end

  test "employee_name delegates to employee" do
    assert_equal @employee.name, @offboarding.employee_name
  end

  test "status_color returns green for completed" do
    @offboarding.status = "completed"
    assert_equal "green", @offboarding.status_color
  end

  test "status_color returns red for cancelled" do
    @offboarding.status = "cancelled"
    assert_equal "red", @offboarding.status_color
  end

  test "last_working_day_formatted returns readable date" do
    @offboarding.last_working_day = Date.new(2024, 12, 31)
    assert_equal "December 31, 2024", @offboarding.last_working_day_formatted
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create offboarding employee" do
    assert_difference("OffboardingEmployee.count") { @offboarding.save! }
  end

  test "should update offboarding employee" do
    @offboarding.save!
    @offboarding.update!(reason: "Better opportunity")
    assert_equal "Better opportunity", @offboarding.reload.reason
  end

  test "should destroy offboarding employee" do
    @offboarding.save!
    assert_difference("OffboardingEmployee.count", -1) { @offboarding.destroy }
  end

  test "destroying offboarding_employee destroys dependent tasks" do
    @offboarding.save!
    OffboardingTask.create!(
      offboarding_employee: @offboarding,
      title: "Return laptop",
      description: "Return all IT equipment",
      category: "Equipment",
      priority: "high",
      due_date: 1.week.from_now.to_date,
      assigned_to: "IT"
    )
    assert_difference("OffboardingTask.count", -1) { @offboarding.destroy }
  end
end
