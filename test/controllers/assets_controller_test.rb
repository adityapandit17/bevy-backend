require "test_helper"

class AssetsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @employee = employees(:one)
    @asset = assets(:one)
    @valid_attributes = {
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
    }
  end

  test "should get index" do
    get assets_url
    assert_response :success
    assert_not_nil assigns(:assets)
  end

  test "should get index with filters" do
    get assets_url, params: { asset_type: "laptop", department: "Engineering" }, as: :json
    assert_response :success

    json_response = JSON.parse(@response.body)
    assert_not_nil json_response["assets"]
    assert_not_nil json_response["total_count"]
    assert_not_nil json_response["filters"]
  end

  test "should get index with search" do
    get assets_url, params: { search: "MacBook" }, as: :json
    assert_response :success

    json_response = JSON.parse(@response.body)
    assert_not_nil json_response["assets"]
  end

  test "should get index with multiple filters" do
    get assets_url, params: {
      asset_type: "laptop",
      department: "Engineering",
      condition: "excellent",
      status: "available"
    }, as: :json
    assert_response :success
  end

  test "should get show" do
    get asset_url(@asset), as: :json
    assert_response :success

    json_response = JSON.parse(@response.body)
    assert_not_nil json_response["asset"]
    assert_not_nil json_response["maintenance_history"]
    assert_not_nil json_response["allocation_history"]
  end

  test "should create asset with valid parameters" do
    assert_difference("Asset.count") do
      post assets_url, params: { asset: @valid_attributes }, as: :json
    end

    assert_response :created
    json_response = JSON.parse(@response.body)
    assert_equal "Asset created successfully", json_response["message"]
    assert_equal @valid_attributes[:name], json_response["asset"]["name"]
  end

  test "should not create asset with invalid parameters" do
    invalid_attributes = @valid_attributes.merge(serial_number: nil)

    assert_no_difference("Asset.count") do
      post assets_url, params: { asset: invalid_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(@response.body)
    assert_equal "Failed to create asset", json_response["message"]
    assert_includes json_response["errors"], "Serial number can't be blank"
  end

  test "should not create asset with duplicate serial number" do
    # First create an asset
    post assets_url, params: { asset: @valid_attributes }, as: :json
    assert_response :created

    # Try to create another with same serial number
    assert_no_difference("Asset.count") do
      post assets_url, params: { asset: @valid_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(@response.body)
    assert_includes json_response["errors"], "Serial number has already been taken"
  end

  test "should not create asset with invalid asset type" do
    invalid_attributes = @valid_attributes.merge(asset_type: "invalid_type")

    assert_no_difference("Asset.count") do
      post assets_url, params: { asset: invalid_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(@response.body)
    assert_includes json_response["errors"], "Asset type is not included in the list"
  end

  test "should not create asset with invalid status" do
    invalid_attributes = @valid_attributes.merge(status: "invalid_status")

    assert_no_difference("Asset.count") do
      post assets_url, params: { asset: invalid_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(@response.body)
    assert_includes json_response["errors"], "Status is not included in the list"
  end

  test "should not create asset with invalid condition" do
    invalid_attributes = @valid_attributes.merge(condition: "invalid_condition")

    assert_no_difference("Asset.count") do
      post assets_url, params: { asset: invalid_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(@response.body)
    assert_includes json_response["errors"], "Condition is not included in the list"
  end

  test "should not create asset with negative purchase cost" do
    invalid_attributes = @valid_attributes.merge(purchase_cost: -100)

    assert_no_difference("Asset.count") do
      post assets_url, params: { asset: invalid_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(@response.body)
    assert_includes json_response["errors"], "Purchase cost must be greater than 0"
  end

  test "should not create asset with negative current value" do
    invalid_attributes = @valid_attributes.merge(current_value: -100)

    assert_no_difference("Asset.count") do
      post assets_url, params: { asset: invalid_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(@response.body)
    assert_includes json_response["errors"], "Current value must be greater than or equal to 0"
  end

  test "should update asset with valid parameters" do
    patch asset_url(@asset), params: { asset: { name: "Updated MacBook Pro" } }, as: :json
    assert_response :success

    json_response = JSON.parse(@response.body)
    assert_equal "Asset updated successfully", json_response["message"]
    assert_equal "Updated MacBook Pro", json_response["asset"]["name"]
  end

  test "should not update asset with invalid parameters" do
    patch asset_url(@asset), params: { asset: { serial_number: nil } }, as: :json
    assert_response :unprocessable_entity

    json_response = JSON.parse(@response.body)
    assert_equal "Failed to update asset", json_response["message"]
    assert_includes json_response["errors"], "Serial number can't be blank"
  end

  test "should not update asset with duplicate serial number" do
    # Create another asset first
    other_asset = Asset.create!(@valid_attributes.merge(serial_number: "OTHER123456789"))

    # Try to update first asset with second asset's serial number
    patch asset_url(@asset), params: { asset: { serial_number: other_asset.serial_number } }, as: :json
    assert_response :unprocessable_entity

    json_response = JSON.parse(@response.body)
    assert_includes json_response["errors"], "Serial number has already been taken"
  end

  test "should destroy asset" do
    assert_difference("Asset.count", -1) do
      delete asset_url(@asset), as: :json
    end

    assert_response :success
    json_response = JSON.parse(@response.body)
    assert_equal "Asset deleted successfully", json_response["message"]
  end

  test "should get stats" do
    get stats_assets_url, as: :json
    assert_response :success

    json_response = JSON.parse(@response.body)
    assert_not_nil json_response["overview"]
    assert_not_nil json_response["financial"]
    assert_not_nil json_response["distribution"]
    assert_not_nil json_response["maintenance"]
  end

  test "should get allocations" do
    get allocations_assets_url, as: :json
    assert_response :success

    json_response = JSON.parse(@response.body)
    assert_not_nil json_response["allocations"]
    assert_not_nil json_response["total_active_allocations"]
  end

  test "should get maintenance" do
    get maintenance_assets_url, as: :json
    assert_response :success

    json_response = JSON.parse(@response.body)
    assert_not_nil json_response["recent_maintenance"]
    assert_not_nil json_response["overdue_maintenance"]
    assert_not_nil json_response["due_maintenance_soon"]
    assert_not_nil json_response["maintenance_stats"]
  end

  test "should handle show with invalid asset" do
    get asset_url(999999), as: :json
    assert_response :not_found

    json_response = JSON.parse(@response.body)
    assert_equal "Asset not found", json_response["message"]
  end

  test "should handle update with invalid asset" do
    patch asset_url(999999), params: { asset: { name: "Updated" } }, as: :json
    assert_response :not_found
  end

  test "should handle destroy with invalid asset" do
    delete asset_url(999999), as: :json
    assert_response :not_found
  end

  test "should handle create with missing asset parameter" do
    post assets_url, params: {}, as: :json
    assert_response :bad_request
  end

  test "should handle update with missing asset parameter" do
    patch asset_url(@asset), params: {}, as: :json
    assert_response :bad_request
  end

  test "should create asset with all valid asset types" do
    valid_types = %w[laptop desktop mobile printer server network other]

    valid_types.each do |type|
      attributes = @valid_attributes.merge(
        serial_number: "#{type.upcase}123456789",
        asset_type: type
      )

      assert_difference("Asset.count") do
        post assets_url, params: { asset: attributes }, as: :json
      end

      assert_response :created
      json_response = JSON.parse(@response.body)
      assert_equal type, json_response["asset"]["asset_type"]
    end
  end

  test "should create asset with all valid statuses" do
    valid_statuses = %w[available assigned maintenance retired lost]

    valid_statuses.each do |status|
      attributes = @valid_attributes.merge(
        serial_number: "#{status.upcase}123456789",
        status: status
      )

      assert_difference("Asset.count") do
        post assets_url, params: { asset: attributes }, as: :json
      end

      assert_response :created
      json_response = JSON.parse(@response.body)
      assert_equal status, json_response["asset"]["status"]
    end
  end

  test "should create asset with all valid conditions" do
    valid_conditions = %w[excellent good fair poor]

    valid_conditions.each do |condition|
      attributes = @valid_attributes.merge(
        serial_number: "#{condition.upcase}123456789",
        condition: condition
      )

      assert_difference("Asset.count") do
        post assets_url, params: { asset: attributes }, as: :json
      end

      assert_response :created
      json_response = JSON.parse(@response.body)
      assert_equal condition, json_response["asset"]["condition"]
    end
  end

  test "should handle depreciation calculation" do
    attributes = @valid_attributes.merge(
      serial_number: "DEP123456789",
      purchase_date: 2.years.ago,
      purchase_cost: 1000.00,
      asset_type: "laptop" # 25% depreciation per year
    )

    post assets_url, params: { asset: attributes }, as: :json
    assert_response :created

    json_response = JSON.parse(@response.body)
    # After 2 years: 1000 * (1 - 0.25)^2 = 562.50
    assert_equal 562.50, json_response["asset"]["current_value"]
  end

  test "should handle status update when employee is assigned" do
    attributes = @valid_attributes.merge(
      serial_number: "EMP123456789",
      status: "available",
      employee_id: @employee.id
    )

    post assets_url, params: { asset: attributes }, as: :json
    assert_response :created

    json_response = JSON.parse(@response.body)
    assert_equal "assigned", json_response["asset"]["status"]
  end

  test "should handle search with special characters" do
    get assets_url, params: { search: "MacBook Pro 16-inch" }, as: :json
    assert_response :success
  end

  test "should handle search with partial matches" do
    get assets_url, params: { search: "Mac" }, as: :json
    assert_response :success
  end

  test "should handle case insensitive search" do
    get assets_url, params: { search: "macbook" }, as: :json
    assert_response :success
  end

  test "should handle empty search results" do
    get assets_url, params: { search: "nonexistent" }, as: :json
    assert_response :success

    json_response = JSON.parse(@response.body)
    assert_equal 0, json_response["total_count"]
  end

  test "should handle large number of assets in index" do
    # Create multiple assets
    10.times do |i|
      Asset.create!(@valid_attributes.merge(
        serial_number: "ASSET#{i}123456789",
        name: "Asset #{i}"
      ))
    end

    get assets_url, as: :json
    assert_response :success

    json_response = JSON.parse(@response.body)
    assert json_response["total_count"] >= 10
  end

  test "should handle concurrent asset creation" do
    threads = []
    results = []

    5.times do |i|
      threads << Thread.new do
        attributes = @valid_attributes.merge(
          serial_number: "CONC#{i}123456789"
        )
        response = post assets_url, params: { asset: attributes }, as: :json
        results << response
      end
    end

    threads.each(&:join)

    # All should succeed
    results.each do |result|
      assert_equal 201, result
    end
  end

  test "should handle malformed JSON" do
    post assets_url,
         params: "invalid json",
         headers: { "CONTENT_TYPE" => "application/json" }
    assert_response :bad_request
  end

  test "should handle empty JSON body" do
    post assets_url,
         params: "{}",
         headers: { "CONTENT_TYPE" => "application/json" }
    assert_response :bad_request
  end

  test "should handle decimal precision in costs" do
    attributes = @valid_attributes.merge(
      serial_number: "DEC123456789",
      purchase_cost: 1234.56,
      current_value: 987.65
    )

    post assets_url, params: { asset: attributes }, as: :json
    assert_response :created

    json_response = JSON.parse(@response.body)
    assert_equal 1234.56, json_response["asset"]["purchase_cost"]
    assert_equal 987.65, json_response["asset"]["current_value"]
  end

  test "should handle warranty and maintenance dates" do
    attributes = @valid_attributes.merge(
      serial_number: "DATE123456789",
      warranty_expiry: 1.year.from_now,
      last_maintenance: 6.months.ago,
      next_maintenance: 6.months.from_now
    )

    post assets_url, params: { asset: attributes }, as: :json
    assert_response :created

    json_response = JSON.parse(@response.body)
    assert_not_nil json_response["asset"]["warranty_expiry"]
    assert_not_nil json_response["asset"]["last_maintenance"]
    assert_not_nil json_response["asset"]["next_maintenance"]
  end
end
