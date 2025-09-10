require "test_helper"

class CompanyTest < ActiveSupport::TestCase
  def setup
    @company = Company.new(
      name: "TechCorp Solutions",
      code: "TECH",
      industry: "Technology",
      employee_count: "500",
      address: "123 Tech Street, Silicon Valley, CA",
      timezone: "America/Los_Angeles",
      currency: "USD"
    )
  end

  test "should be valid with valid attributes" do
    assert @company.valid?
  end

  test "should require name" do
    @company.name = nil
    assert_not @company.valid?
    assert_includes @company.errors[:name], "can't be blank"
  end

  test "should validate name length" do
    @company.name = "A"
    assert_not @company.valid?
    assert_includes @company.errors[:name], "is too short (minimum is 2 characters)"

    @company.name = "A" * 101
    assert_not @company.valid?
    assert_includes @company.errors[:name], "is too long (maximum is 100 characters)"
  end

  test "should require code" do
    @company.code = nil
    assert_not @company.valid?
    assert_includes @company.errors[:code], "can't be blank"
  end

  test "should validate code uniqueness" do
    @company.save!
    duplicate_company = @company.dup
    duplicate_company.name = "Different Name"
    assert_not duplicate_company.valid?
    assert_includes duplicate_company.errors[:code], "has already been taken"
  end

  test "should validate code length" do
    @company.code = "A"
    assert_not @company.valid?
    assert_includes @company.errors[:code], "is too short (minimum is 2 characters)"

    @company.code = "ABCDEFGHIJK"
    assert_not @company.valid?
    assert_includes @company.errors[:code], "is too long (maximum is 10 characters)"
  end

  test "should require industry" do
    @company.industry = nil
    assert_not @company.valid?
    assert_includes @company.errors[:industry], "can't be blank"
  end

  test "should require employee_count" do
    @company.employee_count = nil
    assert_not @company.valid?
    assert_includes @company.errors[:employee_count], "can't be blank"
  end

  test "should require timezone" do
    @company.timezone = nil
    assert_not @company.valid?
    assert_includes @company.errors[:timezone], "can't be blank"
  end

  test "should require currency" do
    @company.currency = nil
    assert_not @company.valid?
    assert_includes @company.errors[:currency], "can't be blank"
  end

  test "should validate currency length" do
    @company.currency = "US"
    assert_not @company.valid?
    assert_includes @company.errors[:currency], "is the wrong length (should be 3 characters)"

    @company.currency = "USDD"
    assert_not @company.valid?
    assert_includes @company.errors[:currency], "is the wrong length (should be 3 characters)"
  end

  # Scope tests
  test "by_industry scope should filter by industry" do
    @company.save!
    finance_company = Company.create!(
      name: "Finance Corp",
      code: "FIN",
      industry: "Finance",
      employee_count: "200",
      timezone: "America/New_York",
      currency: "USD"
    )

    assert_includes Company.by_industry("Technology"), @company
    assert_not_includes Company.by_industry("Technology"), finance_company
  end

  test "large_companies scope should return companies with more than 1000 employees" do
    @company.employee_count = "1500"
    @company.save!

    small_company = Company.create!(
      name: "Small Corp",
      code: "SMALL",
      industry: "Technology",
      employee_count: "50",
      timezone: "America/New_York",
      currency: "USD"
    )

    assert_includes Company.large_companies, @company
    assert_not_includes Company.large_companies, small_company
  end

  test "small_companies scope should return companies with 100 or fewer employees" do
    @company.employee_count = "50"
    @company.save!

    large_company = Company.create!(
      name: "Large Corp",
      code: "LARGE",
      industry: "Technology",
      employee_count: "1500",
      timezone: "America/New_York",
      currency: "USD"
    )

    assert_includes Company.small_companies, @company
    assert_not_includes Company.small_companies, large_company
  end

  # Instance method tests
  test "formatted_employee_count should return formatted string" do
    @company.employee_count = "500"
    assert_equal "500 employees", @company.formatted_employee_count
  end

  test "display_name should return name with code" do
    assert_equal "TechCorp Solutions (TECH)", @company.display_name
  end

  # CRUD tests
  test "should be able to create company" do
    assert_difference("Company.count") do
      @company.save!
    end
  end

  test "should be able to update company" do
    @company.save!
    @company.name = "Updated TechCorp"
    @company.save!
    assert_equal "Updated TechCorp", @company.reload.name
  end

  test "should be able to delete company" do
    @company.save!
    assert_difference("Company.count", -1) do
      @company.destroy
    end
  end
end
