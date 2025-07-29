require "test_helper"

class LeaveRequestsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get leave_requests_index_url
    assert_response :success
  end

  test "should get show" do
    get leave_requests_show_url
    assert_response :success
  end

  test "should get create" do
    get leave_requests_create_url
    assert_response :success
  end

  test "should get update" do
    get leave_requests_update_url
    assert_response :success
  end

  test "should get destroy" do
    get leave_requests_destroy_url
    assert_response :success
  end
end
