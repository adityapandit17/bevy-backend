require "test_helper"

class JwtAuthenticatableTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one) # Assuming you have a user fixture
    @valid_token = JwtService.generate_token(@user)
    @invalid_token = "invalid.token.here"
  end

  # Test controller that includes JwtAuthenticatable
  class TestController < ApplicationController
    include JwtAuthenticatable

    def index
      render json: { message: "Success", user_id: current_user&.id }
    end

    def protected_action
      authenticate_user!
      render json: { message: "Protected action accessed", user_id: current_user.id }
    end
  end

  test "should authenticate user with valid token" do
    get "/api/test",
        headers: { "Authorization" => "Bearer #{@valid_token}" },
        as: :json

    assert_response :ok
    response_data = JSON.parse(response.body)

    assert_equal @user.id, response_data["user_id"]
  end

  test "should not authenticate user with invalid token" do
    get "/api/test",
        headers: { "Authorization" => "Bearer #{@invalid_token}" },
        as: :json

    assert_response :unauthorized
    response_data = JSON.parse(response.body)

    assert_not response_data["success"]
    assert_equal "Invalid or expired token", response_data["error"]
  end

  test "should not authenticate user without token" do
    get "/api/test", as: :json

    assert_response :unauthorized
    response_data = JSON.parse(response.body)

    assert_not response_data["success"]
    assert_equal "Authorization token is required", response_data["error"]
  end

  test "should not authenticate user with malformed authorization header" do
    get "/api/test",
        headers: { "Authorization" => "Invalid #{@valid_token}" },
        as: :json

    assert_response :unauthorized
    response_data = JSON.parse(response.body)

    assert_not response_data["success"]
    assert_equal "Authorization token is required", response_data["error"]
  end

  test "should allow access to protected action with valid token" do
    get "/api/protected",
        headers: { "Authorization" => "Bearer #{@valid_token}" },
        as: :json

    assert_response :ok
    response_data = JSON.parse(response.body)

    assert_equal "Protected action accessed", response_data["message"]
    assert_equal @user.id, response_data["user_id"]
  end

  test "should deny access to protected action without token" do
    get "/api/protected", as: :json

    assert_response :unauthorized
    response_data = JSON.parse(response.body)

    assert_not response_data["success"]
    assert_equal "Authentication required", response_data["error"]
  end

  test "should deny access to protected action with invalid token" do
    get "/api/protected",
        headers: { "Authorization" => "Bearer #{@invalid_token}" },
        as: :json

    assert_response :unauthorized
    response_data = JSON.parse(response.body)

    assert_not response_data["success"]
    assert_equal "Invalid or expired token", response_data["error"]
  end

  test "should set current_user correctly" do
    get "/api/test",
        headers: { "Authorization" => "Bearer #{@valid_token}" },
        as: :json

    assert_response :ok
    response_data = JSON.parse(response.body)

    assert_equal @user.id, response_data["user_id"]
  end

  test "should return false for user_signed_in? without token" do
    get "/api/test", as: :json

    assert_response :unauthorized
  end

  test "should return true for user_signed_in? with valid token" do
    get "/api/test",
        headers: { "Authorization" => "Bearer #{@valid_token}" },
        as: :json

    assert_response :ok
  end

  test "should handle expired token" do
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

    get "/api/test",
        headers: { "Authorization" => "Bearer #{expired_token}" },
        as: :json

    assert_response :unauthorized
    response_data = JSON.parse(response.body)

    assert_not response_data["success"]
    assert_equal "Invalid or expired token", response_data["error"]
  end

  test "should handle non-existent user in token" do
    # Create token for non-existent user
    fake_payload = {
      user_id: 99999,
      email: "fake@example.com",
      name: "Fake User",
      roles: [ "Employee" ],
      iat: Time.current.to_i,
      exp: 24.hours.from_now.to_i,
      jti: SecureRandom.uuid
    }

    fake_token = JWT.encode(fake_payload, JwtService::SECRET_KEY, "HS256")

    get "/api/test",
        headers: { "Authorization" => "Bearer #{fake_token}" },
        as: :json

    assert_response :unauthorized
    response_data = JSON.parse(response.body)

    assert_not response_data["success"]
    assert_equal "Invalid or expired token", response_data["error"]
  end
end
