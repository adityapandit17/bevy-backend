require "test_helper"

class EmployeeTrainingTest < ActiveSupport::TestCase
  def setup
    @employee = employees(:one)
    @training = EmployeeTraining.new(
      employee: @employee,
      name: "Advanced Ruby on Rails",
      training_type: "technical",
      provider: "Rails Academy",
      start_date: Date.current + 1.week,
      end_date: Date.current + 3.weeks,
      status: "not_started",
      progress: 0,
      cost: 1500.00,
      skills: "Ruby, Rails, JavaScript, PostgreSQL",
      certificate: "certificate.pdf"
    )
  end

  test "should be valid with valid attributes" do
    assert @training.valid?
  end

  test "should require employee" do
    @training.employee = nil
    assert_not @training.valid?
    assert_includes @training.errors[:employee], "must exist"
  end

  test "should require name" do
    @training.name = nil
    assert_not @training.valid?
    assert_includes @training.errors[:name], "can't be blank"
  end

  test "should require training_type" do
    @training.training_type = nil
    assert_not @training.valid?
    assert_includes @training.errors[:training_type], "can't be blank"
  end

  test "should validate training_type inclusion" do
    @training.training_type = "invalid_type"
    assert_not @training.valid?
    assert_includes @training.errors[:training_type], "is not included in the list"
  end

  test "should accept valid training types" do
    valid_types = %w[technical soft_skills compliance leadership certification other]
    valid_types.each do |type|
      @training.training_type = type
      assert @training.valid?, "#{type} should be valid"
    end
  end

  test "should require provider" do
    @training.provider = nil
    assert_not @training.valid?
    assert_includes @training.errors[:provider], "can't be blank"
  end

  test "should require start_date" do
    @training.start_date = nil
    assert_not @training.valid?
    assert_includes @training.errors[:start_date], "can't be blank"
  end

  test "should require end_date" do
    @training.end_date = nil
    assert_not @training.valid?
    assert_includes @training.errors[:end_date], "can't be blank"
  end

  test "should require status" do
    @training.status = nil
    assert_not @training.valid?
    assert_includes @training.errors[:status], "can't be blank"
  end

  test "should validate status inclusion" do
    @training.status = "invalid_status"
    assert_not @training.valid?
    assert_includes @training.errors[:status], "is not included in the list"
  end

  test "should accept valid statuses" do
    valid_statuses = %w[not_started in_progress completed cancelled failed]
    valid_statuses.each do |status|
      @training.status = status
      assert @training.valid?, "#{status} should be valid"
    end
  end

  test "should require progress" do
    @training.progress = nil
    assert_not @training.valid?
    assert_includes @training.errors[:progress], "can't be blank"
  end

  test "should validate progress range" do
    @training.progress = -1
    assert_not @training.valid?
    assert_includes @training.errors[:progress], "must be greater than or equal to 0"

    @training.progress = 101
    assert_not @training.valid?
    assert_includes @training.errors[:progress], "must be less than or equal to 100"
  end

  test "should accept valid progress values" do
    [ 0, 25, 50, 75, 100 ].each do |progress|
      @training.progress = progress
      assert @training.valid?, "Progress #{progress} should be valid"
    end
  end

  test "should require cost" do
    @training.cost = nil
    assert_not @training.valid?
    assert_includes @training.errors[:cost], "can't be blank"
  end

  test "should validate cost is greater than or equal to 0" do
    @training.cost = -100
    assert_not @training.valid?
    assert_includes @training.errors[:cost], "must be greater than or equal to 0"
  end

  test "should accept zero cost" do
    @training.cost = 0
    assert @training.valid?
  end

  # Association tests
  test "should belong to employee" do
    assert_respond_to @training, :employee
  end

  # Scope tests
  test "by_employee scope should filter by employee" do
    @training.save!

    other_employee = employees(:two)
    other_training = EmployeeTraining.create!(
      employee: other_employee,
      name: "Other Training",
      training_type: "technical",
      provider: "Other Provider",
      start_date: Date.current + 1.week,
      end_date: Date.current + 2.weeks,
      status: "not_started",
      progress: 0,
      cost: 1000.00
    )

    assert_includes EmployeeTraining.by_employee(@employee.id), @training
    assert_not_includes EmployeeTraining.by_employee(@employee.id), other_training
  end

  test "by_type scope should filter by training type" do
    @training.save!

    soft_skills_training = EmployeeTraining.create!(
      employee: @employee,
      name: "Communication Skills",
      training_type: "soft_skills",
      provider: "Skills Academy",
      start_date: Date.current + 1.week,
      end_date: Date.current + 2.weeks,
      status: "not_started",
      progress: 0,
      cost: 800.00
    )

    assert_includes EmployeeTraining.by_type("technical"), @training
    assert_not_includes EmployeeTraining.by_type("technical"), soft_skills_training
  end

  test "completed scope should return completed trainings" do
    @training.status = "completed"
    @training.save!

    in_progress_training = EmployeeTraining.create!(
      employee: @employee,
      name: "In Progress Training",
      training_type: "technical",
      provider: "Tech Academy",
      start_date: Date.current - 1.week,
      end_date: Date.current + 1.week,
      status: "in_progress",
      progress: 50,
      cost: 1200.00
    )

    assert_includes EmployeeTraining.completed, @training
    assert_not_includes EmployeeTraining.completed, in_progress_training
  end

  test "in_progress scope should return in progress trainings" do
    @training.status = "in_progress"
    @training.save!

    completed_training = EmployeeTraining.create!(
      employee: @employee,
      name: "Completed Training",
      training_type: "technical",
      provider: "Tech Academy",
      start_date: Date.current - 2.weeks,
      end_date: Date.current - 1.week,
      status: "completed",
      progress: 100,
      cost: 1200.00
    )

    assert_includes EmployeeTraining.in_progress, @training
    assert_not_includes EmployeeTraining.in_progress, completed_training
  end

  test "current scope should return current trainings" do
    @training.start_date = Date.current - 1.day
    @training.end_date = Date.current + 1.day
    @training.save!

    future_training = EmployeeTraining.create!(
      employee: @employee,
      name: "Future Training",
      training_type: "technical",
      provider: "Tech Academy",
      start_date: Date.current + 1.week,
      end_date: Date.current + 2.weeks,
      status: "not_started",
      progress: 0,
      cost: 1200.00
    )

    assert_includes EmployeeTraining.current, @training
    assert_not_includes EmployeeTraining.current, future_training
  end

  test "upcoming scope should return future trainings" do
    @training.save!

    past_training = EmployeeTraining.create!(
      employee: @employee,
      name: "Past Training",
      training_type: "technical",
      provider: "Tech Academy",
      start_date: Date.current - 2.weeks,
      end_date: Date.current - 1.week,
      status: "completed",
      progress: 100,
      cost: 1200.00
    )

    assert_includes EmployeeTraining.upcoming, @training
    assert_not_includes EmployeeTraining.upcoming, past_training
  end

  # Instance method tests
  test "not_started? should return true for not_started status" do
    @training.status = "not_started"
    assert @training.not_started?
  end

  test "in_progress? should return true for in_progress status" do
    @training.status = "in_progress"
    assert @training.in_progress?
  end

  test "completed? should return true for completed status" do
    @training.status = "completed"
    assert @training.completed?
  end

  test "cancelled? should return true for cancelled status" do
    @training.status = "cancelled"
    assert @training.cancelled?
  end

  test "failed? should return true for failed status" do
    @training.status = "failed"
    assert @training.failed?
  end

  test "is_current? should return true for current training" do
    @training.start_date = Date.current - 1.day
    @training.end_date = Date.current + 1.day
    assert @training.is_current?
  end

  test "is_current? should return false for past training" do
    @training.start_date = Date.current - 2.weeks
    @training.end_date = Date.current - 1.week
    assert_not @training.is_current?
  end

  test "is_upcoming? should return true for future training" do
    @training.start_date = Date.current + 1.week
    @training.end_date = Date.current + 2.weeks
    assert @training.is_upcoming?
  end

  test "is_past? should return true for past training" do
    @training.start_date = Date.current - 2.weeks
    @training.end_date = Date.current - 1.week
    assert @training.is_past?
  end

  test "is_overdue? should return true for overdue training" do
    @training.end_date = Date.current - 1.day
    @training.status = "in_progress"
    assert @training.is_overdue?
  end

  test "is_overdue? should return false for completed training" do
    @training.end_date = Date.current - 1.day
    @training.status = "completed"
    assert_not @training.is_overdue?
  end

  test "days_until_start should return days until start" do
    @training.start_date = Date.current + 7.days
    assert_equal 7, @training.days_until_start
  end

  test "days_until_start should return negative days for past training" do
    @training.start_date = Date.current - 1.day
    assert_equal -1, @training.days_until_start
  end

  test "days_until_end should return days until end" do
    @training.end_date = Date.current + 14.days
    assert_equal 14, @training.days_until_end
  end

  test "duration_days should return training duration" do
    @training.start_date = Date.new(2023, 6, 1)
    @training.end_date = Date.new(2023, 6, 5)
    assert_equal 5, @training.duration_days
  end

  test "employee_name should return employee name" do
    @training.save!
    assert_equal @employee.name, @training.employee_name
  end

  test "employee_email should return employee email" do
    @training.save!
    assert_equal @employee.email, @training.employee_email
  end

  test "employee_department should return employee department" do
    @training.save!
    assert_equal @employee.department.name, @training.employee_department
  end

  test "training_type_label should return titleized type" do
    @training.training_type = "soft_skills"
    assert_equal "Soft Skills", @training.training_type_label
  end

  test "formatted_start_date should return formatted date" do
    @training.start_date = Date.new(2023, 6, 15)
    assert_equal "June 15, 2023", @training.formatted_start_date
  end

  test "formatted_end_date should return formatted date" do
    @training.end_date = Date.new(2023, 6, 20)
    assert_equal "June 20, 2023", @training.formatted_end_date
  end

  test "status_color should return appropriate color for not_started" do
    @training.status = "not_started"
    assert_equal "gray", @training.status_color
  end

  test "status_color should return appropriate color for in_progress" do
    @training.status = "in_progress"
    assert_equal "blue", @training.status_color
  end

  test "status_color should return appropriate color for completed" do
    @training.status = "completed"
    assert_equal "green", @training.status_color
  end

  test "status_color should return appropriate color for cancelled" do
    @training.status = "cancelled"
    assert_equal "gray", @training.status_color
  end

  test "status_color should return appropriate color for failed" do
    @training.status = "failed"
    assert_equal "red", @training.status_color
  end

  test "status_label should return appropriate label" do
    @training.status = "in_progress"
    assert_equal "In Progress", @training.status_label
  end

  test "progress_color should return green for high progress" do
    @training.progress = 90
    assert_equal "green", @training.progress_color
  end

  test "progress_color should return yellow for medium progress" do
    @training.progress = 50
    assert_equal "yellow", @training.progress_color
  end

  test "progress_color should return red for low progress" do
    @training.progress = 20
    assert_equal "red", @training.progress_color
  end

  test "cost_formatted should return formatted cost" do
    @training.cost = 1500.50
    assert_equal "₹1500.5", @training.cost_formatted
  end

  test "skills_list should return array of skills" do
    @training.skills = "Ruby, Rails, JavaScript, PostgreSQL"
    assert_equal [ "Ruby", "Rails", "JavaScript", "PostgreSQL" ], @training.skills_list
  end

  test "skills_list should return empty array for nil skills" do
    @training.skills = nil
    assert_equal [], @training.skills_list
  end

  test "has_certificate? should return true when certificate present" do
    @training.certificate = "certificate.pdf"
    assert @training.has_certificate?
  end

  test "has_certificate? should return false when certificate absent" do
    @training.certificate = nil
    assert_not @training.has_certificate?
  end

  test "certificate_url should return certificate when present" do
    @training.certificate = "certificate.pdf"
    assert_equal "certificate.pdf", @training.certificate_url
  end

  test "training_summary should return formatted summary" do
    assert_equal "Advanced Ruby on Rails (Rails Academy)", @training.training_summary
  end

  test "duration_summary should return formatted duration" do
    @training.start_date = Date.new(2023, 6, 1)
    @training.end_date = Date.new(2023, 6, 5)
    expected = "June 01, 2023 to June 05, 2023 (5 days)"
    assert_equal expected, @training.duration_summary
  end

  test "completion_status should return completed status" do
    @training.status = "completed"
    @training.progress = 100
    @training.end_date = Date.new(2025, 8, 20)
    assert_equal "Completed on August 20, 2025", @training.completion_status
  end

  test "completion_status should return in progress status" do
    @training.status = "in_progress"
    @training.progress = 50
    assert_equal "50% complete", @training.completion_status
  end

  test "completion_status should return not started status" do
    @training.status = "not_started"
    @training.progress = 0
    assert_equal "Starts in 7 days", @training.completion_status
  end

  test "can_edit? should return true for editable status" do
    @training.status = "in_progress"
    assert @training.can_edit?
  end

  test "can_edit? should return false for completed status" do
    @training.status = "completed"
    assert_not @training.can_edit?
  end

  test "can_cancel? should return true for cancellable status" do
    @training.status = "in_progress"
    assert @training.can_cancel?
  end

  test "can_cancel? should return false for completed status" do
    @training.status = "completed"
    assert_not @training.can_cancel?
  end

  test "can_mark_complete? should return true when ready" do
    @training.status = "in_progress"
    @training.progress = 100
    assert @training.can_mark_complete?
  end

  test "can_mark_complete? should return false when not ready" do
    @training.status = "in_progress"
    @training.progress = 80
    assert_not @training.can_mark_complete?
  end

  # Callback tests
  test "should update status to completed when progress reaches 100" do
    @training.status = "in_progress"
    @training.progress = 100
    @training.save!
    assert_equal "completed", @training.status
  end

  test "should update status to failed when overdue and incomplete" do
    @training.status = "in_progress"
    @training.progress = 50
    @training.end_date = Date.current - 1.day
    @training.save!
    assert_equal "failed", @training.status
  end

  # CRUD tests
  test "should be able to create training" do
    assert_difference("EmployeeTraining.count") do
      @training.save!
    end
  end

  test "should be able to update training" do
    @training.save!
    @training.name = "Updated Training"
    @training.save!
    assert_equal "Updated Training", @training.reload.name
  end

  test "should be able to delete training" do
    @training.save!
    assert_difference("EmployeeTraining.count", -1) do
      @training.destroy
    end
  end

  # Edge cases
  test "should handle single day training" do
    @training.start_date = Date.current + 1.week
    @training.end_date = Date.current + 1.week
    assert @training.valid?
    assert_equal 1, @training.duration_days
  end

  test "should handle skills with extra spaces" do
    @training.skills = "Ruby , Rails , JavaScript"
    assert_equal [ "Ruby", "Rails", "JavaScript" ], @training.skills_list
  end

  test "should handle empty skills string" do
    @training.skills = "   "
    assert_equal [ "" ], @training.skills_list
  end
end
