require "test_helper"

class OnboardingEmployeeTest < ActiveSupport::TestCase
  def setup
    # Use an employee that has no existing onboarding record
    @employee = create_test_employee(
      email: "onboard.test#{SecureRandom.hex(4)}@example.com",
      phone: "9876543212"
    )
    @onboarding = OnboardingEmployee.new(
      employee: @employee,
      start_date: Date.current,
      status: "pending",
      progress: 0
    )
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @onboarding.valid?
  end

  # ── Presence validations ──────────────────────────────────────────────────
  test "should require start_date" do
    @onboarding.start_date = nil
    assert_not @onboarding.valid?
    assert_includes @onboarding.errors[:start_date], "can't be blank"
  end

  test "should require status" do
    @onboarding.status = nil
    assert_not @onboarding.valid?
    assert_includes @onboarding.errors[:status], "can't be blank"
  end

  # ── Inclusion validations ─────────────────────────────────────────────────
  test "should reject invalid status" do
    @onboarding.status = "on_hold"
    assert_not @onboarding.valid?
    assert_includes @onboarding.errors[:status], "is not included in the list"
  end

  test "should accept all valid statuses" do
    %w[pending in_progress completed].each do |s|
      @onboarding.status = s
      assert @onboarding.valid?, "#{s} should be valid"
    end
  end

  # ── Numericality ──────────────────────────────────────────────────────────
  test "should reject progress below 0" do
    @onboarding.progress = -1
    assert_not @onboarding.valid?
  end

  test "should reject progress above 100" do
    @onboarding.progress = 101
    assert_not @onboarding.valid?
  end

  # ── Uniqueness: one onboarding per employee ───────────────────────────────
  test "should enforce one onboarding per employee" do
    @onboarding.save!
    dup = OnboardingEmployee.new(employee: @employee, start_date: Date.current, status: "pending", progress: 0)
    assert_not dup.valid?
    assert dup.errors[:employee_id].any?
  end

  # ── Associations ──────────────────────────────────────────────────────────
  test "should belong to employee" do
    assert_respond_to @onboarding, :employee
  end

  test "should have many onboarding_tasks" do
    assert_respond_to @onboarding, :onboarding_tasks
  end

  # ── Scopes ────────────────────────────────────────────────────────────────
  test "pending scope returns pending records" do
    @onboarding.status = "pending"
    @onboarding.save!
    assert_includes OnboardingEmployee.pending, @onboarding
  end

  test "completed scope returns completed records" do
    @onboarding.status = "completed"
    @onboarding.progress = 100
    @onboarding.save!
    assert_includes OnboardingEmployee.completed, @onboarding
  end

  test "active scope returns pending and in_progress records" do
    @onboarding.status = "pending"
    @onboarding.save!
    assert_includes OnboardingEmployee.active, @onboarding
  end

  # ── Callback: calculate_progress ─────────────────────────────────────────
  test "calculate_progress sets status to in_progress when tasks partially complete" do
    @onboarding.save!
    OnboardingTask.create!(
      onboarding_employee: @onboarding,
      title: "Task 1",
      category: "HR",
      priority: "high",
      due_date: Date.current,
      assigned_to: "HR",
      is_completed: true
    )
    OnboardingTask.create!(
      onboarding_employee: @onboarding,
      title: "Task 2",
      category: "IT",
      priority: "medium",
      due_date: Date.current,
      assigned_to: "IT",
      is_completed: false
    )
    @onboarding.calculate_progress
    @onboarding.save!
    assert_equal 50, @onboarding.reload.progress
    assert_equal "in_progress", @onboarding.reload.status
  end

  test "calculate_progress sets status to completed when all tasks done" do
    @onboarding.save!
    OnboardingTask.create!(
      onboarding_employee: @onboarding,
      title: "Only Task",
      category: "HR",
      priority: "high",
      due_date: Date.current,
      assigned_to: "HR",
      is_completed: true
    )
    @onboarding.calculate_progress
    @onboarding.save!
    assert_equal 100, @onboarding.reload.progress
    assert_equal "completed", @onboarding.reload.status
  end

  # ── Instance methods ──────────────────────────────────────────────────────
  test "employee_name returns full name" do
    assert_equal @employee.name, @onboarding.employee_name
  end

  test "email delegates to employee" do
    assert_equal @employee.email, @onboarding.email
  end

  test "position delegates to employee designation" do
    assert_equal @employee.designation, @onboarding.position
  end

  # ── Class methods ─────────────────────────────────────────────────────────
  test "employee_onboarded? returns true for completed onboarding" do
    @onboarding.status = "completed"
    @onboarding.progress = 100
    @onboarding.save!
    assert OnboardingEmployee.employee_onboarded?(@employee.id)
  end

  test "employee_in_onboarding? returns true for pending/in_progress" do
    @onboarding.save!
    assert OnboardingEmployee.employee_in_onboarding?(@employee.id)
  end

  test "available_for_onboarding? returns false when already onboarded" do
    @onboarding.save!
    assert_not OnboardingEmployee.available_for_onboarding?(@employee.id)
  end

  test "available_for_onboarding? returns true for new employee" do
    new_emp = create_test_employee(
      email: "avail.test#{SecureRandom.hex(4)}@example.com",
      phone: "9876543213"
    )
    assert OnboardingEmployee.available_for_onboarding?(new_emp.id)
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create onboarding employee" do
    assert_difference("OnboardingEmployee.count") { @onboarding.save! }
  end

  test "should update onboarding employee" do
    @onboarding.save!
    @onboarding.update!(notes: "Updated notes")
    assert_equal "Updated notes", @onboarding.reload.notes
  end

  test "should destroy onboarding employee" do
    @onboarding.save!
    assert_difference("OnboardingEmployee.count", -1) { @onboarding.destroy }
  end

  test "destroying onboarding_employee destroys dependent tasks" do
    @onboarding.save!
    OnboardingTask.create!(
      onboarding_employee: @onboarding,
      title: "Task to destroy",
      category: "HR",
      priority: "high",
      due_date: Date.current,
      assigned_to: "HR"
    )
    assert_difference("OnboardingTask.count", -1) { @onboarding.destroy }
  end
end
