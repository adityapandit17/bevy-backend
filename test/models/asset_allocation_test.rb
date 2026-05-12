require "test_helper"

class AssetAllocationTest < ActiveSupport::TestCase
  def setup
    @employee = employees(:one)
    # Use an asset not already active-allocated by fixtures
    @asset = Asset.create!(
      name: "Test Laptop #{SecureRandom.hex(4)}",
      asset_type: "laptop",
      serial_number: "SN-#{SecureRandom.hex(6)}",
      status: "available",
      condition: "good",
      purchase_date: 1.year.ago.to_date,
      purchase_cost: 1000
    )
    @allocation = AssetAllocation.new(
      asset: @asset,
      employee: @employee,
      assigned_date: Date.current,
      status: "active"
    )
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @allocation.valid?
  end

  # ── Presence validations ──────────────────────────────────────────────────
  test "should require assigned_date" do
    @allocation.assigned_date = nil
    assert_not @allocation.valid?
    assert_includes @allocation.errors[:assigned_date], "can't be blank"
  end

  test "should require status" do
    @allocation.status = nil
    assert_not @allocation.valid?
    assert_includes @allocation.errors[:status], "can't be blank"
  end

  # ── Inclusion validations ─────────────────────────────────────────────────
  test "should reject invalid status" do
    @allocation.status = "lost"
    assert_not @allocation.valid?
    assert_includes @allocation.errors[:status], "is not included in the list"
  end

  test "should accept active and returned statuses" do
    %w[active returned].each do |s|
      @allocation.status = s
      assert @allocation.valid?, "#{s} should be valid"
    end
  end

  # ── Uniqueness: one active allocation per asset ───────────────────────────
  test "should reject second active allocation for same asset" do
    @allocation.save!
    dup = AssetAllocation.new(
      asset: @asset,
      employee: employees(:two),
      assigned_date: Date.current,
      status: "active"
    )
    assert_not dup.valid?
    assert dup.errors[:asset_id].any?
  end

  test "should allow returned allocation on same asset after another is active" do
    @allocation.save!
    returned = AssetAllocation.new(
      asset: @asset,
      employee: employees(:two),
      assigned_date: 1.month.ago.to_date,
      return_date: 1.week.ago.to_date,
      status: "returned"
    )
    assert returned.valid?
  end

  test "should allow active allocation on different asset" do
    @allocation.save!
    other_asset = Asset.create!(
      name: "Other Asset #{SecureRandom.hex(4)}",
      asset_type: "desktop",
      serial_number: "SN-#{SecureRandom.hex(6)}",
      status: "available",
      condition: "good",
      purchase_date: 1.year.ago.to_date,
      purchase_cost: 500
    )
    other = AssetAllocation.new(
      asset: other_asset,
      employee: @employee,
      assigned_date: Date.current,
      status: "active"
    )
    assert other.valid?
  end

  # ── Associations ──────────────────────────────────────────────────────────
  test "should belong to asset" do
    assert_respond_to @allocation, :asset
  end

  test "should belong to employee" do
    assert_respond_to @allocation, :employee
  end

  test "should require asset" do
    @allocation.asset = nil
    assert_not @allocation.valid?
  end

  test "should require employee" do
    @allocation.employee = nil
    assert_not @allocation.valid?
  end

  # ── Scopes ────────────────────────────────────────────────────────────────
  test "active scope returns active allocations" do
    @allocation.save!
    assert_includes AssetAllocation.active, @allocation
  end

  test "returned scope returns returned allocations" do
    @allocation.status = "returned"
    @allocation.save!
    assert_includes AssetAllocation.returned, @allocation
  end

  test "by_employee scope filters by employee_id" do
    @allocation.save!
    assert_includes AssetAllocation.by_employee(@employee.id), @allocation
  end

  test "by_asset scope filters by asset_id" do
    @allocation.save!
    assert_includes AssetAllocation.by_asset(@asset.id), @allocation
  end

  test "recent scope orders by assigned_date descending" do
    @allocation.assigned_date = 1.month.ago.to_date
    @allocation.save!
    newer_asset = Asset.create!(
      name: "Newer Asset #{SecureRandom.hex(4)}",
      asset_type: "laptop",
      serial_number: "SN-#{SecureRandom.hex(6)}",
      status: "available",
      condition: "good",
      purchase_date: 1.year.ago.to_date,
      purchase_cost: 800
    )
    newer = AssetAllocation.create!(
      asset: newer_asset,
      employee: @employee,
      assigned_date: Date.current,
      status: "active"
    )
    assert_equal newer, AssetAllocation.recent.first
  end

  # ── Callbacks ─────────────────────────────────────────────────────────────
  test "set_assigned_date defaults to today when not set" do
    @allocation.assigned_date = nil
    @allocation.save!
    assert_equal Date.current, @allocation.reload.assigned_date
  end

  test "update_asset_status sets asset to assigned after create" do
    @allocation.save!
    assert_equal "assigned", @asset.reload.status
  end

  test "update_asset_status_on_return sets asset to available on return" do
    @allocation.save!
    @allocation.update!(status: "returned", return_date: Date.current)
    assert_equal "available", @asset.reload.status
  end

  # ── Instance methods ──────────────────────────────────────────────────────
  test "active? returns true when status is active" do
    @allocation.status = "active"
    assert @allocation.active?
  end

  test "returned? returns true when status is returned" do
    @allocation.status = "returned"
    assert @allocation.returned?
  end

  test "duration_days returns days since assigned_date" do
    @allocation.assigned_date = 10.days.ago.to_date
    assert_equal 10, @allocation.duration_days
  end

  test "duration_days uses return_date when set" do
    @allocation.assigned_date = 20.days.ago.to_date
    @allocation.return_date = 5.days.ago.to_date
    assert_equal 15, @allocation.duration_days
  end

  test "duration_days returns 0 when assigned_date is nil" do
    @allocation.assigned_date = nil
    assert_equal 0, @allocation.duration_days
  end

  test "employee_name delegates to employee" do
    assert_equal @employee.name, @allocation.employee_name
  end

  test "employee_email delegates to employee" do
    assert_equal @employee.email, @allocation.employee_email
  end

  test "asset_name delegates to asset" do
    assert_equal @asset.name, @allocation.asset_name
  end

  test "asset_serial_number delegates to asset" do
    assert_equal @asset.serial_number, @allocation.asset_serial_number
  end

  test "asset_type delegates to asset" do
    assert_equal @asset.asset_type, @allocation.asset_type
  end

  test "return_asset sets status to returned and sets return_date" do
    @allocation.save!
    @allocation.return_asset(Date.current, "Returned in good condition")
    @allocation.reload
    assert_equal "returned", @allocation.status
    assert_equal Date.current, @allocation.return_date
    assert_equal "Returned in good condition", @allocation.notes
  end

  test "extend_allocation appends note when active" do
    @allocation.save!
    new_date = 1.month.from_now.to_date
    result = @allocation.extend_allocation(new_date)
    assert result
    assert_includes @allocation.reload.notes.to_s, "Extended to: #{new_date}"
  end

  test "extend_allocation returns false when not active" do
    @allocation.status = "returned"
    @allocation.save!
    assert_equal false, @allocation.extend_allocation(Date.current + 30)
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create asset allocation" do
    assert_difference("AssetAllocation.count") { @allocation.save! }
  end

  test "should update asset allocation notes" do
    @allocation.save!
    @allocation.update!(notes: "Updated notes")
    assert_equal "Updated notes", @allocation.reload.notes
  end

  test "should destroy asset allocation" do
    @allocation.save!
    assert_difference("AssetAllocation.count", -1) { @allocation.destroy }
  end
end
