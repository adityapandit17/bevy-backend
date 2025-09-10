require "test_helper"

class PerformanceGoalsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @employee = employees(:one)
    @performance_goal = performance_goals(:one)
    @valid_attributes = {
      employee_id: @employee.id,
      title: "Improve Leadership Skills",
      description: "Develop leadership capabilities through training and mentoring",
      target: "Complete leadership training program",
      due_date: Date.current + 3.months,
      progress: 25,
      status: "in_progress"
    }
  end

  test "should get index" do
    get performance_goals_url, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_kind_of Array, json_response
  end

  test "should show performance goal" do
    get performance_goal_url(@performance_goal), as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal @performance_goal.id, json_response["id"]
  end

  test "should create performance goal" do
    assert_difference("PerformanceGoal.count") do
      post performance_goals_url, params: { performance_goal: @valid_attributes }, as: :json
    end

    assert_response :created
    json_response = JSON.parse(response.body)
    assert_equal @valid_attributes[:title], json_response["title"]
    assert_equal @valid_attributes[:target], json_response["target"]
  end

  test "should not create performance goal with invalid attributes" do
    invalid_attributes = @valid_attributes.merge(employee_id: 99999)

    assert_no_difference("PerformanceGoal.count") do
      post performance_goals_url, params: { performance_goal: invalid_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Employee must exist"
  end

  test "should update performance goal" do
    patch performance_goal_url(@performance_goal), params: {
      performance_goal: { progress: 50, target: "Updated target", status: "in_progress" }
    }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 50, json_response["progress"]
    assert_equal "Updated target", json_response["target"]
  end

  test "should not update performance goal with invalid attributes" do
    patch performance_goal_url(@performance_goal), params: {
      performance_goal: { progress: 150 }
    }, as: :json

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Progress must be less than or equal to 100"
  end

  test "should destroy performance goal" do
    assert_difference("PerformanceGoal.count", -1) do
      delete performance_goal_url(@performance_goal), as: :json
    end

    assert_response :no_content
  end

  test "should return 404 for non-existent performance goal" do
    get performance_goal_url(99999), as: :json
    assert_response :not_found
  end

  test "should return 404 when updating non-existent performance goal" do
    patch performance_goal_url(99999), params: {
      performance_goal: { progress: 50 }
    }, as: :json
    assert_response :not_found
  end

  test "should return 404 when destroying non-existent performance goal" do
    delete performance_goal_url(99999), as: :json
    assert_response :not_found
  end

  test "should handle performance goal with all required fields" do
    get performance_goal_url(@performance_goal), as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    required_fields = %w[id employee_id title description target progress status due_date created_at updated_at]

    required_fields.each do |field|
      assert_includes json_response.keys, field, "Missing field: #{field}"
    end
  end

  test "should handle performance goal with missing optional fields" do
    minimal_attributes = {
      employee_id: @employee.id,
      title: "Minimal Goal",
      description: "Basic goal description",
      target: "Basic target",
      due_date: Date.current + 1.month,
      progress: 0,
      status: "not_started"
    }

    post performance_goals_url, params: { performance_goal: minimal_attributes }, as: :json
    assert_response :created

    json_response = JSON.parse(response.body)
    assert_equal minimal_attributes[:title], json_response["title"]
    assert_equal minimal_attributes[:target], json_response["target"]
    # Description is required, so it should be present
    assert_equal minimal_attributes[:description], json_response["description"]
  end
end
