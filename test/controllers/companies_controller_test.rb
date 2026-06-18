require "test_helper"

class CompaniesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @company = companies(:one)
    @valid_attributes = {
      name: "New Company Name",
      address: "123 New Street",
      code: "NEWCO",
      industry: "Technology",
      employee_count: "100-500",
      timezone: "UTC",
      currency: "USD"
    }
  end

  test "should get show" do
    get company_url, as: :json
    assert_response :success
  end

  test "should update company" do
    patch company_url, params: { company: @valid_attributes }, as: :json
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "New Company Name", json_response["name"]
    assert_equal "NEWCO", json_response["code"]
  end

  test "should update work settings on company" do
    patch company_url, params: {
      company: {
        weekly_working_hours: 37.5,
        work_start_time: "08:30",
        work_end_time: "17:30",
        lunch_duration_minutes: 45
      }
    }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "37.5", body["weekly_working_hours"].to_s
    assert_equal "08:30", body["work_start_time"]
    assert_equal "17:30", body["work_end_time"]
    assert_equal 45, body["lunch_duration_minutes"]

    updated = Company.find(body["id"])
    assert_equal 37.5, updated.weekly_working_hours.to_f
  end

  test "show includes work settings defaults" do
    company = companies(:one)
    company.update!(weekly_working_hours: 40, work_start_time: "09:00", work_end_time: "18:00")

    get company_url, as: :json
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal 40.0, body["weekly_working_hours"].to_f
    assert_equal "09:00", body["work_start_time"]
  end

  test "should update dashboard layout on company" do
    patch company_url, params: {
      company: { dashboard_layout: "sidebar" }
    }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "sidebar", body["dashboard_layout"]

    updated = Company.find(body["id"])
    assert_equal "sidebar", updated.dashboard_layout
  end

  test "show includes dashboard layout default" do
    get company_url, as: :json
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal "top_nav", body["dashboard_layout"]
  end

  test "should not update company with invalid params" do
    patch company_url, params: { company: { name: "" } }, as: :json
    assert_response :unprocessable_entity
  end
end
