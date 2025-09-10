require "test_helper"

class JwtServiceTest < ActiveSupport::TestCase
  def setup
    @user = users(:one) # Assuming you have a user fixture
    @payload = {
      user_id: @user.id,
      email: @user.email,
      name: @user.name,
      roles: [ "Employee" ],
      iat: Time.current.to_i,
      jti: SecureRandom.uuid
    }
  end

  test "should encode payload successfully" do
    token = JwtService.encode(@payload)
    assert_not_nil token
    assert_kind_of String, token
  end

  test "should decode valid token successfully" do
    token = JwtService.encode(@payload)
    decoded = JwtService.decode(token)

    assert_not_nil decoded
    assert_equal @payload[:user_id], decoded["user_id"]
    assert_equal @payload[:email], decoded["email"]
    assert_equal @payload[:name], decoded["name"]
  end

  test "should return nil for invalid token" do
    invalid_token = "invalid.token.here"
    decoded = JwtService.decode(invalid_token)

    assert_nil decoded
  end

  test "should return nil for expired token" do
    # Create an expired payload
    expired_payload = @payload.dup
    expired_payload[:exp] = 1.hour.ago.to_i

    token = JWT.encode(expired_payload, JwtService::SECRET_KEY, "HS256")
    decoded = JwtService.decode(token)

    assert_nil decoded
  end

  test "should generate token for user" do
    token = JwtService.generate_token(@user)

    assert_not_nil token
    assert_kind_of String, token

    # Decode and verify the token contains user information
    decoded = JwtService.decode(token)
    assert_equal @user.id, decoded["user_id"]
    assert_equal @user.email, decoded["email"]
    assert_equal @user.name, decoded["name"]
  end

  test "should verify valid token and return user" do
    token = JwtService.generate_token(@user)
    user = JwtService.verify_token(token)

    assert_equal @user, user
  end

  test "should return nil for invalid token in verify_token" do
    invalid_token = "invalid.token.here"
    user = JwtService.verify_token(invalid_token)

    assert_nil user
  end

  test "should return nil for expired token in verify_token" do
    # Create an expired token
    expired_payload = @payload.dup
    expired_payload[:exp] = 1.hour.ago.to_i

    token = JWT.encode(expired_payload, JwtService::SECRET_KEY, "HS256")
    user = JwtService.verify_token(token)

    assert_nil user
  end

  test "should return nil for non-existent user in verify_token" do
    # Create token for non-existent user
    fake_payload = @payload.dup
    fake_payload[:user_id] = 99999

    token = JWT.encode(fake_payload, JwtService::SECRET_KEY, "HS256")
    user = JwtService.verify_token(token)

    assert_nil user
  end

  test "should extract token from authorization header" do
    auth_header = "Bearer eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxfQ"
    token = JwtService.extract_token(auth_header)

    assert_equal "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxfQ", token
  end

  test "should return nil for invalid authorization header format" do
    auth_header = "Invalid eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxfQ"
    token = JwtService.extract_token(auth_header)

    assert_nil token
  end

  test "should return nil for empty authorization header" do
    token = JwtService.extract_token("")
    assert_nil token

    token = JwtService.extract_token(nil)
    assert_nil token
  end

  test "should validate token correctly" do
    token = JwtService.generate_token(@user)
    is_valid = JwtService.valid_token?(token)

    assert is_valid
  end

  test "should return false for invalid token in valid_token?" do
    invalid_token = "invalid.token.here"
    is_valid = JwtService.valid_token?(invalid_token)

    assert_not is_valid
  end

  test "should get current user from token without updating last login" do
    token = JwtService.generate_token(@user)
    user = JwtService.current_user_from_token(token)

    assert_equal @user, user
  end

  test "should return nil for invalid token in current_user_from_token" do
    invalid_token = "invalid.token.here"
    user = JwtService.current_user_from_token(invalid_token)

    assert_nil user
  end
end
