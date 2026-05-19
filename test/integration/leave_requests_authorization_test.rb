require "test_helper"

class LeaveRequestsAuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    travel_to Time.zone.parse("2025-07-29 09:30:00")
    setup_manager_team!
    @other_employee = create_test_employee(
      email: "other.#{SecureRandom.hex(4)}@example.com",
      first_name: "Other",
      last_name: "Employee"
    )
    @pending_leave = LeaveRequest.create!(
      future_leave_attributes(@report_employee.id)
    )
  end

  teardown do
    travel_back
  end

  # --- Authentication ---

  test "index requires authentication" do
    without_authentication { get leave_requests_url }
    assert_json_unauthorized
  end

  test "create requires authentication" do
    without_authentication do
      post leave_requests_url, params: { leave_request: future_leave_attributes(@report_employee.id) }
    end
    assert_json_unauthorized
  end

  test "approve requires authentication" do
    without_authentication { patch approve_leave_request_url(@pending_leave) }
    assert_json_unauthorized
  end

  # --- Authorization: index scoping ---

  test "index forbidden without leave_requests.index" do
    sign_in_as(create_api_user(permissions: []))
    get leave_requests_url
    assert_json_forbidden
  end

  test "employee index returns only own leave requests" do
    other_leave = LeaveRequest.create!(future_leave_attributes(@other_employee.id))

    sign_in_as(@employee_user)
    get leave_requests_url

    assert_response :success
    ids = json_response.map { |r| r["id"] }
    assert_includes ids, @pending_leave.id
    assert_not_includes ids, other_leave.id
  end

  test "employee cannot see other employees leave via employee_id filter" do
    other_leave = LeaveRequest.create!(future_leave_attributes(@other_employee.id))

    sign_in_as(@employee_user)
    get leave_requests_url, params: { employee_id: @other_employee.id }

    assert_response :success
    ids = json_response.map { |r| r["id"] }
    assert_not_includes ids, other_leave.id
  end

  test "hr index returns all leave requests" do
    other_leave = LeaveRequest.create!(future_leave_attributes(@other_employee.id))

    sign_in_as(@hr_user)
    get leave_requests_url

    assert_response :success
    ids = json_response.map { |r| r["id"] }
    assert_includes ids, @pending_leave.id
    assert_includes ids, other_leave.id
  end

  test "manager_pending returns only direct reports pending leave" do
    report_leave = LeaveRequest.create!(future_leave_attributes(@report_employee.id))
    _other_leave = LeaveRequest.create!(future_leave_attributes(@other_employee.id))

    sign_in_as(@manager_user)
    get leave_requests_url, params: { manager_pending: "true", status: "pending" }

    assert_response :success
    ids = json_response.map { |r| r["id"] }
    assert_includes ids, report_leave.id
    assert_not_includes ids, _other_leave.id
  end

  test "manager_pending returns empty when user has no employee record" do
    user_without_employee = create_api_user(
      permissions: %w[leave_requests.index leave_requests.approve],
      email: "no.employee.#{SecureRandom.hex(4)}@test.com"
    )

    sign_in_as(user_without_employee)
    get leave_requests_url, params: { manager_pending: "true" }

    assert_response :success
    assert_equal [], json_response
  end

  # --- Authorization: create ---

  test "employee can create leave for self" do
    sign_in_as(@employee_user)

    assert_difference("LeaveRequest.count") do
      post leave_requests_url, params: {
        leave_request: future_leave_attributes(
          @report_employee.id,
          start_date: Date.current + 10.weeks,
          end_date: Date.current + 11.weeks,
          reason: "Personal trip"
        )
      }
    end
    assert_response :created
    assert_equal @report_employee.id, json_response["employee_id"]
  end

  test "employee cannot create leave for another employee" do
    sign_in_as(@employee_user)

    assert_no_difference("LeaveRequest.count") do
      post leave_requests_url, params: {
        leave_request: future_leave_attributes(@other_employee.id)
      }
    end
    assert_json_forbidden
  end

  test "create forbidden without leave_requests.create" do
    sign_in_as(create_api_user(permissions: %w[leave_requests.index], employee: @report_employee))

    assert_no_difference("LeaveRequest.count") do
      post leave_requests_url, params: { leave_request: future_leave_attributes(@report_employee.id) }
    end
    assert_json_forbidden
  end

  test "hr can create leave for any employee" do
    sign_in_as(@hr_user)

    assert_difference("LeaveRequest.count") do
      post leave_requests_url, params: { leave_request: future_leave_attributes(@other_employee.id) }
    end
    assert_response :created
  end

  # --- Authorization: approve / reject ---

  test "manager can manager-approve direct report pending leave" do
    sign_in_as(@manager_user)

    patch approve_leave_request_url(@pending_leave)
    assert_response :success

    @pending_leave.reload
    assert_equal "manager_approved", @pending_leave.status
  end

  test "manager cannot approve non-report leave" do
    other_leave = LeaveRequest.create!(future_leave_attributes(@other_employee.id))

    sign_in_as(@manager_user)
    patch approve_leave_request_url(other_leave)

    assert_json_forbidden
  end

  test "hr can fully approve pending leave" do
    sign_in_as(@hr_user)

    patch approve_leave_request_url(@pending_leave)
    assert_response :success

    @pending_leave.reload
    assert_equal "approved", @pending_leave.status
  end

  test "employee cannot approve own leave" do
    sign_in_as(@employee_user)

    patch approve_leave_request_url(@pending_leave)
    assert_json_forbidden
  end

  test "manager can reject direct report leave" do
    sign_in_as(@manager_user)

    patch reject_leave_request_url(@pending_leave), params: { reason: "Team coverage needed" }
    assert_response :success

    @pending_leave.reload
    assert_equal "rejected", @pending_leave.status
  end

  # --- Authorization: cancel ---

  test "employee can cancel own pending future leave" do
    sign_in_as(@employee_user)

    patch cancel_leave_request_url(@pending_leave)
    assert_response :success

    @pending_leave.reload
    assert_equal "cancelled", @pending_leave.status
  end

  test "employee cannot cancel another employees leave" do
    other_leave = LeaveRequest.create!(future_leave_attributes(@other_employee.id))

    sign_in_as(@employee_user)
    patch cancel_leave_request_url(other_leave)

    assert_json_forbidden
  end

  test "hr can cancel any cancellable leave" do
    sign_in_as(@hr_user)

    patch cancel_leave_request_url(@pending_leave)
    assert_response :success
    assert_equal "cancelled", @pending_leave.reload.status
  end

  # --- Collection endpoints ---

  test "balance requires authentication" do
    without_authentication do
      get balance_leave_requests_url, params: { employee_id: @report_employee.id }
    end
    assert_json_unauthorized
  end

  test "employee can view own leave balance" do
    sign_in_as(@employee_user)

    get balance_leave_requests_url, params: { employee_id: @report_employee.id }
    assert_response :success
  end

  test "employee cannot view another employees leave balance" do
    sign_in_as(@employee_user)

    get balance_leave_requests_url, params: { employee_id: @other_employee.id }
    assert_json_forbidden
  end
end
