class ApplicationController < ActionController::Base
  include Authorization
  include JwtAuthenticatable

  protect_from_forgery with: :null_session, if: -> { request.format.json? }

  # Skip CSRF protection for specific controllers
  skip_before_action :verify_authenticity_token, if: -> {
    controller_name.in?([ "leave_requests", "attendance_records" ]) && request.format.json?
  }
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  def current_user
    # For API requests, use JWT authentication
    if api_request?
      @current_user
    else
      # For web requests, use session-based authentication
      @current_user ||= User.find(session[:user_id]) if session[:user_id]
    end
  rescue ActiveRecord::RecordNotFound
    session[:user_id] = nil
    nil
  end

  def authenticate_user!
    unless current_user
      if api_request?
        render json: { error: "Authentication required" }, status: :unauthorized
      else
        # Handle case where Devise routes might not be available
        if respond_to?(:new_user_session_path)
          redirect_to new_user_session_path
        else
          render json: { error: "Authentication required" }, status: :unauthorized
        end
      end
    end
  end
end
