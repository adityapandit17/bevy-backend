require "test_helper"

class LeaveRequestsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @employee = employees(:one)
    @leave_request = leave_requests(:one)
    @valid_attributes = {
      employee_id: @employee.id,
      leave_type: "annual",
      start_date: Date.current + 1.week,
      end_date: Date.current + 2.weeks,
      reason: "Vacation",
      status: "pending"
    }
  end

  test "should get index" do
    get leave_requests_url, as: :json
    assert_response :success
  end

  test "should get index as json" do
    get leave_requests_url, as: :json
    assert_response :success
    assert_equal "application/json", @response.media_type
  end

  test "should get show" do
    get leave_request_url(@leave_request), as: :json
    assert_response :success
  end

  test "should create leave request with valid parameters" do
    assert_difference('LeaveRequest.count') do
      post leave_requests_url, params: { leave_request: @valid_attributes }, as: :json
    end

    assert_response :created
    assert_equal "application/json", @response.media_type
    
    json_response = JSON.parse(@response.body)
    assert_equal @valid_attributes[:leave_type], json_response["leave_type"]
    assert_equal @valid_attributes[:reason], json_response["reason"]
  end

  test "should not create leave request with invalid parameters" do
    invalid_attributes = @valid_attributes.merge(leave_type: nil)
    
    assert_no_difference('LeaveRequest.count') do
      post leave_requests_url, params: { leave_request: invalid_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    assert_equal "application/json", @response.media_type
    
    json_response = JSON.parse(@response.body)
    assert_includes json_response["errors"], "Leave type can't be blank"
  end

  test "should not create leave request with invalid leave type" do
    invalid_attributes = @valid_attributes.merge(leave_type: "invalid_type")
    
    assert_no_difference('LeaveRequest.count') do
      post leave_requests_url, params: { leave_request: invalid_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(@response.body)
    assert_includes json_response["errors"], "Leave type is not included in the list"
  end

  test "should not create leave request with invalid status" do
    invalid_attributes = @valid_attributes.merge(status: "invalid_status")
    
    assert_no_difference('LeaveRequest.count') do
      post leave_requests_url, params: { leave_request: invalid_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(@response.body)
    assert_includes json_response["errors"], "Status is not included in the list"
  end

  test "should not create leave request with end date before start date" do
    invalid_attributes = @valid_attributes.merge(
      start_date: Date.current + 2.weeks,
      end_date: Date.current + 1.week
    )
    
    assert_no_difference('LeaveRequest.count') do
      post leave_requests_url, params: { leave_request: invalid_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(@response.body)
    assert_includes json_response["errors"], "End date must be after start date"
  end

  test "should not create leave request without required fields" do
    required_fields = [:employee_id, :leave_type, :start_date, :end_date, :reason]
    
    required_fields.each do |field|
      invalid_attributes = @valid_attributes.dup
      invalid_attributes[field] = nil
      
      assert_no_difference('LeaveRequest.count') do
        post leave_requests_url, params: { leave_request: invalid_attributes }, as: :json
      end

      assert_response :unprocessable_entity
      json_response = JSON.parse(@response.body)
      if field == :employee_id
        assert_includes json_response["errors"], "Employee must exist"
      else
        assert_includes json_response["errors"], "#{field.to_s.humanize} can't be blank"
      end
    end
  end

  test "should create leave request with all valid leave types" do
    valid_types = %w[annual sick personal maternity paternity unpaid other]
    
    valid_types.each do |type|
      attributes = @valid_attributes.merge(
        leave_type: type,
        reason: "#{type.titleize} leave"
      )
      
      assert_difference('LeaveRequest.count') do
        post leave_requests_url, params: { leave_request: attributes }, as: :json
      end
      
      assert_response :created
      json_response = JSON.parse(@response.body)
      assert_equal type, json_response["leave_type"]
    end
  end

  test "should create leave request with all valid statuses" do
    valid_statuses = %w[pending approved rejected cancelled]
    
    valid_statuses.each do |status|
      attributes = @valid_attributes.merge(status: status)
      
      assert_difference('LeaveRequest.count') do
        post leave_requests_url, params: { leave_request: attributes }, as: :json
      end
      
      assert_response :created
      json_response = JSON.parse(@response.body)
      assert_equal status, json_response["status"]
    end
  end

  test "should update leave request with valid parameters" do
    patch leave_request_url(@leave_request), params: { leave_request: { status: "approved" } }, as: :json
    assert_response :success
    
    @leave_request.reload
    assert_equal "approved", @leave_request.status
  end

  test "should not update leave request with invalid parameters" do
    patch leave_request_url(@leave_request), params: { leave_request: { leave_type: nil } }, as: :json
    assert_response :unprocessable_entity
    
    json_response = JSON.parse(@response.body)
    assert_includes json_response["errors"], "Leave type can't be blank"
  end

  test "should not update leave request with end date before start date" do
    patch leave_request_url(@leave_request), params: { 
      leave_request: { 
        start_date: Date.current + 2.weeks,
        end_date: Date.current + 1.week
      } 
    }, as: :json
    assert_response :unprocessable_entity
    
    json_response = JSON.parse(@response.body)
    assert_includes json_response["errors"], "End date must be after start date"
  end

  test "should destroy leave request" do
    assert_difference('LeaveRequest.count', -1) do
      delete leave_request_url(@leave_request), as: :json
    end

    assert_response :success
  end

  test "should handle show with invalid leave request" do
    get leave_request_url(999999), as: :json
    assert_response :not_found
  end

  test "should handle update with invalid leave request" do
    patch leave_request_url(999999), params: { leave_request: { status: "approved" } }, as: :json
    assert_response :not_found
  end

  test "should handle destroy with invalid leave request" do
    delete leave_request_url(999999), as: :json
    assert_response :not_found
  end

  test "should handle create with missing leave request parameter" do
    post leave_requests_url, params: {}, as: :json
    assert_response :bad_request
  end

  test "should handle update with missing leave request parameter" do
    patch leave_request_url(@leave_request), params: {}, as: :json
    assert_response :bad_request
  end

  test "should create leave request with single day duration" do
    single_day_attributes = @valid_attributes.merge(
      start_date: Date.current + 1.week,
      end_date: Date.current + 1.week
    )
    
    assert_difference('LeaveRequest.count') do
      post leave_requests_url, params: { leave_request: single_day_attributes }, as: :json
    end

    assert_response :created
    json_response = JSON.parse(@response.body)
    assert_equal 1, json_response["days"]
  end

  test "should create leave request with multi-week duration" do
    multi_week_attributes = @valid_attributes.merge(
      start_date: Date.current + 1.week,
      end_date: Date.current + 4.weeks
    )
    
    assert_difference('LeaveRequest.count') do
      post leave_requests_url, params: { leave_request: multi_week_attributes }, as: :json
    end

    assert_response :created
    json_response = JSON.parse(@response.body)
    assert_equal 22, json_response["days"]
  end

  test "should handle leave request spanning month boundaries" do
    month_boundary_attributes = @valid_attributes.merge(
      start_date: Date.new(2023, 6, 30),
      end_date: Date.new(2023, 7, 2)
    )
    
    assert_difference('LeaveRequest.count') do
      post leave_requests_url, params: { leave_request: month_boundary_attributes }, as: :json
    end

    assert_response :created
    json_response = JSON.parse(@response.body)
    assert_equal 3, json_response["days"]
  end

  test "should handle leave request spanning year boundaries" do
    year_boundary_attributes = @valid_attributes.merge(
      start_date: Date.new(2023, 12, 30),
      end_date: Date.new(2024, 1, 2)
    )
    
    assert_difference('LeaveRequest.count') do
      post leave_requests_url, params: { leave_request: year_boundary_attributes }, as: :json
    end

    assert_response :created
    json_response = JSON.parse(@response.body)
    assert_equal 4, json_response["days"]
  end

  test "should handle large number of leave requests in index" do
    # Create multiple leave requests
    10.times do |i|
      LeaveRequest.create!(@valid_attributes.merge(
        reason: "Leave request #{i}",
        start_date: Date.current + (i + 1).weeks
      ))
    end
    
    get leave_requests_url, as: :json
    assert_response :success
    
    json_response = JSON.parse(@response.body)
    assert json_response.length >= 10
  end

  test "should handle concurrent leave request creation" do
    threads = []
    results = []
    
    5.times do |i|
      threads << Thread.new do
        attributes = @valid_attributes.merge(
          reason: "Concurrent leave #{i}",
          start_date: Date.current + (i + 1).weeks,
          end_date: Date.current + (i + 2).weeks
        )
        response = post leave_requests_url, params: { leave_request: attributes }, as: :json
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
    post leave_requests_url, 
         params: "invalid json", 
         headers: { 'CONTENT_TYPE' => 'application/json' }
    assert_response :bad_request
  end

  test "should handle empty JSON body" do
    post leave_requests_url, 
         params: "{}", 
         headers: { 'CONTENT_TYPE' => 'application/json' }
    assert_response :bad_request
  end

  test "should handle leave request with special characters in reason" do
    special_attributes = @valid_attributes.merge(
      reason: "Vacation & Personal Time - Family Event"
    )
    
    post leave_requests_url, params: { leave_request: special_attributes }, as: :json
    assert_response :created
    
    json_response = JSON.parse(@response.body)
    assert_equal "Vacation & Personal Time - Family Event", json_response["reason"]
  end

  test "should handle leave request with long reason" do
    long_reason = "A" * 500
    long_attributes = @valid_attributes.merge(reason: long_reason)
    
    post leave_requests_url, params: { leave_request: long_attributes }, as: :json
    assert_response :created
    
    json_response = JSON.parse(@response.body)
    assert_equal long_reason, json_response["reason"]
  end

  test "should handle leave request with past dates" do
    past_attributes = @valid_attributes.merge(
      start_date: Date.current - 2.weeks,
      end_date: Date.current - 1.week
    )
    
    post leave_requests_url, params: { leave_request: past_attributes }, as: :json
    assert_response :created
  end

  test "should handle leave request with current dates" do
    current_attributes = @valid_attributes.merge(
      start_date: Date.current - 1.day,
      end_date: Date.current + 1.day
    )
    
    post leave_requests_url, params: { leave_request: current_attributes }, as: :json
    assert_response :created
  end

  test "should handle leave request with future dates" do
    future_attributes = @valid_attributes.merge(
      start_date: Date.current + 6.months,
      end_date: Date.current + 6.months + 1.week
    )
    
    post leave_requests_url, params: { leave_request: future_attributes }, as: :json
    assert_response :created
  end

  test "should handle leave request with leap year dates" do
    leap_year_attributes = @valid_attributes.merge(
      start_date: Date.new(2024, 2, 28),
      end_date: Date.new(2024, 3, 1)
    )
    
    post leave_requests_url, params: { leave_request: leap_year_attributes }, as: :json
    assert_response :created
    
    json_response = JSON.parse(@response.body)
    assert_equal 3, json_response["days"]
  end

  test "should handle leave request status transitions" do
    # Create a pending leave request
    post leave_requests_url, params: { leave_request: @valid_attributes }, as: :json
    assert_response :created
    
    leave_request_id = JSON.parse(@response.body)["id"]
    
    # Update to approved
    patch leave_request_url(leave_request_id), params: { leave_request: { status: "approved" } }, as: :json
    assert_response :success
    
    # Update to rejected
    patch leave_request_url(leave_request_id), params: { leave_request: { status: "rejected" } }, as: :json
    assert_response :success
    
    # Update to cancelled
    patch leave_request_url(leave_request_id), params: { leave_request: { status: "cancelled" } }, as: :json
    assert_response :success
  end

  test "should handle leave request with same start and end date" do
    same_date_attributes = @valid_attributes.merge(
      start_date: Date.current + 1.week,
      end_date: Date.current + 1.week
    )
    
    post leave_requests_url, params: { leave_request: same_date_attributes }, as: :json
    assert_response :created
    
    json_response = JSON.parse(@response.body)
    assert_equal 1, json_response["days"]
  end

  test "should handle leave request with very long duration" do
    long_duration_attributes = @valid_attributes.merge(
      start_date: Date.current + 1.week,
      end_date: Date.current + 6.months
    )
    
    post leave_requests_url, params: { leave_request: long_duration_attributes }, as: :json
    assert_response :created
    
    json_response = JSON.parse(@response.body)
    assert json_response["days"] > 100
  end

  test "should handle leave request with minimum valid data" do
    minimal_attributes = {
      employee_id: @employee.id,
      leave_type: "annual",
      start_date: Date.current + 1.week,
      end_date: Date.current + 1.week,
      reason: "Minimal",
      status: "pending"
    }
    
    post leave_requests_url, params: { leave_request: minimal_attributes }, as: :json
    assert_response :created
  end

  test "should handle leave request update with same data" do
    # Update leave request with the same data should succeed
    patch leave_request_url(@leave_request), params: { 
      leave_request: { 
        leave_type: @leave_request.leave_type,
        reason: @leave_request.reason
      } 
    }, as: :json
    assert_response :success
  end
end
