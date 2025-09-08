require "test_helper"

class OnboardingTasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @onboarding_employee = onboarding_employees(:one)
    @onboarding_task = onboarding_tasks(:one)
    @valid_attributes = {
      onboarding_employee_id: @onboarding_employee.id,
      title: "Complete IT Setup",
      description: "Set up computer, email, and access credentials",
      category: "IT",
      due_date: Date.current + 1.week,
      priority: "high",
      assigned_to: "IT Department"
    }
  end

  test "should get index" do
    get onboarding_tasks_url, as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_kind_of Array, json_response
  end

  test "should show onboarding task" do
    get onboarding_task_url(@onboarding_task), as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal @onboarding_task.id, json_response["id"]
  end

  test "should create onboarding task" do
    assert_difference('OnboardingTask.count') do
      post onboarding_tasks_url, params: { onboarding_task: @valid_attributes }, as: :json
    end

    assert_response :created
    json_response = JSON.parse(response.body)
    assert_equal @valid_attributes[:title], json_response["title"]
    assert_equal @valid_attributes[:task_type], json_response["task_type"]
  end

  test "should not create onboarding task with invalid attributes" do
    invalid_attributes = @valid_attributes.merge(onboarding_employee_id: 99999)
    
    assert_no_difference('OnboardingTask.count') do
      post onboarding_tasks_url, params: { onboarding_task: invalid_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Onboarding employee must exist"
  end

  test "should update onboarding task" do
    patch onboarding_task_url(@onboarding_task), params: { 
      onboarding_task: { is_completed: true, priority: "medium" } 
    }, as: :json
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal true, json_response["is_completed"]
    assert_equal "medium", json_response["priority"]
  end

  test "should not update onboarding task with invalid attributes" do
    patch onboarding_task_url(@onboarding_task), params: { 
      onboarding_task: { category: "invalid_category" } 
    }, as: :json
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Category is not included in the list"
  end

  test "should destroy onboarding task" do
    assert_difference('OnboardingTask.count', -1) do
      delete onboarding_task_url(@onboarding_task), as: :json
    end

    assert_response :no_content
  end

  test "should return 404 for non-existent onboarding task" do
    get onboarding_task_url(99999), as: :json
    assert_response :not_found
  end

  test "should return 404 when updating non-existent onboarding task" do
    patch onboarding_task_url(99999), params: { 
      onboarding_task: { status: "completed" } 
    }, as: :json
    assert_response :not_found
  end

  test "should return 404 when destroying non-existent onboarding task" do
    delete onboarding_task_url(99999), as: :json
    assert_response :not_found
  end

  test "should handle onboarding task with all required fields" do
    get onboarding_task_url(@onboarding_task), as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    required_fields = %w[id onboarding_employee_id title category due_date created_at updated_at]
    
    required_fields.each do |field|
      assert_includes json_response.keys, field, "Missing field: #{field}"
    end
  end

  test "should handle onboarding task with missing optional fields" do
    minimal_attributes = {
      onboarding_employee_id: @onboarding_employee.id,
      title: "Minimal Task",
      category: "IT",
      due_date: Date.current + 1.week,
      priority: "medium",
      assigned_to: "IT Team"
    }
    
    post onboarding_tasks_url, params: { onboarding_task: minimal_attributes }, as: :json
    assert_response :created
    
    json_response = JSON.parse(response.body)
    assert_equal minimal_attributes[:title], json_response["title"]
    assert_equal minimal_attributes[:category], json_response["category"]
    # Optional fields should be null
    assert_nil json_response["description"]
  end
end
