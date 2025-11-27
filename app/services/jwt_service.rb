class JwtService
  # JWT secret key - in production, this should be stored in environment variables
  SECRET_KEY = Rails.application.credentials.secret_key_base || "your-secret-key"

  # Token expiration time (24 hours)
  EXPIRATION_TIME = 24.hours

  class << self
    # Generate JWT token for a user
    def encode(payload)
      payload[:exp] = EXPIRATION_TIME.from_now.to_i
      JWT.encode(payload, SECRET_KEY, "HS256")
    end

    # Decode and verify JWT token
    def decode(token)
      decoded_token = JWT.decode(token, SECRET_KEY, true, { algorithm: "HS256" })
      decoded_token[0]
    rescue JWT::DecodeError => e
      Rails.logger.error "JWT Decode Error: #{e.message}"
      nil
    rescue JWT::ExpiredSignature => e
      Rails.logger.error "JWT Expired: #{e.message}"
      nil
    rescue JWT::InvalidJtiError => e
      Rails.logger.error "JWT Invalid JTI: #{e.message}"
      nil
    end

    # Generate token for user authentication
    def generate_token(user)
      payload = {
        user_id: user.id,
        email: user.email,
        name: user.name,
        roles: user.roles.pluck(:name),
        iat: Time.current.to_i,
        jti: SecureRandom.uuid
      }
      encode(payload)
    end

    # Verify token and return user
    def verify_token(token)
      return nil unless token.present?

      payload = decode(token)
      return nil unless payload

      # Check if token is expired
      return nil if payload["exp"] && Time.current.to_i > payload["exp"]

      # Find user by ID from token and eager load roles
      user = User.includes(:roles).find_by(id: payload["user_id"])
      return nil unless user&.active?

      # Update last login time (this might reload the user, so reload roles after)
      user.update_last_login!
      
      # Reload roles association if it was cleared by update_last_login!
      user.roles.reload unless user.association(:roles).loaded?

      user
    end

    # Extract token from Authorization header
    def extract_token(auth_header)
      return nil unless auth_header.present?

      # Handle "Bearer <token>" format
      auth_header.split(" ").last if auth_header.start_with?("Bearer ")
    end

    # Check if token is valid (not expired and user exists)
    def valid_token?(token)
      user = verify_token(token)
      user.present?
    end

    # Get user from token without updating last login
    def current_user_from_token(token)
      return nil unless token.present?

      payload = decode(token)
      return nil unless payload

      # Check if token is expired
      return nil if payload["exp"] && Time.current.to_i > payload["exp"]

      User.find_by(id: payload["user_id"])
    end
  end
end
