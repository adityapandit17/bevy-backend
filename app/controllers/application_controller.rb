class ApplicationController < ActionController::Base
  include Authorization
  include JwtAuthenticatable
  include TenantContext

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
    # Legacy GET /sessions/current uses session[:user_id] when JWT is not used (see JwtAuthenticatable#legacy_session_json_route?)
    # For web requests, use session-based authentication
    if request.format.json?
      return @current_user if @current_user.present?
      if session[:user_id].present? && request.get? && request.path == "/sessions/current"
        return @current_user_session ||= User.find_by(id: session[:user_id])
      end

      nil
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

  # Resolve a tenant model by id within Current.company (set by TenantContext).
  def find_in_tenant(model_class, id)
    model_class.for_current_company.find(id)
  end
end
