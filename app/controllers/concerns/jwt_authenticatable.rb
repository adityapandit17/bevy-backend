module JwtAuthenticatable
  extend ActiveSupport::Concern

  included do
    # Skip CSRF protection for API endpoints
    skip_before_action :verify_authenticity_token, if: :api_request?

    # Set current user from JWT token (skip for login endpoint)
    before_action :authenticate_user_from_token!, unless: :login_endpoint?
  end

  private

  def api_request?
    request.path.start_with?("/api/")
  end

  # def should_authenticate_api_request?
  #   login_endpoint?
  # end

  def login_endpoint?
    request.path == "/api/v1/auth/login"
  end

  def authenticate_user_from_token!
    token = JwtService.extract_token(request.headers["Authorization"])

    if token.blank?
      render_unauthorized("Authorization token is required")
      return
    end

    user = JwtService.verify_token(token)

    if user
      @current_user = user
    else
      render_unauthorized("Invalid or expired token")
    end
  end

  def current_user
    @current_user
  end

  def user_signed_in?
    current_user.present?
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
