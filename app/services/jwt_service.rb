class JwtService
  # JWT secret key - in production, this should be stored in environment variables
  SECRET_KEY = Rails.application.credentials.secret_key_base || "your-secret-key"

  # Token expiration time (24 hours)
  EXPIRATION_TIME = 24.hours

  VerifiedToken = Struct.new(:user, :payload, keyword_init: true)

  class << self
    # Generate JWT token for a user
    def encode(payload, expires_in: EXPIRATION_TIME)
      payload = payload.dup
      payload[:exp] = expires_in.from_now.to_i
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
      encode(base_payload(user))
    end

    # Impersonation token — shorter TTL, carries impersonation claims
    def generate_impersonation_token(user, impersonator_id: nil, platform_admin_id: nil, expires_in: 2.hours)
      payload = base_payload(user).merge(imp: true)
      payload[:impersonator_id] = impersonator_id if impersonator_id.present?
      payload[:platform_admin_id] = platform_admin_id if platform_admin_id.present?
      encode(payload, expires_in: expires_in)
    end

    def impersonating?(payload)
      payload.present? && ActiveModel::Type::Boolean.new.cast(payload["imp"] || payload[:imp])
    end

    # Verify token and return user
    def verify_token(token)
      verify_token_details(token)&.user
    end

    def verify_token_details(token)
      return nil unless token.present?

      payload = decode(token)
      return nil unless payload
      return nil unless payload["aud"] == "tenant"

      # Check if token is expired
      return nil if payload["exp"] && Time.current.to_i > payload["exp"]

      # Find user by ID from token and eager load roles with permissions
      user = User.includes(:company, roles: :permissions).find_by(id: payload["user_id"])
      return nil unless user&.active?
      return nil if user.company_id.blank?

      token_company_id = payload["company_id"]
      return nil if token_company_id.present? && token_company_id.to_i != user.company_id

      # Throttle last-login writes — skip during impersonation so we don't pollute target's last_login
      unless impersonating?(payload)
        if user.last_login_at.nil? || user.last_login_at < 15.minutes.ago
          user.update_last_login!
        end
      end

      VerifiedToken.new(user: user, payload: payload)
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

    private

    def base_payload(user)
      {
        aud: "tenant",
        user_id: user.id,
        company_id: user.company_id,
        email: user.email,
        name: user.name,
        roles: user.roles.pluck(:name),
        iat: Time.current.to_i,
        jti: SecureRandom.uuid
      }
    end
  end
end
