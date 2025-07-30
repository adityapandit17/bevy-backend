require "test_helper"

class EmployeeTrainingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @employee = employees(:one)
    @employee_training = employee_trainings(:one)
    @valid_attributes = {
      employee_id: @employee.id,
      name: "Advanced Ruby on Rails",
      training_type: "technical",
      provider: "Rails Academy",
      start_date: Date.current + 1.week,
      end_date: Date.current + 3.weeks,
      status: "not_started",
      progress: 0,
      cost: 1500.00,
      skills: "Ruby, Rails, JavaScript, PostgreSQL",
      certificate: "certificate.pdf"
    }
  end

  test "should get index" do
    get employee_trainings_url, as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_kind_of Array, json_response
  end

  test "should show employee training" do
    get employee_training_url(@employee_training), as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal @employee_training.id, json_response["id"]
  end

  test "should create employee training" do
    assert_difference('EmployeeTraining.count') do
      post employee_trainings_url, params: { employee_training: @valid_attributes }, as: :json
    end

    assert_response :created
    json_response = JSON.parse(response.body)
    assert_equal @valid_attributes[:name], json_response["name"]
    assert_equal @valid_attributes[:training_type], json_response["training_type"]
  end

  test "should not create employee training with invalid attributes" do
    invalid_attributes = @valid_attributes.merge(employee_id: 99999)
    
    assert_no_difference('EmployeeTraining.count') do
      post employee_trainings_url, params: { employee_training: invalid_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Employee must exist"
  end

  test "should update employee training" do
    patch employee_training_url(@employee_training), params: { 
      employee_training: { status: "in_progress", progress: 50 } 
    }, as: :json
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "in_progress", json_response["status"]
    assert_equal 50, json_response["progress"]
  end

  test "should not update employee training with invalid attributes" do
    patch employee_training_url(@employee_training), params: { 
      employee_training: { training_type: "invalid_type" } 
    }, as: :json
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Training type is not included in the list"
  end

  test "should destroy employee training" do
    assert_difference('EmployeeTraining.count', -1) do
      delete employee_training_url(@employee_training), as: :json
    end

    assert_response :no_content
  end

  test "should return 404 for non-existent employee training" do
    get employee_training_url(99999), as: :json
    assert_response :not_found
  end

  test "should return 404 when updating non-existent employee training" do
    patch employee_training_url(99999), params: { 
      employee_training: { status: "in_progress" } 
    }, as: :json
    assert_response :not_found
  end

  test "should return 404 when destroying non-existent employee training" do
    delete employee_training_url(99999), as: :json
    assert_response :not_found
  end

  test "should handle employee training with all required fields" do
    get employee_training_url(@employee_training), as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    required_fields = %w[id employee_id name training_type provider start_date status progress cost created_at updated_at]
    
    required_fields.each do |field|
      assert_includes json_response.keys, field, "Missing field: #{field}"
    end
  end

  test "should handle employee training with missing optional fields" do
    minimal_attributes = {
      employee_id: @employee.id,
      name: "Minimal Training",
      training_type: "technical",
      provider: "Provider",
      start_date: Date.current + 1.week,
      status: "not_started",
      progress: 0,
      cost: 100.00
    }
    
    post employee_trainings_url, params: { employee_training: minimal_attributes }, as: :json
    assert_response :created
    
    json_response = JSON.parse(response.body)
    assert_equal minimal_attributes[:name], json_response["name"]
    assert_equal minimal_attributes[:training_type], json_response["training_type"]
    # Optional fields should be null
    assert_nil json_response["end_date"]
    assert_nil json_response["skills"]
    assert_nil json_response["certificate"]
  end
end
