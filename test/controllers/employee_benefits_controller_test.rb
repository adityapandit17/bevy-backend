require "test_helper"

class EmployeeBenefitsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get employee_benefits_index_url
    assert_response :success
  end

  test "should get show" do
    get employee_benefits_show_url
    assert_response :success
  end

  test "should get create" do
    get employee_benefits_create_url
    assert_response :success
  end

  test "should get update" do
    get employee_benefits_update_url
    assert_response :success
  end

  test "should get destroy" do
    get employee_benefits_destroy_url
    assert_response :success
  end
end
