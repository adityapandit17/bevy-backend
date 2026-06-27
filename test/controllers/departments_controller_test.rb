require "test_helper"

class DepartmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @department = departments(:one)
    @valid_attributes = { name: "Human Resources" }
    @admin_user = create_api_user(permissions: %w[settings.update settings.index])
    sign_in_as(@admin_user)
  end

  test "should get index when authenticated" do
    get departments_url, headers: @auth_headers, as: :json
    assert_response :success
    body = json_response
    assert body.is_a?(Array)
    assert body.first.key?("employee_count")
  end

  test "should require authentication for index" do
    without_authentication do
      get departments_url, headers: @auth_headers, as: :json
      assert_json_unauthorized
    end
  end

  test "should get defaults" do
    get defaults_departments_url, headers: @auth_headers, as: :json
    assert_response :success
    body = json_response
    assert_includes body["default_names"], "Engineering"
    assert body["missing"].is_a?(Array)
  end

  test "should seed defaults" do
    get defaults_departments_url, headers: @auth_headers, as: :json
    missing_count = json_response["missing"].size
    skip "all defaults already present" if missing_count.zero?

    assert_difference("Department.count", missing_count) do
      post seed_defaults_departments_url, headers: @auth_headers, as: :json
    end

    assert_response :success
  end

  test "should create department" do
    assert_difference("Department.count") do
      post departments_url, params: { department: @valid_attributes }, headers: @auth_headers, as: :json
    end

    assert_response :created
  end

  test "should not create department without settings permission" do
    sign_in_as(create_api_user(permissions: []))

    assert_no_difference("Department.count") do
      post departments_url, params: { department: @valid_attributes }, headers: @auth_headers, as: :json
    end

    assert_json_forbidden
  end

  test "should not create department with invalid name" do
    assert_no_difference("Department.count") do
      post departments_url, params: { department: { name: nil } }, headers: @auth_headers, as: :json
    end

    assert_response :unprocessable_entity
  end

  test "should show department" do
    get department_url(@department), headers: @auth_headers, as: :json
    assert_response :success
  end

  test "should update department" do
    patch department_url(@department), params: { department: { name: "Updated HR" } }, headers: @auth_headers, as: :json
    assert_response :success
    @department.reload
    assert_equal "Updated HR", @department.name
  end

  test "should not update department with invalid name" do
    patch department_url(@department), params: { department: { name: nil } }, headers: @auth_headers, as: :json
    assert_response :unprocessable_entity
  end

  test "should destroy department" do
    isolated_department = Department.create!(name: "Isolated Department")

    assert_difference("Department.count", -1) do
      delete department_url(isolated_department), headers: @auth_headers, as: :json
    end

    assert_response :no_content
  end
end
