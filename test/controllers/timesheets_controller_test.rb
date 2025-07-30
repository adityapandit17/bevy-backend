require "test_helper"

class TimesheetsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get timesheets_index_url
    assert_response :success
  end

  test "should get show" do
    get timesheets_show_url
    assert_response :success
  end

  test "should get create" do
    get timesheets_create_url
    assert_response :success
  end

  test "should get update" do
    get timesheets_update_url
    assert_response :success
  end

  test "should get destroy" do
    get timesheets_destroy_url
    assert_response :success
  end
end
