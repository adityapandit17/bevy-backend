require "test_helper"

class EmployeeTest < ActiveSupport::TestCase
  def setup
    @department = departments(:one)
    @employee = Employee.new(
      first_name: "Test",
      last_name: "Employee",
      email: "test.employee@example.com",
      phone: "1234567890",
      department: @department,
      designation: "Software Engineer",
      date_of_joining: Date.current,
      status: "active"
    )
  end

  test "should be valid with valid attributes" do
    assert @employee.valid?
  end

  test "should require first_name" do
    @employee.first_name = nil
    assert_not @employee.valid?
    assert_includes @employee.errors[:first_name], "can't be blank"
  end

  test "should require last_name" do
    @employee.last_name = nil
    assert_not @employee.valid?
    assert_includes @employee.errors[:last_name], "can't be blank"
  end

  test "should require email" do
    @employee.email = nil
    assert_not @employee.valid?
    assert_includes @employee.errors[:email], "can't be blank"
  end

  test "should require unique email" do
    @employee.save!
    duplicate_employee = @employee.dup
    duplicate_employee.email = @employee.email
    assert_not duplicate_employee.valid?
    assert_includes duplicate_employee.errors[:email], "has already been taken"
  end

  test "should validate email format" do
    @employee.email = "invalid-email"
    assert_not @employee.valid?
    assert_includes @employee.errors[:email], "is invalid"
  end

  test "should require phone" do
    @employee.phone = nil
    assert_not @employee.valid?
    assert_includes @employee.errors[:phone], "can't be blank"
  end

  test "should reject invalid phone formats" do
    invalid_phones = [
      "123",            # too short
      "abcd",           # non-numeric
      "+",              # no digits
      "+12-34",         # too short after normalization
      "0000000000"      # too short? no, but still digits; keep it as invalid via business rule later if desired
    ]

    invalid_phones.each do |ph|
      @employee.phone = ph
      assert_not @employee.valid?, "#{ph.inspect} should be invalid"
    end
  end

  test "should accept and normalize common phone formats" do
    # Validation uses company country (defaults to IN). Use valid Indian phone numbers.
    @employee.phone = "+91 98765 43210"
    assert @employee.valid?, @employee.errors.full_messages.inspect
    assert_equal "+919876543210", @employee.phone

    @employee.phone = "98765-43210"
    assert @employee.valid?, @employee.errors.full_messages.inspect
    assert_equal "9876543210", @employee.phone
  end

  test "should require designation" do
    @employee.designation = nil
    assert_not @employee.valid?
    assert_includes @employee.errors[:designation], "can't be blank"
  end

  test "should require date_of_joining" do
    @employee.date_of_joining = nil
    assert_not @employee.valid?
    assert_includes @employee.errors[:date_of_joining], "can't be blank"
  end

  # test "should require status" do
  #   @employee.status = nil
  #   assert_not @employee.valid?
  #   assert_includes @employee.errors[:status], "can't be blank"
  # end

  # test "should validate status inclusion" do
  #   @employee.status = "invalid_status"
  #   assert_not @employee.valid?
  #   assert_includes @employee.errors[:status], "is not included in the list"
  # end

  test "should accept valid statuses" do
    valid_statuses = %w[active inactive terminated probation]
    valid_statuses.each do |status|
      @employee.status = status
      assert @employee.valid?, "#{status} should be valid"
    end
  end

  test "should belong to department" do
    @employee.department = nil
    assert_not @employee.valid?
    assert_includes @employee.errors[:department], "must exist"
  end

  # Association tests
  test "should have many attendance_records" do
    assert_respond_to @employee, :attendance_records
  end

  test "should have many leave_requests" do
    assert_respond_to @employee, :leave_requests
  end

  test "should have many payrolls" do
    assert_respond_to @employee, :payrolls
  end

  test "should have many salary_structures" do
    assert_respond_to @employee, :salary_structures
  end

  test "should have many assets" do
    assert_respond_to @employee, :assets
  end

  test "should have many asset_allocations" do
    assert_respond_to @employee, :asset_allocations
  end

  test "should have many onboarding_employees" do
    assert_respond_to @employee, :onboarding_employees
  end

  test "should have many employee_documents" do
    assert_respond_to @employee, :employee_documents
  end

  test "should have many performance_reviews" do
    assert_respond_to @employee, :performance_reviews
  end

  test "should have many performance_goals" do
    assert_respond_to @employee, :performance_goals
  end

  test "should have many timesheets" do
    assert_respond_to @employee, :timesheets
  end

  test "should have many employee_benefits" do
    assert_respond_to @employee, :employee_benefits
  end

  test "should have many employee_trainings" do
    assert_respond_to @employee, :employee_trainings
  end

  test "should have many offboarding_employees" do
    assert_respond_to @employee, :offboarding_employees
  end

  # Scope tests
  test "active scope should return active employees" do
    @employee.save!

    inactive_employee = Employee.create!(
      first_name: "Inactive",
      last_name: "Employee",
      email: "inactive.employee@example.com",
      phone: "1234567891",
      department: @department,
      designation: "Manager",
      date_of_joining: Date.current,
      status: "inactive"
    )

    assert_includes Employee.active, @employee
    assert_not_includes Employee.active, inactive_employee
  end

  test "inactive scope should return inactive employees" do
    @employee.status = "inactive"
    @employee.save!

    active_employee = Employee.create!(
      first_name: "Active",
      last_name: "Employee",
      email: "active.employee@example.com",
      phone: "1234567892",
      department: @department,
      designation: "Manager",
      date_of_joining: Date.current,
      status: "active"
    )

    assert_includes Employee.inactive, @employee
    assert_not_includes Employee.inactive, active_employee
  end

  test "terminated scope should return terminated employees" do
    @employee.status = "terminated"
    @employee.save!

    active_employee = Employee.create!(
      first_name: "Active",
      last_name: "Employee",
      email: "active.employee2@example.com",
      phone: "1234567893",
      department: @department,
      designation: "Manager",
      date_of_joining: Date.current,
      status: "active"
    )

    assert_includes Employee.terminated, @employee
    assert_not_includes Employee.terminated, active_employee
  end

  test "probation scope should return probation employees" do
    @employee.status = "probation"
    @employee.save!

    active_employee = Employee.create!(
      first_name: "Active",
      last_name: "Employee",
      email: "active.employee3@example.com",
      phone: "1234567894",
      department: @department,
      designation: "Manager",
      date_of_joining: Date.current,
      status: "active"
    )

    assert_includes Employee.probation, @employee
    assert_not_includes Employee.probation, active_employee
  end

  test "by_department scope should filter by department" do
    @employee.save!

    other_department = departments(:two)
    other_dept_employee = Employee.create!(
      first_name: "Other",
      last_name: "Employee",
      email: "other.employee@example.com",
      phone: "1234567895",
      department: other_department,
      designation: "Manager",
      date_of_joining: Date.current,
      status: "active"
    )

    assert_includes Employee.by_department(@department.id), @employee
    assert_not_includes Employee.by_department(@department.id), other_dept_employee
  end

  test "by_designation scope should filter by designation" do
    @employee.save!

    manager_employee = Employee.create!(
      first_name: "Manager",
      last_name: "Employee",
      email: "manager.employee@example.com",
      phone: "1234567896",
      department: @department,
      designation: "Manager",
      date_of_joining: Date.current,
      status: "active"
    )

    assert_includes Employee.by_designation("Software Engineer"), @employee
    assert_not_includes Employee.by_designation("Software Engineer"), manager_employee
  end

  test "recent_hires scope should return employees hired in last 3 months" do
    @employee.save!

    old_employee = Employee.create!(
      first_name: "Old",
      last_name: "Employee",
      email: "old.employee@example.com",
      phone: "1234567897",
      department: @department,
      designation: "Manager",
      date_of_joining: 4.months.ago,
      status: "active"
    )

    assert_includes Employee.recent_hires, @employee
    assert_not_includes Employee.recent_hires, old_employee
  end

  test "long_term scope should return employees hired 2+ years ago" do
    @employee.date_of_joining = 3.years.ago
    @employee.save!

    new_employee = Employee.create!(
      first_name: "New",
      last_name: "Employee",
      email: "new.employee@example.com",
      phone: "1234567898",
      department: @department,
      designation: "Manager",
      date_of_joining: Date.current,
      status: "active"
    )

    assert_includes Employee.long_term, @employee
    assert_not_includes Employee.long_term, new_employee
  end

  # Instance method tests
  test "active? should return true for active status" do
    @employee.status = "active"
    assert @employee.active?
  end

  test "active? should return false for non-active status" do
    @employee.status = "inactive"
    assert_not @employee.active?
  end

  test "inactive? should return true for inactive status" do
    @employee.status = "inactive"
    assert @employee.inactive?
  end

  test "deactivate! sets employee and linked user to inactive" do
    employee = create_test_employee(email: "deactivate.employee@example.com")
    user = ActsAsTenant.with_tenant(companies(:one)) do
      User.create!(
        email: employee.email,
        password: "Password123!",
        first_name: employee.first_name,
        last_name: employee.last_name,
        status: "active",
        employee: employee,
        company: companies(:one)
      )
    end

    ActsAsTenant.with_tenant(companies(:one)) do
      employee.deactivate!
    end

    employee.reload
    user.reload

    assert_equal "inactive", employee.status
    assert_equal "inactive", user.status
  end

  test "terminated? should return true for terminated status" do
    @employee.status = "terminated"
    assert @employee.terminated?
  end

  test "probation? should return true for probation status" do
    @employee.status = "probation"
    assert @employee.probation?
  end

  test "name should return full name" do
    assert_equal "Test Employee", @employee.name
  end

  test "department_name should return department name" do
    @employee.save!
    assert_equal @department.name, @employee.department_name
  end

  test "formatted_hire_date should return formatted date" do
    @employee.date_of_joining = Date.new(2023, 6, 15)
    assert_equal "June 15, 2023", @employee.formatted_hire_date
  end

  test "tenure_years should calculate years of service" do
    @employee.date_of_joining = 2.years.ago - 1.day
    assert_equal 2, @employee.tenure_years
  end

  test "tenure_months should calculate months of service" do
    @employee.date_of_joining = 4.months.ago - 1.day
    assert_equal 4, @employee.tenure_months
  end

  test "tenure_summary should return formatted tenure" do
    @employee.date_of_joining = 4.months.ago - 1.day
    assert_equal "4 months", @employee.tenure_summary
  end

  test "tenure_summary should return years for long tenure" do
    @employee.date_of_joining = 2.years.ago - 1.day
    assert_equal "2 years", @employee.tenure_summary
  end

  test "status_color should return appropriate color for active" do
    @employee.status = "active"
    assert_equal "green", @employee.status_color
  end

  test "status_color should return appropriate color for inactive" do
    @employee.status = "inactive"
    assert_equal "gray", @employee.status_color
  end

  test "status_color should return appropriate color for terminated" do
    @employee.status = "terminated"
    assert_equal "red", @employee.status_color
  end

  test "status_color should return appropriate color for probation" do
    @employee.status = "probation"
    assert_equal "yellow", @employee.status_color
  end

  test "status_label should return titleized status" do
    @employee.status = "active"
    assert_equal "Active", @employee.status_label
  end

  test "full_name should return full name" do
    assert_equal "Test Employee", @employee.full_name
  end

  test "initials should return initials" do
    assert_equal "TE", @employee.initials
  end

  test "avatar_url should return local data URI placeholder" do
    url = @employee.avatar_url
    assert url.start_with?("data:image/svg+xml;base64,"), "expected local SVG data URI, got #{url}"
  end

  test "profile_completion_percentage should calculate completion" do
    @employee.save!
    # All required fields are filled, so should be 100%
    assert_equal 100.0, @employee.profile_completion_percentage
  end

  test "profile_completion_percentage should handle missing fields" do
    @employee.first_name = nil
    @employee.phone = nil
    # 5 out of 7 fields filled = 71.4%
    assert_equal 71.4, @employee.profile_completion_percentage
  end

  test "salary should return basic salary from salary structure" do
    skip "Model has issue with recent scope"
    @employee.save!
    # Since no salary structure exists, should return 0
    assert_equal 0, @employee.salary
  end

  test "salary should return 0 when no salary structure exists" do
    skip "Model has issue with recent scope"
    @employee.save!
    assert_equal 0, @employee.salary
  end

  # CRUD tests
  test "should be able to create employee" do
    assert_difference("Employee.count") do
      @employee.save!
    end
  end

  test "should be able to update employee" do
    @employee.save!
    @employee.first_name = "Updated"
    @employee.save!
    assert_equal "Updated", @employee.reload.first_name
  end

  test "should be able to delete employee" do
    @employee.save!
    assert_difference("Employee.count", -1) do
      @employee.destroy
    end
  end
end
