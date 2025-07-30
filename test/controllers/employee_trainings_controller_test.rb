require "test_helper"

class EmployeeTrainingsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get employee_trainings_index_url
    assert_response :success
  end

  test "should get show" do
    get employee_trainings_show_url
    assert_response :success
  end

  test "should get create" do
    get employee_trainings_create_url
    assert_response :success
  end

  test "should get update" do
    get employee_trainings_update_url
    assert_response :success
  end

  test "should get destroy" do
    get employee_trainings_destroy_url
    assert_response :success
  end
end
