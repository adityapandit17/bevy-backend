require "test_helper"

class PendingTaskTest < ActiveSupport::TestCase
  def setup
    @assignee = employees(:one)
    @leave_request = leave_requests(:one)
    @task = PendingTask.new(
      title: "Review Leave Application - John Doe",
      priority: "high",
      status: "pending",
      taskable: @leave_request,
      assigned_to: @assignee,
      due_date: Date.current
    )
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @task.valid?
  end

  test "should be valid without assigned_to (optional)" do
    @task.assigned_to = nil
    assert @task.valid?
  end

  # ── Presence validations ──────────────────────────────────────────────────
  test "should require title" do
    @task.title = nil
    assert_not @task.valid?
    assert_includes @task.errors[:title], "can't be blank"
  end

  test "should require priority" do
    @task.priority = nil
    assert_not @task.valid?
    assert_includes @task.errors[:priority], "can't be blank"
  end

  test "should require status" do
    @task.status = nil
    assert_not @task.valid?
    assert_includes @task.errors[:status], "can't be blank"
  end

  # ── Inclusion validations ─────────────────────────────────────────────────
  test "should reject invalid priority" do
    @task.priority = "critical"
    assert_not @task.valid?
    assert_includes @task.errors[:priority], "is not included in the list"
  end

  test "should accept all valid priorities" do
    %w[low medium high].each do |p|
      @task.priority = p
      assert @task.valid?, "#{p} should be valid"
    end
  end

  test "should reject invalid status" do
    @task.status = "archived"
    assert_not @task.valid?
    assert_includes @task.errors[:status], "is not included in the list"
  end

  test "should accept all valid statuses" do
    %w[pending completed cancelled].each do |s|
      @task.status = s
      assert @task.valid?, "#{s} should be valid"
    end
  end

  # ── Associations (polymorphic) ────────────────────────────────────────────
  test "should belong to polymorphic taskable" do
    assert_respond_to @task, :taskable
    assert_equal @leave_request, @task.taskable
  end

  test "should optionally belong to assigned_to employee" do
    assert_respond_to @task, :assigned_to
  end

  # ── Scopes ────────────────────────────────────────────────────────────────
  test "pending scope returns pending tasks" do
    @task.status = "pending"
    @task.save!
    assert_includes PendingTask.pending, @task
  end

  test "completed scope returns completed tasks" do
    @task.status = "completed"
    @task.save!
    assert_includes PendingTask.completed, @task
  end

  test "cancelled scope returns cancelled tasks" do
    @task.status = "cancelled"
    @task.save!
    assert_includes PendingTask.cancelled, @task
  end

  test "high_priority scope returns high priority tasks" do
    @task.priority = "high"
    @task.save!
    assert_includes PendingTask.high_priority, @task
  end

  test "overdue scope returns past-due pending tasks" do
    @task.due_date = 2.days.ago.to_date
    @task.status = "pending"
    @task.save!
    assert_includes PendingTask.overdue, @task
  end

  test "due_today scope returns tasks due today" do
    @task.due_date = Date.current
    @task.status = "pending"
    @task.save!
    assert_includes PendingTask.due_today, @task
  end

  test "for_employee scope filters by assigned_to_id" do
    @task.save!
    assert_includes PendingTask.for_employee(@assignee.id), @task
  end

  test "by_type scope filters by taskable type" do
    @task.save!
    assert_includes PendingTask.by_type("LeaveRequest"), @task
  end

  # ── Instance methods ──────────────────────────────────────────────────────
  test "pending? returns true when status is pending" do
    @task.status = "pending"
    assert @task.pending?
  end

  test "completed? returns true when status is completed" do
    @task.status = "completed"
    assert @task.completed?
  end

  test "cancelled? returns true when status is cancelled" do
    @task.status = "cancelled"
    assert @task.cancelled?
  end

  test "overdue? returns true for past due pending task" do
    @task.due_date = 1.day.ago.to_date
    @task.status = "pending"
    assert @task.overdue?
  end

  test "overdue? returns false for future due_date" do
    @task.due_date = 1.day.from_now.to_date
    assert_not @task.overdue?
  end

  test "due_today? returns true when due_date is today and pending" do
    @task.due_date = Date.current
    @task.status = "pending"
    assert @task.due_today?
  end

  test "mark_completed! sets status to completed" do
    @task.save!
    @task.mark_completed!
    assert_equal "completed", @task.reload.status
  end

  test "mark_cancelled! sets status to cancelled" do
    @task.save!
    @task.mark_cancelled!
    assert_equal "cancelled", @task.reload.status
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create pending task" do
    assert_difference("PendingTask.count") { @task.save! }
  end

  test "should update pending task" do
    @task.save!
    @task.update!(title: "Updated task title")
    assert_equal "Updated task title", @task.reload.title
  end

  test "should destroy pending task" do
    @task.save!
    assert_difference("PendingTask.count", -1) { @task.destroy }
  end
end
