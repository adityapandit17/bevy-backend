require "test_helper"

class EmployeeBenefitTest < ActiveSupport::TestCase
  def setup
    @employee = employees(:one)
    @benefit = EmployeeBenefit.new(
      employee: @employee,
      name: "Health Insurance Premium",
      benefit_type: "health_insurance",
      provider: "Blue Cross Blue Shield",
      coverage: "Family Coverage",
      start_date: Date.current,
      end_date: Date.current + 1.year,
      status: "active",
      cost: 500.00
    )
  end

  test "should be valid with valid attributes" do
    assert @benefit.valid?
  end

  test "should require employee" do
    @benefit.employee = nil
    assert_not @benefit.valid?
    assert_includes @benefit.errors[:employee], "must exist"
  end

  test "should require name" do
    @benefit.name = nil
    assert_not @benefit.valid?
    assert_includes @benefit.errors[:name], "can't be blank"
  end

  test "should require benefit_type" do
    @benefit.benefit_type = nil
    assert_not @benefit.valid?
    assert_includes @benefit.errors[:benefit_type], "can't be blank"
  end

  test "should validate benefit_type inclusion" do
    @benefit.benefit_type = "invalid_type"
    assert_not @benefit.valid?
    assert_includes @benefit.errors[:benefit_type], "is not included in the list"
  end

  test "should accept valid benefit types" do
    valid_types = %w[health_insurance life_insurance dental_insurance vision_insurance retirement wellness other]
    valid_types.each do |type|
      @benefit.benefit_type = type
      assert @benefit.valid?, "#{type} should be valid"
    end
  end

  test "should require provider" do
    @benefit.provider = nil
    assert_not @benefit.valid?
    assert_includes @benefit.errors[:provider], "can't be blank"
  end

  test "should require coverage" do
    @benefit.coverage = nil
    assert_not @benefit.valid?
    assert_includes @benefit.errors[:coverage], "can't be blank"
  end

  test "should require start_date" do
    @benefit.start_date = nil
    assert_not @benefit.valid?
    assert_includes @benefit.errors[:start_date], "can't be blank"
  end

  test "should require status" do
    @benefit.status = nil
    assert_not @benefit.valid?
    assert_includes @benefit.errors[:status], "can't be blank"
  end

  test "should validate status inclusion" do
    @benefit.status = "invalid_status"
    assert_not @benefit.valid?
    assert_includes @benefit.errors[:status], "is not included in the list"
  end

  test "should accept valid statuses" do
    valid_statuses = %w[active inactive pending expired]
    valid_statuses.each do |status|
      @benefit.status = status
      assert @benefit.valid?, "#{status} should be valid"
    end
  end

  test "should require cost" do
    @benefit.cost = nil
    assert_not @benefit.valid?
    assert_includes @benefit.errors[:cost], "can't be blank"
  end

  test "should validate cost is greater than or equal to 0" do
    @benefit.cost = -100
    assert_not @benefit.valid?
    assert_includes @benefit.errors[:cost], "must be greater than or equal to 0"
  end

  test "should accept zero cost" do
    @benefit.cost = 0
    assert @benefit.valid?
  end

  # Association tests
  test "should belong to employee" do
    assert_respond_to @benefit, :employee
  end

  # Scope tests
  test "by_employee scope should filter by employee" do
    @benefit.save!

    other_employee = employees(:two)
    other_benefit = EmployeeBenefit.create!(
      employee: other_employee,
      name: "Other Benefit",
      benefit_type: "health_insurance",
      provider: "Other Provider",
      coverage: "Individual Coverage",
      start_date: Date.current,
      status: "active",
      cost: 300.00
    )

    assert_includes EmployeeBenefit.by_employee(@employee.id), @benefit
    assert_not_includes EmployeeBenefit.by_employee(@employee.id), other_benefit
  end

  test "by_type scope should filter by benefit type" do
    @benefit.save!

    dental_benefit = EmployeeBenefit.create!(
      employee: @employee,
      name: "Dental Insurance",
      benefit_type: "dental_insurance",
      provider: "Dental Provider",
      coverage: "Family Coverage",
      start_date: Date.current,
      status: "active",
      cost: 200.00
    )

    assert_includes EmployeeBenefit.by_type("health_insurance"), @benefit
    assert_not_includes EmployeeBenefit.by_type("health_insurance"), dental_benefit
  end

  test "active scope should return active benefits" do
    @benefit.save!

    inactive_benefit = EmployeeBenefit.create!(
      employee: @employee,
      name: "Inactive Benefit",
      benefit_type: "health_insurance",
      provider: "Provider",
      coverage: "Coverage",
      start_date: Date.current,
      status: "inactive",
      cost: 100.00
    )

    assert_includes EmployeeBenefit.active, @benefit
    assert_not_includes EmployeeBenefit.active, inactive_benefit
  end

  test "expiring_soon scope should return benefits expiring soon" do
    @benefit.end_date = Date.current + 15.days
    @benefit.save!

    long_term_benefit = EmployeeBenefit.create!(
      employee: @employee,
      name: "Long Term Benefit",
      benefit_type: "health_insurance",
      provider: "Provider",
      coverage: "Coverage",
      start_date: Date.current,
      end_date: Date.current + 6.months,
      status: "active",
      cost: 100.00
    )

    assert_includes EmployeeBenefit.expiring_soon, @benefit
    assert_not_includes EmployeeBenefit.expiring_soon, long_term_benefit
  end

  # Instance method tests
  test "active? should return true for active status" do
    @benefit.status = "active"
    assert @benefit.active?
  end

  test "inactive? should return true for inactive status" do
    @benefit.status = "inactive"
    assert @benefit.inactive?
  end

  test "pending? should return true for pending status" do
    @benefit.status = "pending"
    assert @benefit.pending?
  end

  test "expired? should return true for expired status" do
    @benefit.status = "expired"
    assert @benefit.expired?
  end

  test "is_expired? should return true for expired benefit" do
    @benefit.end_date = Date.current - 1.day
    assert @benefit.is_expired?
  end

  test "is_expiring_soon? should return true for expiring benefit" do
    @benefit.end_date = Date.current + 15.days
    assert @benefit.is_expiring_soon?
  end

  test "days_until_expiry should return days until expiry" do
    @benefit.end_date = Date.current + 30.days
    assert_equal 30, @benefit.days_until_expiry
  end

  test "days_until_expiry should return nil when no end date" do
    @benefit.end_date = nil
    assert_nil @benefit.days_until_expiry
  end

  test "days_since_start should return days since start" do
    @benefit.start_date = Date.current - 10.days
    assert_equal 10, @benefit.days_since_start
  end

  test "employee_name should return employee name" do
    @benefit.save!
    assert_equal @employee.name, @benefit.employee_name
  end

  test "employee_email should return employee email" do
    @benefit.save!
    assert_equal @employee.email, @benefit.employee_email
  end

  test "employee_department should return employee department" do
    @benefit.save!
    assert_equal @employee.department.name, @benefit.employee_department
  end

  test "benefit_type_label should return titleized type" do
    @benefit.benefit_type = "health_insurance"
    assert_equal "Health Insurance", @benefit.benefit_type_label
  end

  test "formatted_start_date should return formatted date" do
    @benefit.start_date = Date.new(2023, 6, 15)
    assert_equal "June 15, 2023", @benefit.formatted_start_date
  end

  test "formatted_end_date should return formatted date when present" do
    @benefit.end_date = Date.new(2023, 6, 20)
    assert_equal "June 20, 2023", @benefit.formatted_end_date
  end

  test "formatted_end_date should return no end date when absent" do
    @benefit.end_date = nil
    assert_equal "No end date", @benefit.formatted_end_date
  end

  test "status_color should return appropriate color for active" do
    @benefit.status = "active"
    assert_equal "green", @benefit.status_color
  end

  test "status_color should return appropriate color for inactive" do
    @benefit.status = "inactive"
    assert_equal "gray", @benefit.status_color
  end

  test "status_color should return appropriate color for pending" do
    @benefit.status = "pending"
    assert_equal "yellow", @benefit.status_color
  end

  test "status_color should return appropriate color for expired" do
    @benefit.status = "expired"
    assert_equal "red", @benefit.status_color
  end

  test "cost_formatted should return formatted cost" do
    @benefit.cost = 500.50
    assert_equal "₹500.5", @benefit.cost_formatted
  end

  test "annual_cost should return yearly cost" do
    @benefit.cost = 500.00
    assert_equal 6000.00, @benefit.annual_cost
  end

  test "annual_cost_formatted should return formatted annual cost" do
    @benefit.cost = 500.00
    assert_equal "₹6000.0", @benefit.annual_cost_formatted
  end

  test "coverage_summary should return formatted summary" do
    assert_equal "Family Coverage - Blue Cross Blue Shield", @benefit.coverage_summary
  end

  test "duration_summary should return formatted duration with end date" do
    @benefit.start_date = Date.new(2023, 6, 1)
    @benefit.end_date = Date.new(2024, 6, 1)
    expected = "June 01, 2023 to June 01, 2024 (366 days)"
    assert_equal expected, @benefit.duration_summary
  end

  test "duration_summary should return ongoing when no end date" do
    @benefit.start_date = Date.new(2023, 6, 1)
    @benefit.end_date = nil
    assert_equal "Started June 01, 2023 (Ongoing)", @benefit.duration_summary
  end

  test "benefit_icon should return appropriate icon for health_insurance" do
    @benefit.benefit_type = "health_insurance"
    assert_equal "🏥", @benefit.benefit_icon
  end

  test "benefit_icon should return appropriate icon for life_insurance" do
    @benefit.benefit_type = "life_insurance"
    assert_equal "🛡️", @benefit.benefit_icon
  end

  test "benefit_icon should return appropriate icon for dental_insurance" do
    @benefit.benefit_type = "dental_insurance"
    assert_equal "🦷", @benefit.benefit_icon
  end

  test "can_edit? should return true for active benefit" do
    @benefit.status = "active"
    assert @benefit.can_edit?
  end

  test "can_edit? should return true for pending benefit" do
    @benefit.status = "pending"
    assert @benefit.can_edit?
  end

  test "can_edit? should return false for inactive benefit" do
    @benefit.status = "inactive"
    assert_not @benefit.can_edit?
  end

  test "can_cancel? should return true for cancellable benefit" do
    @benefit.status = "active"
    @benefit.end_date = Date.current + 1.month
    assert @benefit.can_cancel?
  end

  test "can_cancel? should return false for non-cancellable benefit" do
    @benefit.status = "inactive"
    assert_not @benefit.can_cancel?
  end

  # Callback tests
  test "should update status to expired when end date is past" do
    @benefit.end_date = Date.current - 1.day
    @benefit.save!
    assert_equal "expired", @benefit.status
  end

  # CRUD tests
  test "should be able to create benefit" do
    assert_difference("EmployeeBenefit.count") do
      @benefit.save!
    end
  end

  test "should be able to update benefit" do
    @benefit.save!
    @benefit.name = "Updated Benefit"
    @benefit.save!
    assert_equal "Updated Benefit", @benefit.reload.name
  end

  test "should be able to delete benefit" do
    @benefit.save!
    assert_difference("EmployeeBenefit.count", -1) do
      @benefit.destroy
    end
  end

  # Edge cases
  test "should handle benefit with no end date" do
    @benefit.end_date = nil
    assert @benefit.valid?
    assert_nil @benefit.days_until_expiry
    assert_not @benefit.is_expired?
  end

  test "should handle zero cost benefit" do
    @benefit.cost = 0
    assert @benefit.valid?
    assert_equal 0, @benefit.annual_cost
  end
end
