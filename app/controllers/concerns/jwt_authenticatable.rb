module JwtAuthenticatable
  extend ActiveSupport::Concern

  included do
    # Skip CSRF protection for API endpoints
    skip_before_action :verify_authenticity_token, if: :json_request?

    # Set current user from JWT token (skip for login endpoint and non-JSON requests)
    before_action :authenticate_user_from_token!, if: :should_authenticate?
  end

  private

  def api_request?
    request.path.start_with?("/api/")
  end

  def json_request?
    request.format.json? || request.headers["Accept"]&.include?("application/json")
  end

  def should_authenticate?
    # Authenticate if it's a JSON request and not a public auth endpoint
    json_request? && !public_auth_endpoint?
  end

  # def should_authenticate_api_request?
  #   login_endpoint?
  # end

  def public_auth_endpoint?
    request.path == "/api/v1/auth/login" ||
      request.path == "/api/v1/auth/accept_invitation" ||
      request.path == "/api/v1/auth/forgot_password" ||
      request.path == "/api/v1/auth/reset_password" ||
      request.path == "/api/v1/platform/auth/login" ||
      request.path == "/api/v1/public/signup" ||
      request.path.start_with?("/api/v1/public/")
  end

  # Backwards compatibility for controllers that still reference this name.
  def login_endpoint?
    public_auth_endpoint?
  end

  def authenticate_user_from_token!
    token = JwtService.extract_token(request.headers["Authorization"])

    if token.blank?
      Rails.logger.error "JWT Authentication failed: No token provided"
      render_unauthorized("Authorization token is required")
      return
    end

    user = JwtService.verify_token(token)

    if user
      @current_user = user
      Rails.logger.debug { "JWT auth OK user=#{user.id}" } if Rails.env.development?
    else
      Rails.logger.error "JWT Authentication failed: Invalid or expired token"
      render_unauthorized("Invalid or expired token")
    end
  end

  def user_signed_in?
    @current_user.present?
  end

  def authenticate_user!
    unless user_signed_in?
      render_unauthorized("Authentication required")
    end
  end

  def render_unauthorized(message = "Unauthorized")
    render json: {
      success: false,
      error: message
    }, status: :unauthorized
  end
end
