require "test_helper"

# Verifies JWT authentication and permission checks on controllers that enforce authorize!.
class ApiAuthenticationMatrixTest < ActionDispatch::IntegrationTest
  # Controllers with explicit authorize!(resource, "index") on #index
  PERMISSION_GATED_INDEX = [
    { path: "/employees", permission: "employees.index" },
    { path: "/attendance_records", permission: "attendance_records.index" },
    { path: "/leave_requests", permission: "leave_requests.index" },
    { path: "/job_openings", permission: "job_openings.index" },
    { path: "/candidates", permission: "candidates.index" },
    { path: "/interviews", permission: "interviews.index" }
  ].freeze

  # Authenticated but no per-action permission gate on index (document current behavior)
  AUTH_ONLY_INDEX = [
    "/departments",
    "/events",
    "/timesheets",
    "/helpdesk_tickets",
    "/onboarding_employees",
    "/performance_reviews",
    "/salary_structures",
    "/payrolls",
    "/api/assets"
  ].freeze

  PERMISSION_GATED_INDEX.each do |endpoint|
    test "GET #{endpoint[:path]} returns 401 without token" do
      without_authentication { get endpoint[:path] }
      assert_json_unauthorized
    end

    test "GET #{endpoint[:path]} returns 403 without #{endpoint[:permission]}" do
      sign_in_as(create_api_user(permissions: []))
      get endpoint[:path]
      assert_json_forbidden
    end

    test "GET #{endpoint[:path]} succeeds with #{endpoint[:permission]}" do
      sign_in_as(create_api_user(permissions: [endpoint[:permission]]))
      get endpoint[:path]
      assert_response :success
    end
  end

  AUTH_ONLY_INDEX.each do |path|
    test "GET #{path} returns 401 without token" do
      without_authentication { get path }
      assert_json_unauthorized
    end

    test "GET #{path} succeeds for authenticated user without resource permission" do
      sign_in_as(create_api_user(permissions: []))
      get path
      assert_response :success
    end
  end

  test "GET /api/v1/users/directory returns 401 without token" do
    without_authentication { get "/api/v1/users/directory" }
    assert_response :unauthorized
  end

  test "GET /api/v1/users/directory succeeds for any authenticated user" do
    sign_in_as(create_api_user(permissions: []))
    get "/api/v1/users/directory"
    assert_response :success
    assert json_response["success"]
    assert json_response["users"].is_a?(Array)
  end

  test "GET /users index requires users.index permission" do
    without_authentication { get users_url }
    assert_json_unauthorized

    sign_in_as(create_api_user(permissions: []))
    get users_url
    assert_json_forbidden

    sign_in_as(create_api_user(permissions: %w[users.index]))
    get users_url
    assert_response :success
  end

  test "inactive user token is rejected" do
    user = create_api_user(permissions: %w[employees.index])
    user.update!(status: "inactive")

    sign_in_as(user)
    get employees_url
    assert_json_unauthorized
  end

  test "user with multiple permissions can access each granted resource" do
    user = create_api_user(permissions: %w[employees.index attendance_records.index])
    sign_in_as(user)

    get employees_url
    assert_response :success

    get attendance_records_url
    assert_response :success
  end
end
