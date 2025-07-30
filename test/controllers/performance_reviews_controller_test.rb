require "test_helper"

class PerformanceReviewsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get performance_reviews_index_url
    assert_response :success
  end

  test "should get show" do
    get performance_reviews_show_url
    assert_response :success
  end

  test "should get create" do
    get performance_reviews_create_url
    assert_response :success
  end

  test "should get update" do
    get performance_reviews_update_url
    assert_response :success
  end

  test "should get destroy" do
    get performance_reviews_destroy_url
    assert_response :success
  end
end
