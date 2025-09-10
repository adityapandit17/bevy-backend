require "test_helper"

class TimesheetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @employee = employees(:one)
    @timesheet = timesheets(:one)
    @valid_attributes = {
      employee_id: @employee.id,
      date: Date.current,
      hours: 8.0,
      project: "HRMS Development",
      task: "Implementing test suites for controllers",
      status: "pending"
    }
  end

  test "should get index" do
    get timesheets_url, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_kind_of Array, json_response
  end

  test "should show timesheet" do
    get timesheet_url(@timesheet), as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal @timesheet.id, json_response["id"]
  end

  test "should create timesheet" do
    assert_difference("Timesheet.count") do
      post timesheets_url, params: { timesheet: @valid_attributes }, as: :json
    end

    assert_response :created
    json_response = JSON.parse(response.body)
    assert_equal @valid_attributes[:employee_id], json_response["employee_id"]
    assert_equal @valid_attributes[:hours], json_response["hours"].to_f
  end

  test "should not create timesheet with invalid attributes" do
    invalid_attributes = @valid_attributes.merge(employee_id: 99999)

    assert_no_difference("Timesheet.count") do
      post timesheets_url, params: { timesheet: invalid_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Employee must exist"
  end

  test "should update timesheet" do
    patch timesheet_url(@timesheet), params: {
      timesheet: { hours: 9.0, status: "approved" }
    }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 9.0, json_response["hours"].to_f
    assert_equal "approved", json_response["status"]
  end

  test "should not update timesheet with invalid attributes" do
    patch timesheet_url(@timesheet), params: {
      timesheet: { hours: 25.0 }
    }, as: :json

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Hours must be less than or equal to 24"
  end

  test "should destroy timesheet" do
    assert_difference("Timesheet.count", -1) do
      delete timesheet_url(@timesheet), as: :json
    end

    assert_response :no_content
  end

  test "should return 404 for non-existent timesheet" do
    get timesheet_url(99999), as: :json
    assert_response :not_found
  end

  test "should return 404 when updating non-existent timesheet" do
    patch timesheet_url(99999), params: {
      timesheet: { hours_worked: 9.0 }
    }, as: :json
    assert_response :not_found
  end

  test "should return 404 when destroying non-existent timesheet" do
    delete timesheet_url(99999), as: :json
    assert_response :not_found
  end

  test "should handle timesheet with all required fields" do
    get timesheet_url(@timesheet), as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    required_fields = %w[id employee_id date hours status created_at updated_at]

    required_fields.each do |field|
      assert_includes json_response.keys, field, "Missing field: #{field}"
    end
  end

  test "should handle timesheet with missing optional fields" do
    minimal_attributes = {
      employee_id: @employee.id,
      date: Date.current,
      hours: 8.0,
      project: "Default Project",
      task: "Default Task",
      status: "pending"
    }

    post timesheets_url, params: { timesheet: minimal_attributes }, as: :json
    assert_response :created

    json_response = JSON.parse(response.body)
    assert_equal minimal_attributes[:employee_id], json_response["employee_id"]
    assert_equal minimal_attributes[:hours], json_response["hours"].to_f
    # Project and task are required fields
    assert_equal minimal_attributes[:project], json_response["project"]
    assert_equal minimal_attributes[:task], json_response["task"]
  end
end
