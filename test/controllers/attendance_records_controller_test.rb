require "test_helper"

class AttendanceRecordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @attendance_record = attendance_records(:one)
  end

  test "should get index" do
    get attendance_records_url
    assert_response :success
  end

  test "should get show" do
    get attendance_record_url(@attendance_record)
    assert_response :success
  end

  test "should create attendance record" do
    post attendance_records_url, params: { 
      attendance_record: {
        employee_id: @attendance_record.employee_id,
        date: Date.current,
        check_in: Time.current,
        check_out: Time.current + 8.hours,
        status: "present"
      }
    }, as: :json
    assert_response :created
  end

  test "should update attendance record" do
    patch attendance_record_url(@attendance_record), params: { 
      attendance_record: { status: "late" }
    }, as: :json
    assert_response :success
  end

  test "should destroy attendance record" do
    delete attendance_record_url(@attendance_record)
    assert_response :success
  end
end
