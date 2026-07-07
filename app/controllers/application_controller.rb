class ApplicationController < ActionController::Base
  include Authorization
  include JwtAuthenticatable
  include SetCurrentTenant

  # Skip CSRF protection for API endpoints and JSON requests (JWT auth, no cookie-based sessions).
  # Include Content-Type check: requests with application/json are API clients even when format is */*
  skip_before_action :verify_authenticity_token, if: -> {
    request.path.start_with?("/api/") ||
    request.format.json? ||
    request.headers["Accept"]&.include?("application/json") ||
    request.headers["Content-Type"]&.include?("application/json")
  }

  # Only enable CSRF protection for non-API, non-JSON requests
  # In development, CSRF protection is disabled entirely
  protect_from_forgery with: :exception, unless: -> {
    Rails.env.development? ||
    request.path.start_with?("/api/") ||
    request.format.json? ||
    request.headers["Accept"]&.include?("application/json") ||
    request.headers["Content-Type"]&.include?("application/json")
  }
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  def current_user
    # For JSON requests, @current_user is set by JwtAuthenticatable concern's authenticate_user_from_token!
    # For web requests, use session-based authentication
    if request.format.json?
      @current_user
    else
      @current_user ||= User.find(session[:user_id]) if session[:user_id]
    end
  rescue ActiveRecord::RecordNotFound
    session[:user_id] = nil
    nil
  end

  def authenticate_user!
    return if @current_user.present?

    # Legacy session fallback (API-only app; JWT is primary)
    if session[:user_id].present?
      user = User.find_by(id: session[:user_id])
      if user&.active?
        @current_user = user
        return
      end
      session[:user_id] = nil
    end

    render json: { success: false, error: "Authentication required" }, status: :unauthorized
  end

  def json_request?
    request.format.json? || request.headers["Accept"]&.include?("application/json")
  end
end
