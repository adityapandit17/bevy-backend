# frozen_string_literal: true

require "test_helper"

class Api::V1::Public::SignupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Role.find_or_create_by!(name: "Super Admin") { |r| r.description = "Full access" }
    Department.find_or_create_by!(name: "General")
  end

  test "creates trial company and admin user" do
    email = "jane.#{SecureRandom.hex(4)}@acmetrial.com"

    assert_difference("Company.unscoped.count", 1) do
      post "/api/v1/public/signup",
           params: {
             company_name: "Acme Trial Co",
             industry: "technology",
             employee_count: "1-50",
             plan: "starter",
             admin_first_name: "Jane",
             admin_last_name: "Founder",
             admin_email: email,
             admin_password: "securepass123"
           },
           as: :json
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert body["success"]
    assert body["data"]["token"].present?
    assert_equal "trial", body["data"]["company"]["status"]

    company = Company.unscoped.find_by(code: body["data"]["company"]["code"])
    assert company.trial_ends_at.present?

    ActsAsTenant.with_tenant(company) do
      assert_equal 1, User.count
      assert User.exists?(email: email)
      assert_equal 1, Employee.count
      assert_equal DepartmentSeeder.default_names.size, Department.count
      assert Department.exists?(name: "Engineering")
      assert Department.exists?(name: "General")
    end
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
