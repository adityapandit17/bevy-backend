# frozen_string_literal: true

require "test_helper"

class Api::V1::Public::SignupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Role.find_or_create_by!(name: "Super Admin") { |r| r.description = "Full access" }
    Department.find_or_create_by!(name: "General")
  end

  test "creates trial company and admin user" do
    assert_difference [ "Company.count", "User.count", "Employee.count" ], 1 do
      post "/api/v1/public/signup",
           params: {
             company_name: "Acme Trial Co",
             industry: "technology",
             employee_count: "1-50",
             plan: "starter",
             admin_first_name: "Jane",
             admin_last_name: "Founder",
             admin_email: "jane@acmetrial.com",
             admin_password: "securepass123"
           },
           as: :json
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert body["success"]
    assert body["data"]["token"].present?
    assert_equal "trial", body["data"]["company"]["status"]

    company = Company.find_by(code: body["data"]["company"]["code"])
    assert company.trial_ends_at.present?
    assert User.exists?(email: "jane@acmetrial.com", company_id: company.id)
  end

  test "rejects duplicate email" do
    existing = users(:one)

    post "/api/v1/public/signup",
         params: {
           company_name: "Another Co",
           admin_first_name: "Test",
           admin_last_name: "User",
           admin_email: existing.email,
           admin_password: "securepass123"
         },
         as: :json

    assert_response :unprocessable_entity
  end
end
