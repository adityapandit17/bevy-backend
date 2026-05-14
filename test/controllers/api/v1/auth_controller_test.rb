require "test_helper"

class Api::V1::AuthControllerTest < ActionDispatch::IntegrationTest
  def setup
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

  test "accept_invitation returns jwt for valid invitation token" do
    inviter = users(:one)
    invited = User.invite!(
      {
        email: "invited_accept_#{SecureRandom.hex(4)}@example.com",
        first_name: "Inv",
        last_name: "Itee",
        status: "active"
      },
      inviter
    ) { |u| u.skip_invitation = true }

    assert_predicate invited, :persisted?
    raw = invited.raw_invitation_token
    assert raw.present?

    post "/api/v1/auth/accept_invitation",
         params: {
           invitation_token: raw,
           password: "newpass99",
           password_confirmation: "newpass99"
         },
         as: :json

    assert_response :ok
    response_data = JSON.parse(response.body)
    assert response_data["success"]
    assert_not_nil response_data["data"]["token"]
    assert_equal invited.email, response_data["data"]["user"]["email"]
  end

  test "accept_invitation rejects invalid token" do
    post "/api/v1/auth/accept_invitation",
         params: {
           invitation_token: "not-a-real-token",
           password: "newpass99",
           password_confirmation: "newpass99"
         },
         as: :json

    assert_response :unprocessable_entity
    response_data = JSON.parse(response.body)
    assert_not response_data["success"]
  end

  test "accept_invitation requires token and password" do
    post "/api/v1/auth/accept_invitation",
         params: { password: "newpass99" },
         as: :json

    assert_response :bad_request
  end
end
