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
    # Legacy cookie-session JSON routes (/sessions) authenticate via session[:user_id], not JWT
    return false if legacy_session_json_route?

    # Authenticate if it's a JSON request and not the login endpoint
    json_request? && !login_endpoint?
  end

  # def should_authenticate_api_request?
  #   login_endpoint?
  # end

  def login_endpoint?
    request.path == "/api/v1/auth/login"
  end

  # POST /sessions, DELETE /sessions, GET /sessions/current — session-based API (not JWT)
  def legacy_session_json_route?
    return false unless json_request?

    case request.path
    when "/sessions"
      request.post? || request.delete?
    when "/sessions/current"
      request.get?
    else
      false
    end
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
      # Ensure roles are loaded and set current_user
      user.roles.load unless user.association(:roles).loaded?
      @current_user = user
      Rails.logger.info "JWT Authentication successful - User: #{user.id}, Email: #{user.email}, Roles: #{user.roles.pluck(:name).inspect}, @current_user set: #{@current_user.present?}"
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
