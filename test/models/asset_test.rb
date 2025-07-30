require "test_helper"

class AssetTest < ActiveSupport::TestCase
  def setup
    @employee = employees(:one)
    @asset = Asset.new(
      name: "MacBook Pro",
      asset_type: "laptop",
      serial_number: "MBP123456789",
      brand: "Apple",
      model: "MacBook Pro 16-inch",
      purchase_date: Date.current,
      purchase_cost: 2500.00,
      current_value: 2500.00,
      status: "available",
      location: "Office A",
      department: "Engineering",
      condition: "excellent"
    )
  end

  test "should be valid with valid attributes" do
    assert @asset.valid?
  end

  test "should require name" do
    @asset.name = nil
    assert_not @asset.valid?
    assert_includes @asset.errors[:name], "can't be blank"
  end

  test "should require asset_type" do
    @asset.asset_type = nil
    assert_not @asset.valid?
    assert_includes @asset.errors[:asset_type], "can't be blank"
  end

  test "should validate asset_type inclusion" do
    @asset.asset_type = "invalid_type"
    assert_not @asset.valid?
    assert_includes @asset.errors[:asset_type], "is not included in the list"
  end

  test "should accept valid asset types" do
    valid_types = %w[laptop desktop mobile printer server network other]
    valid_types.each do |type|
      @asset.asset_type = type
      assert @asset.valid?, "#{type} should be valid"
    end
  end

  test "should require serial_number" do
    @asset.serial_number = nil
    assert_not @asset.valid?
    assert_includes @asset.errors[:serial_number], "can't be blank"
  end

  test "should require unique serial_number" do
    @asset.save!
    duplicate_asset = @asset.dup
    duplicate_asset.serial_number = @asset.serial_number
    assert_not duplicate_asset.valid?
    assert_includes duplicate_asset.errors[:serial_number], "has already been taken"
  end

  test "should require brand" do
    @asset.brand = nil
    assert_not @asset.valid?
    assert_includes @asset.errors[:brand], "can't be blank"
  end

  test "should require model" do
    @asset.model = nil
    assert_not @asset.valid?
    assert_includes @asset.errors[:model], "can't be blank"
  end

  test "should require purchase_date" do
    @asset.purchase_date = nil
    assert_not @asset.valid?
    assert_includes @asset.errors[:purchase_date], "can't be blank"
  end

  test "should require purchase_cost" do
    @asset.purchase_cost = nil
    assert_not @asset.valid?
    assert_includes @asset.errors[:purchase_cost], "can't be blank"
  end

  test "should validate purchase_cost is greater than 0" do
    @asset.purchase_cost = 0
    assert_not @asset.valid?
    assert_includes @asset.errors[:purchase_cost], "must be greater than 0"
    
    @asset.purchase_cost = -100
    assert_not @asset.valid?
    assert_includes @asset.errors[:purchase_cost], "must be greater than 0"
  end

  test "should require current_value" do
    @asset.current_value = nil
    assert_not @asset.valid?
    assert_includes @asset.errors[:current_value], "can't be blank"
  end

  test "should validate current_value is greater than or equal to 0" do
    @asset.current_value = -100
    assert_not @asset.valid?
    assert_includes @asset.errors[:current_value], "must be greater than or equal to 0"
  end

  test "should require status" do
    @asset.status = nil
    assert_not @asset.valid?
    assert_includes @asset.errors[:status], "can't be blank"
  end

  test "should validate status inclusion" do
    @asset.status = "invalid_status"
    assert_not @asset.valid?
    assert_includes @asset.errors[:status], "is not included in the list"
  end

  test "should accept valid statuses" do
    valid_statuses = %w[available assigned maintenance retired lost]
    valid_statuses.each do |status|
      @asset.status = status
      assert @asset.valid?, "#{status} should be valid"
    end
  end

  test "should require location" do
    @asset.location = nil
    assert_not @asset.valid?
    assert_includes @asset.errors[:location], "can't be blank"
  end

  test "should require department" do
    @asset.department = nil
    assert_not @asset.valid?
    assert_includes @asset.errors[:department], "can't be blank"
  end

  test "should require condition" do
    @asset.condition = nil
    assert_not @asset.valid?
    assert_includes @asset.errors[:condition], "can't be blank"
  end

  test "should validate condition inclusion" do
    @asset.condition = "invalid_condition"
    assert_not @asset.valid?
    assert_includes @asset.errors[:condition], "is not included in the list"
  end

  test "should accept valid conditions" do
    valid_conditions = %w[excellent good fair poor]
    valid_conditions.each do |condition|
      @asset.condition = condition
      assert @asset.valid?, "#{condition} should be valid"
    end
  end

  # Association tests
  test "should belong to employee optionally" do
    @asset.employee = nil
    assert @asset.valid?
    
    @asset.employee = @employee
    assert @asset.valid?
  end

  test "should have many asset_allocations" do
    assert_respond_to @asset, :asset_allocations
  end

  test "should have many maintenance_records" do
    assert_respond_to @asset, :maintenance_records
  end

  # Scope tests
  test "available scope should return available assets" do
    @asset.save!
    assigned_asset = Asset.create!(
      name: "Dell Laptop",
      asset_type: "laptop",
      serial_number: "DELL123456789",
      brand: "Dell",
      model: "Latitude",
      purchase_date: Date.current,
      purchase_cost: 1500.00,
      current_value: 1500.00,
      status: "assigned",
      location: "Office B",
      department: "Sales",
      condition: "good",
      employee: @employee
    )
    
    assert_includes Asset.available, @asset
    assert_not_includes Asset.available, assigned_asset
  end

  test "assigned scope should return assigned assets" do
    @asset.status = "assigned"
    @asset.employee = @employee
    @asset.save!
    
    assert_includes Asset.assigned, @asset
  end

  test "maintenance scope should return maintenance assets" do
    @asset.status = "maintenance"
    @asset.save!
    
    assert_includes Asset.maintenance, @asset
  end

  test "retired scope should return retired assets" do
    @asset.status = "retired"
    @asset.save!
    
    assert_includes Asset.retired, @asset
  end

  test "lost scope should return lost assets" do
    @asset.status = "lost"
    @asset.save!
    
    assert_includes Asset.lost, @asset
  end

  test "by_type scope should filter by asset type" do
    @asset.save!
    desktop_asset = Asset.create!(
      name: "Desktop PC",
      asset_type: "desktop",
      serial_number: "DESK123456789",
      brand: "HP",
      model: "EliteDesk",
      purchase_date: Date.current,
      purchase_cost: 800.00,
      current_value: 800.00,
      status: "available",
      location: "Office C",
      department: "IT",
      condition: "good"
    )
    
    assert_includes Asset.by_type("laptop"), @asset
    assert_not_includes Asset.by_type("laptop"), desktop_asset
  end

  test "by_department scope should filter by department" do
    @asset.save!
    sales_asset = Asset.create!(
      name: "Sales Laptop",
      asset_type: "laptop",
      serial_number: "SALES123456789",
      brand: "Lenovo",
      model: "ThinkPad",
      purchase_date: Date.current,
      purchase_cost: 1200.00,
      current_value: 1200.00,
      status: "available",
      location: "Office D",
      department: "Sales",
      condition: "good"
    )
    
    assert_includes Asset.by_department("Engineering"), @asset
    assert_not_includes Asset.by_department("Engineering"), sales_asset
  end

  test "by_condition scope should filter by condition" do
    @asset.save!
    fair_asset = Asset.create!(
      name: "Fair Laptop",
      asset_type: "laptop",
      serial_number: "FAIR123456789",
      brand: "Acer",
      model: "Aspire",
      purchase_date: Date.current,
      purchase_cost: 600.00,
      current_value: 600.00,
      status: "available",
      location: "Office E",
      department: "Marketing",
      condition: "fair"
    )
    
    assert_includes Asset.by_condition("excellent"), @asset
    assert_not_includes Asset.by_condition("excellent"), fair_asset
  end

  test "overdue_maintenance scope should return assets with overdue maintenance" do
    @asset.next_maintenance = 1.day.ago
    @asset.save!
    
    assert_includes Asset.overdue_maintenance, @asset
  end

  test "due_maintenance_soon scope should return assets due for maintenance soon" do
    @asset.next_maintenance = 15.days.from_now
    @asset.save!
    
    assert_includes Asset.due_maintenance_soon, @asset
  end

  test "warranty_expiring_soon scope should return assets with expiring warranty" do
    @asset.warranty_expiry = 45.days.from_now
    @asset.save!
    
    assert_includes Asset.warranty_expiring_soon, @asset
  end

  # Instance method tests
  test "assigned? should return true when assigned to employee" do
    @asset.status = "assigned"
    @asset.employee = @employee
    assert @asset.assigned?
  end

  test "assigned? should return false when not assigned" do
    @asset.status = "available"
    @asset.employee = nil
    assert_not @asset.assigned?
  end

  test "available? should return true for available status" do
    @asset.status = "available"
    assert @asset.available?
  end

  test "under_maintenance? should return true for maintenance status" do
    @asset.status = "maintenance"
    assert @asset.under_maintenance?
  end

  test "retired? should return true for retired status" do
    @asset.status = "retired"
    assert @asset.retired?
  end

  test "lost? should return true for lost status" do
    @asset.status = "lost"
    assert @asset.lost?
  end

  test "overdue_maintenance? should return true for overdue maintenance" do
    @asset.next_maintenance = 1.day.ago
    assert @asset.overdue_maintenance?
  end

  test "due_maintenance_soon? should return true for maintenance due soon" do
    @asset.next_maintenance = 15.days.from_now
    assert @asset.due_maintenance_soon?
  end

  test "warranty_expiring_soon? should return true for expiring warranty" do
    @asset.warranty_expiry = 45.days.from_now
    assert @asset.warranty_expiring_soon?
  end

  test "warranty_expired? should return true for expired warranty" do
    @asset.warranty_expiry = 1.day.ago
    assert @asset.warranty_expired?
  end

  test "age_in_years should calculate asset age" do
    @asset.purchase_date = 2.years.ago
    assert_equal 2, @asset.age_in_years
  end

  test "depreciation_rate should return correct rate for laptop" do
    @asset.asset_type = "laptop"
    assert_equal 0.25, @asset.depreciation_rate
  end

  test "depreciation_rate should return correct rate for mobile" do
    @asset.asset_type = "mobile"
    assert_equal 0.40, @asset.depreciation_rate
  end

  test "depreciation_rate should return correct rate for printer" do
    @asset.asset_type = "printer"
    assert_equal 0.20, @asset.depreciation_rate
  end

  test "depreciation_rate should return correct rate for server" do
    @asset.asset_type = "server"
    assert_equal 0.15, @asset.depreciation_rate
  end

  test "depreciation_rate should return default rate for other types" do
    @asset.asset_type = "other"
    assert_equal 0.20, @asset.depreciation_rate
  end

  test "total_maintenance_cost should sum maintenance records" do
    @asset.save!
    @asset.maintenance_records.create!(
      maintenance_date: Date.current,
      maintenance_type: "routine",
      description: "Regular maintenance",
      cost: 100.00,
      performed_by: "Tech Support"
    )
    @asset.maintenance_records.create!(
      maintenance_date: Date.current,
      maintenance_type: "repair",
      description: "Screen replacement",
      cost: 300.00,
      performed_by: "Apple Service"
    )
    
    assert_equal 400.00, @asset.total_maintenance_cost
  end

  test "last_maintenance_record should return most recent maintenance" do
    @asset.save!
    old_maintenance = @asset.maintenance_records.create!(
      maintenance_date: 1.month.ago,
      maintenance_type: "routine",
      description: "Old maintenance",
      cost: 50.00,
      performed_by: "Tech Support"
    )
    recent_maintenance = @asset.maintenance_records.create!(
      maintenance_date: Date.current,
      maintenance_type: "repair",
      description: "Recent maintenance",
      cost: 150.00,
      performed_by: "Apple Service"
    )
    
    assert_equal recent_maintenance, @asset.last_maintenance_record
  end

  test "current_allocation should return active allocation" do
    @asset.save!
    allocation = @asset.asset_allocations.create!(
      employee: @employee,
      assigned_date: Date.current,
      status: "active"
    )
    
    assert_equal allocation, @asset.current_allocation
  end

  test "employee_name should return employee name when assigned" do
    @asset.employee = @employee
    assert_equal @employee.name, @asset.employee_name
  end

  test "employee_name should return 'Not assigned' when not assigned" do
    @asset.employee = nil
    assert_equal "Not assigned", @asset.employee_name
  end

  test "employee_email should return employee email when assigned" do
    @asset.employee = @employee
    assert_equal @employee.email, @asset.employee_email
  end

  test "employee_email should return nil when not assigned" do
    @asset.employee = nil
    assert_nil @asset.employee_email
  end

  test "employee_department should return employee department when assigned" do
    @asset.employee = @employee
    assert_equal @employee.department.name, @asset.employee_department
  end

  test "employee_department should return asset department when not assigned" do
    @asset.employee = nil
    assert_equal "Engineering", @asset.employee_department
  end

  test "full_name should return formatted asset name" do
    assert_equal "Apple MacBook Pro 16-inch - MBP123456789", @asset.full_name
  end

  test "status_color should return appropriate color" do
    @asset.status = "available"
    assert_equal "green", @asset.status_color
    
    @asset.status = "assigned"
    assert_equal "blue", @asset.status_color
    
    @asset.status = "maintenance"
    assert_equal "orange", @asset.status_color
    
    @asset.status = "retired"
    assert_equal "gray", @asset.status_color
    
    @asset.status = "lost"
    assert_equal "red", @asset.status_color
  end

  test "condition_color should return appropriate color" do
    @asset.condition = "excellent"
    assert_equal "green", @asset.condition_color
    
    @asset.condition = "good"
    assert_equal "blue", @asset.condition_color
    
    @asset.condition = "fair"
    assert_equal "yellow", @asset.condition_color
    
    @asset.condition = "poor"
    assert_equal "red", @asset.condition_color
  end

  # Callback tests
  test "should calculate depreciation before save" do
    @asset.purchase_date = 2.years.ago
    @asset.purchase_cost = 1000.00
    @asset.asset_type = "laptop" # 25% depreciation per year
    @asset.save!
    
    # After 2 years: 1000 * (1 - 0.25)^2 = 1000 * 0.5625 = 562.50
    assert_equal 562.50, @asset.current_value
  end

  test "should update status to assigned when employee is present" do
    @asset.status = "available"
    @asset.employee = @employee
    @asset.save!
    
    assert_equal "assigned", @asset.status
  end

  test "should update status to available when employee is removed" do
    @asset.status = "assigned"
    @asset.employee = @employee
    @asset.save!
    
    @asset.employee = nil
    @asset.save!
    
    assert_equal "available", @asset.status
  end
end
