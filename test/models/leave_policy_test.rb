require "test_helper"

class LeavePolicyTest < ActiveSupport::TestCase
  def setup
    # Use a far-future year to avoid conflicts with any seeded data
    @year = 2099
    @policy = LeavePolicy.new(
      year: @year,
      holidays_per_year: 10,
      annual_leave: 21,
      sick_leave: 12,
      personal_leave: 5,
      maternity_leave: 90,
      paternity_leave: 15,
      unpaid_leave: 30,
      other_leave: 5,
      active: true
    )
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @policy.valid?
  end

  # ── Presence validations ──────────────────────────────────────────────────
  test "should require year" do
    @policy.year = nil
    assert_not @policy.valid?
    assert_includes @policy.errors[:year], "can't be blank"
  end

  test "should require annual_leave" do
    @policy.annual_leave = nil
    assert_not @policy.valid?
    assert_includes @policy.errors[:annual_leave], "can't be blank"
  end

  test "should require sick_leave" do
    @policy.sick_leave = nil
    assert_not @policy.valid?
    assert_includes @policy.errors[:sick_leave], "can't be blank"
  end

  test "should require personal_leave" do
    @policy.personal_leave = nil
    assert_not @policy.valid?
    assert_includes @policy.errors[:personal_leave], "can't be blank"
  end

  test "should require maternity_leave" do
    @policy.maternity_leave = nil
    assert_not @policy.valid?
    assert_includes @policy.errors[:maternity_leave], "can't be blank"
  end

  test "should require paternity_leave" do
    @policy.paternity_leave = nil
    assert_not @policy.valid?
    assert_includes @policy.errors[:paternity_leave], "can't be blank"
  end

  test "should require unpaid_leave" do
    @policy.unpaid_leave = nil
    assert_not @policy.valid?
    assert_includes @policy.errors[:unpaid_leave], "can't be blank"
  end

  test "should require other_leave" do
    @policy.other_leave = nil
    assert_not @policy.valid?
    assert_includes @policy.errors[:other_leave], "can't be blank"
  end

  # ── Numericality validations ──────────────────────────────────────────────
  test "should reject negative annual_leave" do
    @policy.annual_leave = -1
    assert_not @policy.valid?
  end

  test "should accept zero for leave fields" do
    @policy.sick_leave = 0
    assert @policy.valid?
  end

  test "should reject non-integer annual_leave" do
    @policy.annual_leave = 10.5
    assert_not @policy.valid?
  end

  # ── Uniqueness ────────────────────────────────────────────────────────────
  test "should enforce unique year" do
    @policy.save!
    dup = LeavePolicy.new(
      year: @year,
      holidays_per_year: 10,
      annual_leave: 21,
      sick_leave: 12,
      personal_leave: 5,
      maternity_leave: 90,
      paternity_leave: 15,
      unpaid_leave: 30,
      other_leave: 5,
      active: true
    )
    assert_not dup.valid?
    assert_includes dup.errors[:year], "has already been taken"
  end

  # ── Scopes ────────────────────────────────────────────────────────────────
  test "active scope returns active policies" do
    @policy.save!
    inactive = LeavePolicy.create!(
      year: @year - 1,
      holidays_per_year: 10,
      annual_leave: 15,
      sick_leave: 10,
      personal_leave: 5,
      maternity_leave: 90,
      paternity_leave: 15,
      unpaid_leave: 30,
      other_leave: 5,
      active: false
    )
    assert_includes LeavePolicy.active, @policy
    assert_not_includes LeavePolicy.active, inactive
  end

  test "by_year scope filters by year" do
    @policy.save!
    assert_includes LeavePolicy.by_year(@year), @policy
  end

  # ── Instance methods ──────────────────────────────────────────────────────
  test "leave_limit_for_type returns annual_leave for annual" do
    assert_equal 21, @policy.leave_limit_for_type("annual")
  end

  test "leave_limit_for_type returns sick_leave for sick" do
    assert_equal 12, @policy.leave_limit_for_type("sick")
  end

  test "leave_limit_for_type returns personal_leave for personal" do
    assert_equal 5, @policy.leave_limit_for_type("personal")
  end

  test "leave_limit_for_type returns maternity_leave for maternity" do
    assert_equal 90, @policy.leave_limit_for_type("maternity")
  end

  test "leave_limit_for_type returns paternity_leave for paternity" do
    assert_equal 15, @policy.leave_limit_for_type("paternity")
  end

  test "leave_limit_for_type returns unpaid_leave for unpaid" do
    assert_equal 30, @policy.leave_limit_for_type("unpaid")
  end

  test "leave_limit_for_type returns other_leave for other" do
    assert_equal 5, @policy.leave_limit_for_type("other")
  end

  test "leave_limit_for_type returns 0 for unknown type" do
    assert_equal 0, @policy.leave_limit_for_type("vacation")
  end

  test "to_hash returns all policy fields" do
    hash = @policy.to_hash
    assert_equal @year, hash[:year]
    assert_equal 21, hash[:annual_leave]
    assert_equal 12, hash[:sick_leave]
    assert_equal true, hash[:active]
  end

  # ── Class methods ─────────────────────────────────────────────────────────
  test "for_year returns existing active policy for given year" do
    @policy.save!
    result = LeavePolicy.for_year(@year)
    assert_equal @policy, result
  end

  test "for_year creates default policy when none exists for year" do
    future_year = @year + 1
    LeavePolicy.where(year: future_year).destroy_all
    result = LeavePolicy.for_year(future_year)
    assert_not_nil result
    assert_equal future_year, result.year
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create leave policy" do
    assert_difference("LeavePolicy.count") { @policy.save! }
  end

  test "should update leave policy" do
    @policy.save!
    @policy.update!(annual_leave: 25)
    assert_equal 25, @policy.reload.annual_leave
  end

  test "should destroy leave policy" do
    @policy.save!
    assert_difference("LeavePolicy.count", -1) { @policy.destroy }
  end
end
