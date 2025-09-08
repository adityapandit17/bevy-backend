require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  def setup
    # Create a test user
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      first_name: "Test",
      last_name: "User",
      status: "active"
    )
    
    # Create a role and assign it to the user
    @role = Role.create!(name: "Test Role", description: "Test role for testing")
    @user.roles << @role
  end

  test "should login with valid credentials" do
    post sessions_url, params: { email: @user.email, password: "password123" }, as: :json
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "Login successful", json_response["message"]
    assert_equal @user.id, json_response["user"]["id"]
    assert_equal @user.email, json_response["user"]["email"]
  end

  test "should not login with invalid credentials" do
    post sessions_url, params: { email: @user.email, password: "wrongpassword" }, as: :json
    
    assert_response :unauthorized
    json_response = JSON.parse(response.body)
    assert_equal "Invalid email or password", json_response["error"]
  end

  test "should logout successfully" do
    # First login
    post sessions_url, params: { email: @user.email, password: "password123" }, as: :json
    assert_response :success
    
    # Then logout
    delete sessions_url, as: :json
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "Logout successful", json_response["message"]
  end

  test "should get current user when authenticated" do
    # Login first
    post sessions_url, params: { email: @user.email, password: "password123" }, as: :json
    assert_response :success
    
    # Get current user
    get current_sessions_url, as: :json
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal @user.id, json_response["user"]["id"]
  end

  test "should not get current user when not authenticated" do
    get current_sessions_url, as: :json
    assert_response :unauthorized
    json_response = JSON.parse(response.body)
    assert_equal "Authentication required", json_response["error"]
  end
end
