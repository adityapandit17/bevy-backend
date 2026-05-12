# frozen_string_literal: true

require "test_helper"

class MultitenancyTenantIsolationTest < ActionDispatch::IntegrationTest
  test "cannot fetch employee from another workspace when scoped by X-Company-Id" do
    company_one = companies(:one)
    other_workspace_employee = employees(:two)

    CompanyMembership.find_or_create_by!(user: @auth_user, company: company_one) do |m|
      m.status = "active"
    end

    get "/employees/#{other_workspace_employee.id}",
        headers: auth_headers_for.merge("X-Company-Id" => company_one.id.to_s)

    assert_response :not_found
    json = JSON.parse(response.body)
    assert_equal "Employee not found", json["error"]
  end

end
