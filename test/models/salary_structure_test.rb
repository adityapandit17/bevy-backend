require "test_helper"

class SalaryStructureTest < ActiveSupport::TestCase
  def setup
    @employee = create_test_employee(
      email: "salary.test#{SecureRandom.hex(4)}@example.com",
      phone: "9876543210",
      date_of_joining: 6.months.ago.to_date
    )
    @structure = SalaryStructure.new(
      employee: @employee,
      basic: 50000,
      hra: 15000,
      allowances: 10000,
      pf: 1800,
      esi: 750,
      professional_tax: 200,
      income_tax: 1000,
      effective_from: 1.month.ago.to_date
    )
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @structure.valid?
  end

  # ── Presence validations ──────────────────────────────────────────────────
  test "should require effective_from when persisted" do
    @structure.save!
    @structure.effective_from = nil
    assert_not @structure.valid?
    assert_includes @structure.errors[:effective_from], "can't be blank"
  end

  # ── Associations ──────────────────────────────────────────────────────────
  test "should belong to employee" do
    assert_respond_to @structure, :employee
  end

  test "should require employee" do
    @structure.employee = nil
    assert_not @structure.valid?
  end

  # ── Callbacks ─────────────────────────────────────────────────────────────
  test "before_save combines bonus into allowances" do
    @structure.allowances = 10000
    @structure.bonus = 5000
    @structure.save!
    assert_equal 15000, @structure.reload.allowances.to_f
    assert_equal 0, @structure.reload.bonus.to_f
  end

  test "before_save calculates monthly_ctc from annual_ctc" do
    @structure.annual_ctc = 1200000
    @structure.save!
    assert_in_delta 100000.0, @structure.reload.monthly_ctc.to_f, 0.01
  end

  # ── Overlap validation ────────────────────────────────────────────────────
  test "should reject overlapping salary structure periods" do
    @structure.save!
    overlapping = SalaryStructure.new(
      employee: @employee,
      basic: 55000,
      hra: 16000,
      allowances: 11000,
      effective_from: @structure.effective_from
    )
    assert_not overlapping.valid?
    assert overlapping.errors[:base].any?
  end

  test "should allow non-overlapping periods for the same employee" do
    @structure.effective_from = 3.months.ago.to_date
    @structure.effective_upto = 2.months.ago.to_date
    @structure.save!
    next_structure = SalaryStructure.new(
      employee: @employee,
      basic: 55000,
      hra: 16000,
      allowances: 11000,
      effective_from: 1.month.ago.to_date
    )
    assert next_structure.valid?
  end

  test "should allow periods with effective_upto before next from" do
    @structure.effective_from = 4.months.ago.to_date
    @structure.effective_upto = 3.months.ago.to_date
    @structure.save!
    later = SalaryStructure.new(
      employee: @employee,
      basic: 60000,
      hra: 18000,
      allowances: 12000,
      effective_from: 2.months.ago.to_date
    )
    assert later.valid?
  end

  # ── Class methods ─────────────────────────────────────────────────────────
  test "periods_overlap? returns true for identical periods" do
    assert SalaryStructure.periods_overlap?(
      Date.new(2024, 1, 1), Date.new(2024, 3, 31),
      Date.new(2024, 1, 1), Date.new(2024, 3, 31)
    )
  end

  test "periods_overlap? returns false for non-overlapping periods" do
    assert_not SalaryStructure.periods_overlap?(
      Date.new(2024, 1, 1), Date.new(2024, 3, 31),
      Date.new(2024, 4, 1), Date.new(2024, 6, 30)
    )
  end

  test "periods_overlap? handles nil end date (indefinite) correctly" do
    assert SalaryStructure.periods_overlap?(
      Date.new(2024, 1, 1), nil,
      Date.new(2024, 6, 1), nil
    )
  end

  test "periods_overlap? returns true when second period starts before first ends" do
    assert SalaryStructure.periods_overlap?(
      Date.new(2024, 1, 1), Date.new(2024, 6, 30),
      Date.new(2024, 3, 1), Date.new(2024, 9, 30)
    )
  end

  test "generate_defaults_for_employee returns empty array when no structures exist" do
    new_emp = create_test_employee(
      email: "defaults.test#{SecureRandom.hex(4)}@example.com",
      phone: "9876543211",
      date_of_joining: 3.months.ago.to_date
    )
    result = SalaryStructure.generate_defaults_for_employee(new_emp)
    assert_equal [], result
  end

  test "generate_defaults_for_employee fills gap months with zero structures" do
    @structure.effective_from = 1.month.ago.beginning_of_month.to_date
    @structure.save!
    # Employee joined 6 months ago — should create 5 default structures for the intervening months
    defaults = SalaryStructure.generate_defaults_for_employee(@employee)
    assert defaults.length >= 1
    defaults.each do |s|
      assert_equal 0, s.basic.to_f
    end
  end

  test "for_month returns structure effective for given month" do
    @structure.save!
    result = SalaryStructure.for_month(@employee, @structure.effective_from.year, @structure.effective_from.month)
    assert_not_nil result
  end

  test "resolve_duplicates keeps latest created structure per month" do
    @structure.save!
    later = SalaryStructure.create!(
      employee: @employee,
      basic: 60000,
      hra: 18000,
      allowances: 12000,
      effective_from: @structure.effective_from
    )
    resolved = SalaryStructure.resolve_duplicates([@structure, later])
    assert_includes resolved, later
    assert_not_includes resolved, @structure
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create salary structure" do
    assert_difference("SalaryStructure.count") { @structure.save! }
  end

  test "should update salary structure" do
    @structure.save!
    @structure.update!(basic: 55000)
    assert_equal 55000, @structure.reload.basic.to_f
  end

  test "should destroy salary structure" do
    @structure.save!
    assert_difference("SalaryStructure.count", -1) { @structure.destroy }
  end
end
