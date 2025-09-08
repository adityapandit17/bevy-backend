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

  test "should not update company with invalid params" do
    patch company_url, params: { company: { name: "" } }, as: :json
    assert_response :unprocessable_entity
  end
end
