require "test_helper"

class OnboardingTasksControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get onboarding_tasks_index_url
    assert_response :success
  end

  test "should get show" do
    get onboarding_tasks_show_url
    assert_response :success
  end

  test "should get create" do
    get onboarding_tasks_create_url
    assert_response :success
  end

  test "should get update" do
    get onboarding_tasks_update_url
    assert_response :success
  end

  test "should get destroy" do
    get onboarding_tasks_destroy_url
    assert_response :success
  end
end
