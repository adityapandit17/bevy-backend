require "test_helper"

class AttendanceRecordsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get attendance_records_index_url
    assert_response :success
  end

  test "should get show" do
    get attendance_records_show_url
    assert_response :success
  end

  test "should get create" do
    get attendance_records_create_url
    assert_response :success
  end

  test "should get update" do
    get attendance_records_update_url
    assert_response :success
  end

  test "should get destroy" do
    get attendance_records_destroy_url
    assert_response :success
  end
end
