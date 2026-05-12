require "test_helper"

class Api::V1::AuthControllerTest < ActionDispatch::IntegrationTest
  def setup
    super
    # Integration tests auto-inject JWT by default; these tests opt in per request.
    @auth_headers = {}

    @user = users(:one) # Assuming you have a user fixture
    @valid_credentials = {
      email: @user.email,
      password: "password123" # Assuming this is the password in fixtures
    }
    @invalid_credentials = {
      email: @user.email,
      password: "wrongpassword"
    }
  end

  # Login tests
  test "should login with valid credentials" do
    post "/api/v1/auth/login", params: @valid_credentials, as: :json

    assert_response :ok
    response_data = JSON.parse(response.body)

    assert response_data["success"]
    assert_not_nil response_data["data"]["token"]
    assert_equal @user.id, response_data["data"]["user"]["id"]
    assert_equal @user.email, response_data["data"]["user"]["email"]
    assert_equal @user.name, response_data["data"]["user"]["name"]
  end

  test "should not login with invalid credentials" do
    post "/api/v1/auth/login", params: @invalid_credentials, as: :json

    assert_response :unauthorized
    response_data = JSON.parse(response.body)

    assert_not response_data["success"]
    assert_equal "Invalid email or password", response_data["error"]
  end

  test "should not login with missing email" do
    post "/api/v1/auth/login", params: { password: "password123" }, as: :json

    assert_response :bad_request
    response_data = JSON.parse(response.body)

    assert_not response_data["success"]
    assert_equal "Email and password are required", response_data["error"]
  end

  test "should not login with missing password" do
    post "/api/v1/auth/login", params: { email: @user.email }, as: :json

    assert_response :bad_request
    response_data = JSON.parse(response.body)

    assert_not response_data["success"]
    assert_equal "Email and password are required", response_data["error"]
  end

  test "should not login with non-existent user" do
    post "/api/v1/auth/login", params: {
      email: "nonexistent@example.com",
      password: "password123"
    }, as: :json

    assert_response :unauthorized
    response_data = JSON.parse(response.body)

    assert_not response_data["success"]
    assert_equal "Invalid email or password", response_data["error"]
  end

  # Logout tests
  test "should logout successfully with valid token" do
    token = JwtService.generate_token(@user)

    post "/api/v1/auth/logout",
         headers: { "Authorization" => "Bearer #{token}" },
         as: :json

    assert_response :ok
    response_data = JSON.parse(response.body)

    assert response_data["success"]
    assert_equal "Logged out successfully", response_data["data"]["message"]
  end

  test "should not logout without token" do
    post "/api/v1/auth/logout", as: :json

    assert_response :unauthorized
  end

  # Refresh tests
  test "should refresh token successfully" do
    token = JwtService.generate_token(@user)

    post "/api/v1/auth/refresh",
         headers: { "Authorization" => "Bearer #{token}" },
         as: :json

    assert_response :ok
    response_data = JSON.parse(response.body)

    assert response_data["success"]
    assert_not_nil response_data["data"]["token"]
    assert_equal @user.id, response_data["data"]["user"]["id"]
  end

  test "should not refresh token without authentication" do
    post "/api/v1/auth/refresh", as: :json

    assert_response :unauthorized
  end

  # Me endpoint tests
  test "should get current user info with valid token" do
    token = JwtService.generate_token(@user)

    get "/api/v1/auth/me",
        headers: { "Authorization" => "Bearer #{token}" },
        as: :json

    assert_response :ok
    response_data = JSON.parse(response.body)

    assert response_data["success"]
    assert_equal @user.id, response_data["data"]["user"]["id"]
    assert_equal @user.email, response_data["data"]["user"]["email"]
    assert_equal @user.name, response_data["data"]["user"]["name"]
  end

  test "should not get current user info without token" do
    get "/api/v1/auth/me", as: :json

    assert_response :unauthorized
  end

  # Validate tests
  test "should validate valid token" do
    token = JwtService.generate_token(@user)

    post "/api/v1/auth/validate",
         headers: { "Authorization" => "Bearer #{token}" },
         as: :json

    assert_response :ok
    response_data = JSON.parse(response.body)

    assert response_data["success"]
    assert response_data["data"]["valid"]
    assert_equal @user.id, response_data["data"]["user"]["id"]
  end

  test "should not validate invalid token" do
    post "/api/v1/auth/validate",
         headers: { "Authorization" => "Bearer invalid.token.here" },
         as: :json

    assert_response :unauthorized
    response_data = JSON.parse(response.body)

    assert_not response_data["success"]
    assert_equal "Invalid or expired token", response_data["error"]
  end

  test "should not validate without token" do
    post "/api/v1/auth/validate", as: :json

    assert_response :unauthorized
    response_data = JSON.parse(response.body)

    assert_not response_data["success"]
    assert_equal "Authorization token is required", response_data["error"]
  end

  test "should not validate expired token" do
    # Create an expired token
    expired_payload = {
      user_id: @user.id,
      email: @user.email,
      name: @user.name,
      roles: [ "Employee" ],
      iat: Time.current.to_i,
      exp: 1.hour.ago.to_i,
      jti: SecureRandom.uuid
    }

    expired_token = JWT.encode(expired_payload, JwtService::SECRET_KEY, "HS256")

    post "/api/v1/auth/validate",
         headers: { "Authorization" => "Bearer #{expired_token}" },
         as: :json

    assert_response :unauthorized
    response_data = JSON.parse(response.body)

    assert_not response_data["success"]
    assert_equal "Invalid or expired token", response_data["error"]
  end
end
