require "test_helper"

class AssetAllocationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @employee = employees(:one)
    @asset = assets(:one)
    @asset_allocation = asset_allocations(:one)
    @valid_attributes = {
      asset_id: @asset.id,
      employee_id: @employee.id,
      assigned_date: Date.current,
      return_date: Date.current + 1.year,
      notes: "Laptop allocated for development work",
      status: "active"
    }
  end

  test "should get index" do
    get asset_allocations_url, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_kind_of Array, json_response
  end

  test "should show asset allocation" do
    get asset_allocation_url(@asset_allocation), as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal @asset_allocation.id, json_response["id"]
  end

  test "should create asset allocation" do
    assert_difference("AssetAllocation.count") do
      post asset_allocations_url, params: { asset_allocation: @valid_attributes }, as: :json
    end

    assert_response :created
    json_response = JSON.parse(response.body)
    assert_equal @valid_attributes[:asset_id], json_response["asset_id"]
    assert_equal @valid_attributes[:employee_id], json_response["employee_id"]
  end

  test "should not create asset allocation with invalid attributes" do
    invalid_attributes = @valid_attributes.merge(asset_id: 99999)

    assert_no_difference("AssetAllocation.count") do
      post asset_allocations_url, params: { asset_allocation: invalid_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Asset must exist"
  end

  test "should update asset allocation" do
    patch asset_allocation_url(@asset_allocation), params: {
      asset_allocation: { status: "returned", return_date: Date.current }
    }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "returned", json_response["status"]
    assert_equal Date.current.to_s, json_response["return_date"]
  end

  test "should not update asset allocation with invalid attributes" do
    patch asset_allocation_url(@asset_allocation), params: {
      asset_allocation: { employee_id: 99999 }
    }, as: :json

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Employee must exist"
  end

  test "should destroy asset allocation" do
    assert_difference("AssetAllocation.count", -1) do
      delete asset_allocation_url(@asset_allocation), as: :json
    end

    assert_response :no_content
  end

  test "should return 404 for non-existent asset allocation" do
    get asset_allocation_url(99999), as: :json
    assert_response :not_found
  end

  test "should return 404 when updating non-existent asset allocation" do
    patch asset_allocation_url(99999), params: {
      asset_allocation: { status: "returned" }
    }, as: :json
    assert_response :not_found
  end

  test "should return 404 when destroying non-existent asset allocation" do
    delete asset_allocation_url(99999), as: :json
    assert_response :not_found
  end

  test "should handle asset allocation with all required fields" do
    get asset_allocation_url(@asset_allocation), as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    required_fields = %w[id asset_id employee_id assigned_date status created_at updated_at]

    required_fields.each do |field|
      assert_includes json_response.keys, field, "Missing field: #{field}"
    end
  end

  test "should handle asset allocation with missing optional fields" do
    minimal_attributes = {
      asset_id: @asset.id,
      employee_id: @employee.id,
      assigned_date: Date.current,
      status: "active"
    }

    post asset_allocations_url, params: { asset_allocation: minimal_attributes }, as: :json
    assert_response :created

    json_response = JSON.parse(response.body)
    assert_equal minimal_attributes[:asset_id], json_response["asset_id"]
    assert_equal minimal_attributes[:employee_id], json_response["employee_id"]
    # Optional fields should be null
    assert_nil json_response["return_date"]
    assert_nil json_response["notes"]
  end
end
