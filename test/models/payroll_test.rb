require "test_helper"

class PayrollTest < ActiveSupport::TestCase
  def setup
    @employee = employees(:one)
    @payroll = Payroll.new(
      employee: @employee,
      month: "2024-01-01",
      gross_salary: 75000.00,
      net_salary: 70000.00,
      status: "pending",
      working_days: 23,
      payable_days: 22,
      unpaid_days: 1,
      leave_deduction: 3260.87
    )
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @payroll.valid?
  end

  # ── Associations ──────────────────────────────────────────────────────────
  test "should belong to employee" do
    assert_respond_to @payroll, :employee
  end

  test "should require employee" do
    @payroll.employee = nil
    assert_not @payroll.valid?
  end

  # ── Attribute presence ────────────────────────────────────────────────────
  test "should persist gross_salary" do
    @payroll.save!
    assert_equal 75000.00, @payroll.reload.gross_salary.to_f
  end

  test "should persist net_salary" do
    @payroll.save!
    assert_equal 70000.00, @payroll.reload.net_salary.to_f
  end

  test "should persist status" do
    @payroll.save!
    assert_equal "pending", @payroll.reload.status
  end

  test "should persist month" do
    @payroll.save!
    assert_not_nil @payroll.reload.month
  end

  test "should persist leave_deduction" do
    @payroll.save!
    assert_in_delta 3260.87, @payroll.reload.leave_deduction.to_f, 0.01
  end

  # ── JSONB breakdown columns ───────────────────────────────────────────────
  test "should store and retrieve earnings_breakdown as hash" do
    @payroll.earnings_breakdown = { "basic" => 50000, "hra" => 15000, "allowances" => 10000 }
    @payroll.save!
    reloaded = @payroll.reload.earnings_breakdown
    assert_equal 50000, reloaded["basic"]
    assert_equal 15000, reloaded["hra"]
  end

  test "should store and retrieve deductions_breakdown as hash" do
    @payroll.deductions_breakdown = { "pf" => 1800, "esi" => 750, "leave_deduction" => 3260.87 }
    @payroll.save!
    reloaded = @payroll.reload.deductions_breakdown
    assert_equal 1800, reloaded["pf"]
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create payroll" do
    assert_difference("Payroll.count") { @payroll.save! }
  end

  test "should update payroll" do
    @payroll.save!
    @payroll.update!(status: "approved")
    assert_equal "approved", @payroll.reload.status
  end

  test "should destroy payroll" do
    @payroll.save!
    assert_difference("Payroll.count", -1) { @payroll.destroy }
  end

  # ── Fixture smoke tests ───────────────────────────────────────────────────
  test "fixture one should be valid" do
    assert payrolls(:one).valid?
  end

  test "fixture two should be valid" do
    assert payrolls(:two).valid?
  end

  test "fixture one belongs to employee one" do
    assert_equal employees(:one), payrolls(:one).employee
  end
end
