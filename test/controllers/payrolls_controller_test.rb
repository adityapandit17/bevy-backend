require "test_helper"

class PayrollsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @employee = employees(:one)
    @salary_structure = salary_structures(:one)
    @payroll = payrolls(:one)
    @valid_attributes = {
      employee_id: @employee.id,
      month: "January",
      gross_salary: 55000.00,
      net_salary: 53000.00,
      status: "pending"
    }
  end

  test "should get index" do
    get payrolls_url, as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_kind_of Array, json_response
  end

  test "should show payroll" do
    get payroll_url(@payroll), as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal @payroll.id, json_response["id"]
  end

  test "should create payroll" do
    assert_difference('Payroll.count') do
      post payrolls_url, params: { payroll: @valid_attributes }, as: :json
    end

    assert_response :created
    json_response = JSON.parse(response.body)
    assert_equal @valid_attributes[:employee_id], json_response["employee_id"]
    assert_equal @valid_attributes[:month], json_response["month"]
  end

  test "should not create payroll with invalid attributes" do
    invalid_attributes = @valid_attributes.merge(employee_id: 99999)
    
    assert_no_difference('Payroll.count') do
      post payrolls_url, params: { payroll: invalid_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Employee must exist"
  end

  test "should update payroll" do
    patch payroll_url(@payroll), params: { 
      payroll: { status: "approved", gross_salary: 60000.00 } 
    }, as: :json
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "approved", json_response["status"]
    assert_equal 60000.00, json_response["gross_salary"].to_f
  end

  test "should not update payroll with invalid attributes" do
    patch payroll_url(@payroll), params: { 
      payroll: { employee_id: 99999 } 
    }, as: :json
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Employee must exist"
  end

  test "should destroy payroll" do
    assert_difference('Payroll.count', -1) do
      delete payroll_url(@payroll), as: :json
    end

    assert_response :no_content
  end

  test "should return 404 for non-existent payroll" do
    get payroll_url(99999), as: :json
    assert_response :not_found
  end

  test "should return 404 when updating non-existent payroll" do
    patch payroll_url(99999), params: { 
      payroll: { status: "approved" } 
    }, as: :json
    assert_response :not_found
  end

  test "should return 404 when destroying non-existent payroll" do
    delete payroll_url(99999), as: :json
    assert_response :not_found
  end

  test "should handle payroll with all required fields" do
    get payroll_url(@payroll), as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    required_fields = %w[id employee_id month gross_salary net_salary status created_at updated_at]
    
    required_fields.each do |field|
      assert_includes json_response.keys, field, "Missing field: #{field}"
    end
  end

  test "should handle payroll with missing optional fields" do
    minimal_attributes = {
      employee_id: @employee.id,
      month: "January",
      gross_salary: 50000.00,
      status: "pending"
    }
    
    post payrolls_url, params: { payroll: minimal_attributes }, as: :json
    assert_response :created
    
    json_response = JSON.parse(response.body)
    assert_equal minimal_attributes[:employee_id], json_response["employee_id"]
    assert_equal minimal_attributes[:gross_salary], json_response["gross_salary"].to_f
    # Optional fields should be null
    assert_nil json_response["net_salary"]
  end
end
