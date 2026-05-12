require "test_helper"

class OnboardingTaskTest < ActiveSupport::TestCase
  def setup
    @emp = create_test_employee(
      email: "ont.test#{SecureRandom.hex(4)}@example.com",
      phone: "9876543214"
    )
    @onboarding = OnboardingEmployee.create!(
      employee: @emp,
      start_date: Date.current,
      status: "pending",
      progress: 0
    )
    @task = OnboardingTask.new(
      onboarding_employee: @onboarding,
      title: "Sign Employment Contract",
      category: "HR",
      priority: "high",
      due_date: Date.tomorrow,
      assigned_to: "HR Manager"
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
  test "should reject invalid category" do
    @task.category = "Finance"
    assert_not @task.valid?
    assert_includes @task.errors[:category], "is not included in the list"
  end

  test "should accept all valid categories" do
    %w[HR IT Department Training Compliance Performance].each do |cat|
      @task.category = cat
      assert @task.valid?, "#{cat} should be valid"
    end
  end

  test "should reject invalid priority" do
    @task.priority = "urgent"
    assert_not @task.valid?
    assert_includes @task.errors[:priority], "is not included in the list"
  end

  test "should accept all valid priorities" do
    %w[low medium high].each do |p|
      @task.priority = p
      assert @task.valid?, "#{p} should be valid"
    end
  end

  # ── Associations ──────────────────────────────────────────────────────────
  test "should belong to onboarding_employee" do
    assert_respond_to @task, :onboarding_employee
  end

  test "should require onboarding_employee" do
    @task.onboarding_employee = nil
    assert_not @task.valid?
  end

  # ── Scopes ────────────────────────────────────────────────────────────────
  test "completed scope returns completed tasks" do
    @task.is_completed = true
    @task.save!
    assert_includes OnboardingTask.completed, @task
  end

  test "pending scope returns incomplete tasks" do
    @task.is_completed = false
    @task.save!
    assert_includes OnboardingTask.pending, @task
  end

  test "high_priority scope returns high priority tasks" do
    @task.priority = "high"
    @task.save!
    assert_includes OnboardingTask.high_priority, @task
  end

  test "overdue scope returns past-due incomplete tasks" do
    @task.due_date = 2.days.ago.to_date
    @task.is_completed = false
    @task.save!
    assert_includes OnboardingTask.overdue, @task
  end

  test "by_category scope filters by category" do
    @task.save!
    it_task = OnboardingTask.create!(
      onboarding_employee: @onboarding,
      title: "IT Setup",
      category: "IT",
      priority: "medium",
      due_date: Date.tomorrow,
      assigned_to: "IT"
    )
    assert_includes OnboardingTask.by_category("HR"), @task
    assert_not_includes OnboardingTask.by_category("HR"), it_task
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

  test "documents_list returns empty array when blank" do
    @task.documents = nil
    assert_equal [], @task.documents_list
  end

  test "documents_list parses comma-separated documents" do
    @task.documents = "Contract.pdf, Tax form.pdf"
    @task.save!
    assert_includes @task.documents_list, "Contract.pdf"
    assert_equal 2, @task.documents_list.length
  end

  test "documents_list= assigns comma-separated string" do
    @task.documents_list = %w[doc1.pdf doc2.pdf]
    assert_equal "doc1.pdf, doc2.pdf", @task.documents
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create onboarding task" do
    assert_difference("OnboardingTask.count") { @task.save! }
  end

  test "should update onboarding task" do
    @task.save!
    @task.update!(is_completed: true)
    assert @task.reload.is_completed
  end

  test "should destroy onboarding task" do
    @task.save!
    assert_difference("OnboardingTask.count", -1) { @task.destroy }
  end
end
