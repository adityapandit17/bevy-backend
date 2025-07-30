require "test_helper"

class EmployeeBenefitsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @employee = employees(:one)
    @employee_benefit = employee_benefits(:one)
    @valid_attributes = {
      employee_id: @employee.id,
      name: "Health Insurance Premium",
      benefit_type: "health_insurance",
      provider: "Blue Cross Blue Shield",
      coverage: "Family Coverage",
      start_date: Date.current,
      end_date: Date.current + 1.year,
      status: "active",
      cost: 500.00
    }
  end

  test "should get index" do
    get employee_benefits_url, as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_kind_of Array, json_response
  end

  test "should show employee benefit" do
    get employee_benefit_url(@employee_benefit), as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal @employee_benefit.id, json_response["id"]
  end

  test "should create employee benefit" do
    assert_difference('EmployeeBenefit.count') do
      post employee_benefits_url, params: { employee_benefit: @valid_attributes }, as: :json
    end

    assert_response :created
    json_response = JSON.parse(response.body)
    assert_equal @valid_attributes[:name], json_response["name"]
    assert_equal @valid_attributes[:benefit_type], json_response["benefit_type"]
  end

  test "should not create employee benefit with invalid attributes" do
    invalid_attributes = @valid_attributes.merge(employee_id: 99999)
    
    assert_no_difference('EmployeeBenefit.count') do
      post employee_benefits_url, params: { employee_benefit: invalid_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Employee must exist"
  end

  test "should update employee benefit" do
    patch employee_benefit_url(@employee_benefit), params: { 
      employee_benefit: { status: "inactive", cost: 600.00 } 
    }, as: :json
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "inactive", json_response["status"]
    assert_equal 600.00, json_response["cost"].to_f
  end

  test "should not update employee benefit with invalid attributes" do
    patch employee_benefit_url(@employee_benefit), params: { 
      employee_benefit: { benefit_type: "invalid_type" } 
    }, as: :json
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Benefit type is not included in the list"
  end

  test "should destroy employee benefit" do
    assert_difference('EmployeeBenefit.count', -1) do
      delete employee_benefit_url(@employee_benefit), as: :json
    end

    assert_response :no_content
  end

  test "should return 404 for non-existent employee benefit" do
    get employee_benefit_url(99999), as: :json
    assert_response :not_found
  end

  test "should return 404 when updating non-existent employee benefit" do
    patch employee_benefit_url(99999), params: { 
      employee_benefit: { status: "inactive" } 
    }, as: :json
    assert_response :not_found
  end

  test "should return 404 when destroying non-existent employee benefit" do
    delete employee_benefit_url(99999), as: :json
    assert_response :not_found
  end

  test "should handle employee benefit with all required fields" do
    get employee_benefit_url(@employee_benefit), as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    required_fields = %w[id employee_id name benefit_type provider coverage start_date status cost created_at updated_at]
    
    required_fields.each do |field|
      assert_includes json_response.keys, field, "Missing field: #{field}"
    end
  end

  test "should handle employee benefit with missing optional fields" do
    minimal_attributes = {
      employee_id: @employee.id,
      name: "Minimal Benefit",
      benefit_type: "health_insurance",
      provider: "Provider",
      coverage: "Coverage",
      start_date: Date.current,
      status: "active",
      cost: 100.00
    }
    
    post employee_benefits_url, params: { employee_benefit: minimal_attributes }, as: :json
    assert_response :created
    
    json_response = JSON.parse(response.body)
    assert_equal minimal_attributes[:name], json_response["name"]
    assert_equal minimal_attributes[:benefit_type], json_response["benefit_type"]
    # Optional fields should be null
    assert_nil json_response["end_date"]
  end
end
