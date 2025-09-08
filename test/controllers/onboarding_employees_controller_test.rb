require "test_helper"

class OnboardingEmployeesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @employee = employees(:one)
    @onboarding_employee = onboarding_employees(:one)
    @valid_attributes = {
      employee_id: @employee.id,
      start_date: Date.current + 1.week,
      status: "pending",
      progress: 0,
      notes: "New employee onboarding process"
    }
  end

  test "should get index" do
    get onboarding_employees_url, as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_kind_of Array, json_response
  end

  test "should show onboarding employee" do
    get onboarding_employee_url(@onboarding_employee), as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal @onboarding_employee.id, json_response["id"]
  end

  test "should create onboarding employee" do
    assert_difference('OnboardingEmployee.count') do
      post onboarding_employees_url, params: { onboarding_employee: @valid_attributes }, as: :json
    end

    assert_response :created
    json_response = JSON.parse(response.body)
    assert_equal @valid_attributes[:employee_id], json_response["employee_id"]
    assert_equal @valid_attributes[:status], json_response["status"]
  end

  test "should not create onboarding employee with invalid attributes" do
    invalid_attributes = @valid_attributes.merge(employee_id: 99999)
    
    assert_no_difference('OnboardingEmployee.count') do
      post onboarding_employees_url, params: { onboarding_employee: invalid_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Employee must exist"
  end

  test "should update onboarding employee" do
    # Create some tasks for the onboarding employee so the callback works correctly
    task = @onboarding_employee.onboarding_tasks.create!(
      title: "Test Task",
      description: "Test Description",
      category: "HR",
      priority: "high",
      due_date: Date.current + 1.week,
      assigned_to: "Test Person"
    )
    # Mark the task as completed so progress calculation works
    task.update!(is_completed: true)
    
    patch onboarding_employee_url(@onboarding_employee), params: { 
      onboarding_employee: { status: "in_progress" } 
    }, as: :json
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "in_progress", json_response["status"]
    # Progress should be calculated as 50% (1 completed out of 2 total - fixture task + our task)
    assert_equal 50, json_response["progress"]
  end

  test "should not update onboarding employee with invalid attributes" do
    patch onboarding_employee_url(@onboarding_employee), params: { 
      onboarding_employee: { status: "invalid_status" } 
    }, as: :json
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Status is not included in the list"
  end

  test "should destroy onboarding employee" do
    assert_difference('OnboardingEmployee.count', -1) do
      delete onboarding_employee_url(@onboarding_employee), as: :json
    end

    assert_response :no_content
  end

  test "should return 404 for non-existent onboarding employee" do
    get onboarding_employee_url(99999), as: :json
    assert_response :not_found
  end

  test "should return 404 when updating non-existent onboarding employee" do
    patch onboarding_employee_url(99999), params: { 
      onboarding_employee: { status: "in_progress" } 
    }, as: :json
    assert_response :not_found
  end

  test "should return 404 when destroying non-existent onboarding employee" do
    delete onboarding_employee_url(99999), as: :json
    assert_response :not_found
  end

  test "should handle onboarding employee with all required fields" do
    get onboarding_employee_url(@onboarding_employee), as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    required_fields = %w[id employee_id start_date status created_at updated_at]
    
    required_fields.each do |field|
      assert_includes json_response.keys, field, "Missing field: #{field}"
    end
  end

  test "should handle onboarding employee with missing optional fields" do
    minimal_attributes = {
      employee_id: @employee.id,
      start_date: Date.current + 1.week,
      status: "pending",
      progress: 0
    }
    
    post onboarding_employees_url, params: { onboarding_employee: minimal_attributes }, as: :json
    assert_response :created
    
    json_response = JSON.parse(response.body)
    assert_equal minimal_attributes[:employee_id], json_response["employee_id"]
    assert_equal minimal_attributes[:status], json_response["status"]
    # Optional fields should be null
    assert_nil json_response["orientation_date"]
    assert_nil json_response["mentor_id"]
    assert_nil json_response["notes"]
  end
end
