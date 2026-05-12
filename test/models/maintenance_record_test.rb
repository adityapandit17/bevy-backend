require "test_helper"

class MaintenanceRecordTest < ActiveSupport::TestCase
  def setup
    @asset = assets(:one)
    @record = MaintenanceRecord.new(
      asset: @asset,
      maintenance_date: Date.current,
      maintenance_type: "routine",
      description: "Quarterly hardware check",
      cost: 200.00,
      performed_by: "Tech Support"
    )
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @record.valid?
  end

  # ── Presence validations ──────────────────────────────────────────────────
  test "should require maintenance_date" do
    @record.maintenance_date = nil
    assert_not @record.valid?
    assert_includes @record.errors[:maintenance_date], "can't be blank"
  end

  test "should require maintenance_type" do
    @record.maintenance_type = nil
    assert_not @record.valid?
    assert_includes @record.errors[:maintenance_type], "can't be blank"
  end

  test "should require description" do
    @record.description = nil
    assert_not @record.valid?
    assert_includes @record.errors[:description], "can't be blank"
  end

  test "should require cost" do
    @record.cost = nil
    assert_not @record.valid?
    assert_includes @record.errors[:cost], "can't be blank"
  end

  test "should require performed_by" do
    @record.performed_by = nil
    assert_not @record.valid?
    assert_includes @record.errors[:performed_by], "can't be blank"
  end

  # ── Inclusion validations ─────────────────────────────────────────────────
  test "should reject invalid maintenance_type" do
    @record.maintenance_type = "cleaning"
    assert_not @record.valid?
    assert_includes @record.errors[:maintenance_type], "is not included in the list"
  end

  test "should accept all valid maintenance_types" do
    %w[routine repair upgrade replacement inspection].each do |type|
      @record.maintenance_type = type
      @record.next_maintenance = nil
      assert @record.valid?, "#{type} should be valid"
    end
  end

  # ── Numericality validations ──────────────────────────────────────────────
  test "should reject negative cost" do
    @record.cost = -1
    assert_not @record.valid?
    assert_includes @record.errors[:cost], "must be greater than or equal to 0"
  end

  test "should accept zero cost" do
    @record.cost = 0
    assert @record.valid?
  end

  # ── Associations ──────────────────────────────────────────────────────────
  test "should belong to asset" do
    assert_respond_to @record, :asset
  end

  test "should require asset" do
    @record.asset = nil
    assert_not @record.valid?
  end

  # ── Scopes ────────────────────────────────────────────────────────────────
  test "by_type scope filters by maintenance_type" do
    @record.save!
    assert_includes MaintenanceRecord.by_type("routine"), @record
  end

  test "recent scope orders by maintenance_date descending" do
    @record.maintenance_date = 1.month.ago.to_date
    @record.save!
    newer = MaintenanceRecord.create!(
      asset: assets(:two),
      maintenance_date: Date.current,
      maintenance_type: "repair",
      description: "Emergency fix",
      cost: 500,
      performed_by: "Vendor"
    )
    assert_equal newer, MaintenanceRecord.recent.first
  end

  test "expensive scope returns records with cost > 1000" do
    @record.cost = 1500
    @record.save!
    cheap = MaintenanceRecord.create!(
      asset: assets(:two),
      maintenance_date: Date.current,
      maintenance_type: "repair",
      description: "Minor fix",
      cost: 50,
      performed_by: "Tech"
    )
    assert_includes MaintenanceRecord.expensive, @record
    assert_not_includes MaintenanceRecord.expensive, cheap
  end

  test "by_performer scope filters by performed_by" do
    @record.performed_by = "John Tech"
    @record.save!
    assert_includes MaintenanceRecord.by_performer("John Tech"), @record
  end

  test "this_year scope returns current-year records" do
    @record.maintenance_date = Date.current
    @record.save!
    assert_includes MaintenanceRecord.this_year, @record
  end

  test "last_year scope returns last-year records" do
    @record.maintenance_date = 1.year.ago.to_date
    @record.save!
    assert_includes MaintenanceRecord.last_year, @record
  end

  # ── Callback: set_next_maintenance ────────────────────────────────────────
  test "routine sets next_maintenance 6 months out" do
    @record.maintenance_type = "routine"
    @record.next_maintenance = nil
    @record.save!
    assert_equal @record.maintenance_date + 6.months, @record.reload.next_maintenance
  end

  test "repair sets next_maintenance 3 months out" do
    @record.maintenance_type = "repair"
    @record.next_maintenance = nil
    @record.save!
    assert_equal @record.maintenance_date + 3.months, @record.reload.next_maintenance
  end

  test "upgrade sets next_maintenance 1 year out" do
    @record.maintenance_type = "upgrade"
    @record.next_maintenance = nil
    @record.save!
    assert_equal @record.maintenance_date + 1.year, @record.reload.next_maintenance
  end

  test "replacement sets next_maintenance 2 years out" do
    @record.maintenance_type = "replacement"
    @record.next_maintenance = nil
    @record.save!
    assert_equal @record.maintenance_date + 2.years, @record.reload.next_maintenance
  end

  test "inspection sets next_maintenance 1 month out" do
    @record.maintenance_type = "inspection"
    @record.next_maintenance = nil
    @record.save!
    assert_equal @record.maintenance_date + 1.month, @record.reload.next_maintenance
  end

  test "does not override explicit next_maintenance" do
    explicit_date = Date.current + 10.days
    @record.next_maintenance = explicit_date
    @record.save!
    assert_equal explicit_date, @record.reload.next_maintenance
  end

  # ── Callback: update_asset_maintenance_dates ──────────────────────────────
  test "saving record updates asset last_maintenance and next_maintenance" do
    @record.save!
    @asset.reload
    assert_equal @record.maintenance_date, @asset.last_maintenance
    assert_equal @record.next_maintenance, @asset.next_maintenance
  end

  # ── Instance methods ──────────────────────────────────────────────────────
  test "routine? returns true for routine type" do
    @record.maintenance_type = "routine"
    assert @record.routine?
  end

  test "repair? returns true for repair type" do
    @record.maintenance_type = "repair"
    assert @record.repair?
  end

  test "upgrade? returns true for upgrade type" do
    @record.maintenance_type = "upgrade"
    assert @record.upgrade?
  end

  test "replacement? returns true for replacement type" do
    @record.maintenance_type = "replacement"
    assert @record.replacement?
  end

  test "inspection? returns true for inspection type" do
    @record.maintenance_type = "inspection"
    assert @record.inspection?
  end

  test "expensive? returns true when cost > 1000" do
    @record.cost = 1500
    assert @record.expensive?
  end

  test "expensive? returns false when cost <= 1000" do
    @record.cost = 1000
    assert_not @record.expensive?
  end

  test "overdue? returns true when next_maintenance is in the past" do
    @record.next_maintenance = 1.day.ago.to_date
    assert @record.overdue?
  end

  test "overdue? returns false when next_maintenance is in the future" do
    @record.next_maintenance = 1.day.from_now.to_date
    assert_not @record.overdue?
  end

  test "overdue? returns false when next_maintenance is nil" do
    @record.next_maintenance = nil
    assert_not @record.overdue?
  end

  test "due_soon? returns true when next_maintenance is within 30 days" do
    @record.next_maintenance = 15.days.from_now.to_date
    assert @record.due_soon?
  end

  test "due_soon? returns false when next_maintenance is beyond 30 days" do
    @record.next_maintenance = 45.days.from_now.to_date
    assert_not @record.due_soon?
  end

  test "asset_name delegates to asset" do
    assert_equal @asset.name, @record.asset_name
  end

  test "asset_serial_number delegates to asset" do
    assert_equal @asset.serial_number, @record.asset_serial_number
  end

  test "asset_type delegates to asset" do
    assert_equal @asset.asset_type, @record.asset_type
  end

  test "formatted_cost returns rupee-prefixed cost" do
    @record.cost = 200.00
    assert_equal "₹200.0", @record.formatted_cost
  end

  test "formatted_date returns human-readable maintenance_date" do
    @record.maintenance_date = Date.new(2024, 3, 15)
    assert_equal "March 15, 2024", @record.formatted_date
  end

  test "formatted_next_maintenance returns readable date when set" do
    @record.next_maintenance = Date.new(2024, 9, 15)
    assert_equal "September 15, 2024", @record.formatted_next_maintenance
  end

  test "formatted_next_maintenance returns Not scheduled when nil" do
    @record.next_maintenance = nil
    assert_equal "Not scheduled", @record.formatted_next_maintenance
  end

  test "maintenance_type_label returns titleized type" do
    @record.maintenance_type = "routine"
    assert_equal "Routine", @record.maintenance_type_label
  end

  test "type_color returns correct color for each type" do
    {
      "routine" => "green",
      "repair" => "orange",
      "upgrade" => "blue",
      "replacement" => "red",
      "inspection" => "purple"
    }.each do |type, color|
      @record.maintenance_type = type
      assert_equal color, @record.type_color, "#{type} should be #{color}"
    end
  end

  test "cost_category returns Low for cost 0–100" do
    @record.cost = 50
    assert_equal "Low", @record.cost_category
  end

  test "cost_category returns Medium for cost 101–500" do
    @record.cost = 300
    assert_equal "Medium", @record.cost_category
  end

  test "cost_category returns High for cost 501–1000" do
    @record.cost = 750
    assert_equal "High", @record.cost_category
  end

  test "cost_category returns Very High for cost > 1000" do
    @record.cost = 2000
    assert_equal "Very High", @record.cost_category
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create maintenance record" do
    assert_difference("MaintenanceRecord.count") { @record.save! }
  end

  test "should update maintenance record" do
    @record.save!
    @record.update!(description: "Updated description")
    assert_equal "Updated description", @record.reload.description
  end

  test "should destroy maintenance record" do
    @record.save!
    assert_difference("MaintenanceRecord.count", -1) { @record.destroy }
  end
end
