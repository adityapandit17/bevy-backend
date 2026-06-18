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
    # For API/JSON requests, JWT authentication is handled by authenticate_user_from_token!
    # So we just need to check if current_user is set
    return if @current_user.present? && request.format.json?

    unless current_user
      # For JSON requests, always return JSON error
      if json_request?
        render json: { success: false, error: "Authentication required" }, status: :unauthorized
      else
        # Handle case where Devise routes might not be available
        if respond_to?(:new_user_session_path)
          redirect_to new_user_session_path
        else
          render json: { success: false, error: "Authentication required" }, status: :unauthorized
        end
      end
    end
  end

  def json_request?
    request.format.json? || request.headers["Accept"]&.include?("application/json")
  end
end
