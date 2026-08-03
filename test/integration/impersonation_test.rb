# frozen_string_literal: true

require "test_helper"

class ImpersonationTest < ActionDispatch::IntegrationTest
  setup do
    @company = companies(:one)
    @admin = users(:admin)
    @target = users(:one)
    @other = users(:two)

    @super_admin_role = Role.find_or_create_by!(name: "Super Admin", company_id: nil) do |role|
      role.description = "Full access"
    end
    @admin.roles << @super_admin_role unless @admin.roles.exists?(id: @super_admin_role.id)

    CompanyFeatureFlag.update_for_company!(@company, { impersonation: true })

    @platform_admin = PlatformAdminUser.create!(
      email: "platform-impersonate@test.com",
      first_name: "Platform",
      last_name: "Admin",
      password: "password123",
      password_confirmation: "password123",
      role: "super_admin",
      status: "active"
    )
  end

  test "tenant impersonation requires feature flag" do
    CompanyFeatureFlag.update_for_company!(@company, { impersonation: false })
    token = JwtService.generate_token(@admin)

    post "/api/v1/auth/impersonate",
         params: { user_id: @target.id },
         headers: { "Authorization" => "Bearer #{token}" },
         as: :json

    assert_response :forbidden
  end

  test "tenant super admin can impersonate and stop" do
    token = JwtService.generate_token(@admin)

    post "/api/v1/auth/impersonate",
         params: { user_id: @target.id },
         headers: { "Authorization" => "Bearer #{token}" },
         as: :json

    assert_response :ok
    body = JSON.parse(response.body)
    assert body["success"]
    assert body["data"]["impersonation"]["active"]
    assert_equal @target.id, body["data"]["user"]["id"]

    imp_token = body["data"]["token"]
    payload = JwtService.decode(imp_token)
    assert_equal true, ActiveModel::Type::Boolean.new.cast(payload["imp"])
    assert_equal @admin.id, payload["impersonator_id"]

    get "/api/v1/auth/me",
        headers: { "Authorization" => "Bearer #{imp_token}" },
        as: :json

    assert_response :ok
    me = JSON.parse(response.body)
    assert me["data"]["impersonation"]["active"]
    assert_equal @admin.id, me["data"]["impersonation"]["impersonator"]["id"]

    post "/api/v1/auth/stop_impersonation",
         headers: { "Authorization" => "Bearer #{imp_token}" },
         as: :json

    assert_response :ok
    stop = JSON.parse(response.body)
    assert_equal @admin.id, stop["data"]["user"]["id"]
    assert_equal false, stop["data"]["impersonation"]["active"]
  end

  test "cannot change password while impersonating" do
    token = JwtService.generate_impersonation_token(@target, impersonator_id: @admin.id)

    post "/api/v1/auth/change_password",
         params: {
           current_password: "password123",
           new_password: "newpassword1",
           confirm_password: "newpassword1"
         },
         headers: { "Authorization" => "Bearer #{token}" },
         as: :json

    assert_response :forbidden
  end

  test "non super admin cannot impersonate" do
    token = JwtService.generate_token(@other)

    post "/api/v1/auth/impersonate",
         params: { user_id: @target.id },
         headers: { "Authorization" => "Bearer #{token}" },
         as: :json

    assert_response :forbidden
  end

  test "platform admin can impersonate company admin" do
    platform_token = PlatformJwtService.generate_token(@platform_admin)

    post "/api/v1/platform/companies/#{@company.id}/impersonate",
         headers: { "Authorization" => "Bearer #{platform_token}" },
         as: :json

    assert_response :ok
    body = JSON.parse(response.body)
    assert body["success"]
    assert body["data"]["token"].present?
    assert body["data"]["redirect_url"].include?("/impersonation/accept")
    assert_equal @admin.id, body["data"]["user"]["id"]

    tenant_token = body["data"]["token"]
    payload = JwtService.decode(tenant_token)
    assert_equal @platform_admin.id, payload["platform_admin_id"]
    assert JwtService.impersonating?(payload)

    get "/api/v1/auth/me",
        headers: { "Authorization" => "Bearer #{tenant_token}" },
        as: :json

    assert_response :ok
    me = JSON.parse(response.body)
    assert me["data"]["impersonation"]["platform"]
  end

  test "feature flags include impersonation key" do
    flags = CompanyFeatureFlag.for_company(@company)
    assert flags.key?("impersonation")
  end
end
