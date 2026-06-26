# frozen_string_literal: true

require "test_helper"

class Api::V1::Platform::AuthControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = PlatformAdminUser.create!(
      email: "platform@test.com",
      first_name: "Test",
      last_name: "Admin",
      password: "password123",
      password_confirmation: "password123",
      role: "super_admin",
      status: "active"
    )
  end

  test "login with valid credentials" do
    post "/api/v1/platform/auth/login",
         params: { email: @admin.email, password: "password123" },
         as: :json

    assert_response :ok
    body = JSON.parse(response.body)
    assert body["success"]
    assert body["data"]["token"].present?
    assert_equal @admin.email, body["data"]["admin"]["email"]
  end

  test "login with invalid credentials" do
    post "/api/v1/platform/auth/login",
         params: { email: @admin.email, password: "wrong" },
         as: :json

    assert_response :unauthorized
  end

  test "me with valid platform token" do
    token = PlatformJwtService.generate_token(@admin)

    get "/api/v1/platform/auth/me",
        headers: { "Authorization" => "Bearer #{token}" },
        as: :json

    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal @admin.id, body["data"]["admin"]["id"]
  end

  test "me rejects tenant token" do
    user = users(:one)
    token = JwtService.generate_token(user)

    get "/api/v1/platform/auth/me",
        headers: { "Authorization" => "Bearer #{token}" },
        as: :json

    assert_response :unauthorized
  end

  test "change_password with valid current password" do
    token = PlatformJwtService.generate_token(@admin)

    post "/api/v1/platform/auth/change_password",
         params: {
           current_password: "password123",
           new_password: "newpassword123",
           confirm_password: "newpassword123"
         },
         headers: { "Authorization" => "Bearer #{token}" },
         as: :json

    assert_response :ok
    assert @admin.reload.valid_password?("newpassword123")
  end

  test "super admin can reset another admin password" do
    other = PlatformAdminUser.create!(
      email: "other@test.com",
      first_name: "Other",
      last_name: "Admin",
      password: "password123",
      password_confirmation: "password123",
      role: "support",
      status: "active"
    )
    token = PlatformJwtService.generate_token(@admin)

    patch "/api/v1/platform/admins/#{other.id}/password",
          params: { new_password: "resetpass123", confirm_password: "resetpass123" },
          headers: { "Authorization" => "Bearer #{token}" },
          as: :json

    assert_response :ok
    assert other.reload.valid_password?("resetpass123")
  end
end
