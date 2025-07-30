require "test_helper"

class PerformanceGoalsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get performance_goals_index_url
    assert_response :success
  end

  test "should get show" do
    get performance_goals_show_url
    assert_response :success
  end

  test "should get create" do
    get performance_goals_create_url
    assert_response :success
  end

  test "should get update" do
    get performance_goals_update_url
    assert_response :success
  end

  test "should get destroy" do
    get performance_goals_destroy_url
    assert_response :success
  end
end
