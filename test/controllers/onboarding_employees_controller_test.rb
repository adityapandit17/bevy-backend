require "test_helper"

class OnboardingEmployeesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get onboarding_employees_index_url
    assert_response :success
  end

  test "should get show" do
    get onboarding_employees_show_url
    assert_response :success
  end

  test "should get create" do
    get onboarding_employees_create_url
    assert_response :success
  end

  test "should get update" do
    get onboarding_employees_update_url
    assert_response :success
  end

  test "should get destroy" do
    get onboarding_employees_destroy_url
    assert_response :success
  end
end
