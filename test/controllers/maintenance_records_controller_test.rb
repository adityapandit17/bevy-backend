require "test_helper"

class MaintenanceRecordsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get maintenance_records_index_url
    assert_response :success
  end

  test "should get show" do
    get maintenance_records_show_url
    assert_response :success
  end

  test "should get create" do
    get maintenance_records_create_url
    assert_response :success
  end

  test "should get update" do
    get maintenance_records_update_url
    assert_response :success
  end

  test "should get destroy" do
    get maintenance_records_destroy_url
    assert_response :success
  end

  test "should get schedule" do
    get maintenance_records_schedule_url
    assert_response :success
  end
end
