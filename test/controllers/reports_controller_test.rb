# frozen_string_literal: true

require "test_helper"

class ReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @company = companies(:one)
    ActsAsTenant.current_tenant = @company
    @user = create_api_user(permissions: %w[reports.index])
    @headers = jwt_headers_for(@user)
  end

  test "show returns employee directory report" do
    get report_path("employee-directory"), headers: @headers, as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "Employee Directory", json["data"]["title"]
    assert json["data"]["columns"].is_a?(Array)
    assert json["data"]["rows"].is_a?(Array)
  end

  test "show returns 404 for unknown report type" do
    get report_path("not-a-real-report"), headers: @headers, as: :json
    assert_response :not_found
  end

  test "show forbidden without reports permission" do
    user = create_api_user(permissions: [])
    get report_path("employee-directory"), headers: jwt_headers_for(user), as: :json
    assert_response :forbidden
  end
end
