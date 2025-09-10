require "test_helper"

class MaintenanceRecordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @maintenance_record = maintenance_records(:one)
  end

  test "should get index" do
    get maintenance_records_url
    assert_response :success
  end

  test "should get show" do
    get maintenance_record_url(@maintenance_record)
    assert_response :success
  end

  test "should create maintenance record" do
    post maintenance_records_url, params: {
      maintenance_record: {
        asset_id: @maintenance_record.asset_id,
        maintenance_date: Date.current,
        maintenance_type: "routine",
        description: "Test maintenance",
        cost: 100.00,
        performed_by: "Test Technician"
      }
    }, as: :json
    assert_response :created
  end

  test "should update maintenance record" do
    patch maintenance_record_url(@maintenance_record), params: {
      maintenance_record: { description: "Updated description" }
    }, as: :json
    assert_response :success
  end

  test "should get destroy" do
    delete maintenance_record_url(@maintenance_record)
    assert_response :success
  end

  test "should get schedule" do
    post schedule_maintenance_records_url, params: {
      asset_id: @maintenance_record.asset_id,
      maintenance_type: "routine",
      scheduled_date: Date.current + 1.week,
      notes: "Scheduled maintenance"
    }, as: :json
    assert_response :created
  end
end
