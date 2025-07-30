require "test_helper"

class CompaniesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @company = companies(:one)
    @valid_attributes = {
      name: "New Company Name",
      address: "123 New Street",
      phone: "9876543210",
      email: "contact@newcompany.com"
    }
  end

  test "should get show" do
    get company_url, as: :json
    assert_response :success
  end

  test "should update company" do
    patch company_url, params: { company: @valid_attributes }, as: :json
    assert_response :success
    @company.reload
    assert_equal "New Company Name", @company.name
    assert_equal "contact@newcompany.com", @company.email
  end

  test "should not update company with invalid params" do
    patch company_url, params: { company: { name: "" } }, as: :json
    assert_response :unprocessable_entity
  end
end
