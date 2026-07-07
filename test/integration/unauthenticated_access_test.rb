# frozen_string_literal: true

require "test_helper"

# Ensures sensitive tenant routes cannot be accessed without authentication when the
# client omits Accept: application/json (direct browser/curl access).
class UnauthenticatedAccessTest < ActionDispatch::IntegrationTest
  SENSITIVE_GET_PATHS = [
    "/payrolls",
    "/salary_structures",
    "/api/assets",
    "/events",
    "/helpdesk_tickets",
    "/policy_documents",
    "/permissions",
    "/notifications",
    "/timesheets",
    "/performance_reviews",
    "/employee_documents",
    "/onboarding_employees",
    "/expenses",
    "/projects"
  ].freeze

  PUBLIC_GET_PATHS = [
    "/api/v1/public/pricing",
    "/up"
  ].freeze

  SENSITIVE_GET_PATHS.each do |path|
    test "GET #{path} returns 401 without auth and without JSON Accept header" do
      without_authentication do
        get path, headers: { "Accept" => "text/html" }
      end

      assert_response :unauthorized
      assert json_response["error"].present?, "expected error message in #{json_response.inspect}"
    end
  end

  test "POST /uploads returns 401 without auth" do
    without_authentication do
      post "/uploads", headers: { "Accept" => "text/html" }
    end

    assert_response :unauthorized
  end

  test "legacy POST /sessions route is not available" do
    post "/sessions",
         params: { email: "admin@hrms.com", password: "admin123" }.to_json,
         headers: { "Content-Type" => "application/json", "Accept" => "application/json" }

    assert_response :not_found
  end

  test "devise web sign-in route is not available" do
    get "/users/sign_in", headers: { "Accept" => "text/html" }

    assert_response :not_found
  end

  PUBLIC_GET_PATHS.each do |path|
    test "GET #{path} remains publicly accessible" do
      without_authentication do
        get path, headers: { "Accept" => "text/html" }
      end

      assert_response :success
    end
  end

  test "GET /api/v1/auth/login remains reachable for unauthenticated clients" do
    without_authentication do
      post "/api/v1/auth/login",
           params: { email: "missing@example.com", password: "wrong" }.to_json,
           headers: { "Content-Type" => "application/json", "Accept" => "text/html" }
    end

    assert_response :unauthorized
    assert json_response["error"].present?
  end

  test "authenticated GET /payrolls succeeds without JSON Accept when bearer token is sent" do
    sign_in_as(create_api_user(permissions: %w[payrolls.index]))

    get "/payrolls",
        headers: {
          "Accept" => "text/html",
          "Authorization" => @auth_headers["Authorization"]
        }

    assert_response :success
  end
end
