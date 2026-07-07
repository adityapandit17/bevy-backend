module JwtAuthenticatable
  extend ActiveSupport::Concern

  included do
    # Skip CSRF protection for API endpoints
    skip_before_action :verify_authenticity_token, if: :json_request?

    # Set current user from JWT token (skip for public endpoints)
    before_action :authenticate_user_from_token!, if: :should_authenticate?
    # Enforce authentication on all non-exempt routes (covers non-JSON bypass)
    before_action :authenticate_user!, unless: :authentication_exempt?
  end

  private

  def api_request?
    request.path.start_with?("/api/")
  end

  def json_request?
    request.format.json? || request.headers["Accept"]&.include?("application/json")
  end

  def bearer_authenticated_request?
    JwtService.extract_token(request.headers["Authorization"]).present?
  end

  def should_authenticate?
    return false if authentication_exempt?

    api_request? || json_request? || bearer_authenticated_request?
  end

  def authentication_exempt?
    return true if public_auth_endpoint?
    return true if platform_api_path?
    return true if infrastructure_path?
    return true if uploads_public_action?

    false
  end

  def public_auth_endpoint?
    request.path == "/api/v1/auth/login" ||
      request.path == "/api/v1/auth/accept_invitation" ||
      request.path == "/api/v1/auth/forgot_password" ||
      request.path == "/api/v1/auth/reset_password" ||
      request.path == "/api/v1/platform/auth/login" ||
      request.path == "/api/v1/public/signup" ||
      request.path == "/api/v1/public/pricing" ||
      request.path == "/api/v1/webhooks/payment/stripe" ||
      request.path == "/api/v1/google_calendar/callback" ||
      request.path.start_with?("/api/v1/public/")
  end

  def platform_api_path?
    request.path.start_with?("/api/v1/platform/")
  end

  def infrastructure_path?
    request.path == "/up" ||
      request.path.start_with?("/cable") ||
      request.path.start_with?("/jobs")
  end

  def uploads_public_action?
    controller_path == "uploads" && action_name.in?(%w[show options])
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
