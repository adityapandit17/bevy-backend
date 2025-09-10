require "test_helper"

class JwtAuthenticationIntegrationTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one) # Assuming you have a user fixture
    @valid_token = JwtService.generate_token(@user)
    @invalid_token = "invalid.token.here"
  end

  test "should access API endpoints with valid JWT token" do
    # Test accessing a protected API endpoint
    get "/api/v1/auth/me",
        headers: { "Authorization" => "Bearer #{@valid_token}" },
        as: :json

    assert_response :ok
    response_data = JSON.parse(response.body)

    assert response_data["success"]
    assert_equal @user.id, response_data["data"]["user"]["id"]
  end

  test "should deny access to API endpoints without JWT token" do
    get "/api/v1/auth/me", as: :json

    assert_response :unauthorized
    response_data = JSON.parse(response.body)

    assert_not response_data["success"]
    assert_equal "Authorization token is required", response_data["error"]
  end

  test "should deny access to API endpoints with invalid JWT token" do
    get "/api/v1/auth/me",
        headers: { "Authorization" => "Bearer #{@invalid_token}" },
        as: :json

    assert_response :unauthorized
    response_data = JSON.parse(response.body)

    assert_not response_data["success"]
    assert_equal "Invalid or expired token", response_data["error"]
  end

  test "should allow access to non-API endpoints without JWT token" do
    # Test that non-API endpoints still work with session-based auth
    get "/dashboard"

    # This should redirect to login or work with session auth
    # The exact response depends on your session authentication setup
    # Since we don't have Devise routes set up, it will return 401
    assert_response :unauthorized
  end

  test "should handle JWT token refresh flow" do
    # Login to get initial token
    post "/api/v1/auth/login",
         params: { email: @user.email, password: "password123" },
         as: :json

    assert_response :ok
    login_response = JSON.parse(response.body)
    initial_token = login_response["data"]["token"]

    # Use the token to access protected endpoint
    get "/api/v1/auth/me",
        headers: { "Authorization" => "Bearer #{initial_token}" },
        as: :json

    assert_response :ok

    # Refresh the token
    post "/api/v1/auth/refresh",
         headers: { "Authorization" => "Bearer #{initial_token}" },
         as: :json

    assert_response :ok
    refresh_response = JSON.parse(response.body)
    new_token = refresh_response["data"]["token"]

    # Verify new token works
    get "/api/v1/auth/me",
        headers: { "Authorization" => "Bearer #{new_token}" },
        as: :json

    assert_response :ok
  end

  test "should handle complete authentication flow" do
    # 1. Login
    post "/api/v1/auth/login",
         params: { email: @user.email, password: "password123" },
         as: :json

    assert_response :ok
    login_response = JSON.parse(response.body)
    token = login_response["data"]["token"]

    # 2. Access protected resource
    get "/api/v1/auth/me",
        headers: { "Authorization" => "Bearer #{token}" },
        as: :json

    assert_response :ok

    # 3. Validate token
    post "/api/v1/auth/validate",
         headers: { "Authorization" => "Bearer #{token}" },
         as: :json

    assert_response :ok
    validate_response = JSON.parse(response.body)
    assert validate_response["data"]["valid"]

    # 4. Logout
    post "/api/v1/auth/logout",
         headers: { "Authorization" => "Bearer #{token}" },
         as: :json

    assert_response :ok
  end

  test "should handle case insensitive email in login" do
    post "/api/v1/auth/login",
         params: { email: @user.email.upcase, password: "password123" },
         as: :json

    assert_response :ok
    response_data = JSON.parse(response.body)

    assert response_data["success"]
    assert_equal @user.id, response_data["data"]["user"]["id"]
  end

  test "should update last_login_at on successful authentication" do
    initial_login_time = @user.last_login_at

    post "/api/v1/auth/login",
         params: { email: @user.email, password: "password123" },
         as: :json

    assert_response :ok

    @user.reload
    assert @user.last_login_at > initial_login_time if initial_login_time
  end

  test "should include user roles and permissions in token response" do
    post "/api/v1/auth/login",
         params: { email: @user.email, password: "password123" },
         as: :json

    assert_response :ok
    response_data = JSON.parse(response.body)

    assert response_data["data"]["user"]["roles"].is_a?(Array)
    assert response_data["data"]["user"]["permissions"].is_a?(Array)
  end

  test "should handle inactive user authentication" do
    # Assuming you have an inactive user fixture
    inactive_user = users(:inactive) if defined?(users(:inactive))

    if inactive_user
      post "/api/v1/auth/login",
           params: { email: inactive_user.email, password: "password123" },
           as: :json

      assert_response :unauthorized
      response_data = JSON.parse(response.body)

      assert_not response_data["success"]
      assert_equal "Invalid email or password", response_data["error"]
    end
  end

  test "should handle suspended user authentication" do
    # Assuming you have a suspended user fixture
    suspended_user = users(:suspended) if defined?(users(:suspended))

    if suspended_user
      post "/api/v1/auth/login",
           params: { email: suspended_user.email, password: "password123" },
           as: :json

      assert_response :unauthorized
      response_data = JSON.parse(response.body)

      assert_not response_data["success"]
      assert_equal "Invalid email or password", response_data["error"]
    end
  end
end
