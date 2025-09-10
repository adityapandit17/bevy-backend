class Api::V1::AuthController < ApplicationController
  # Skip CSRF protection for API endpoints
  skip_before_action :verify_authenticity_token
  before_action :authenticate_user!, only: [ :logout, :refresh, :me ]

  # POST /api/v1/auth/login
  def login
    email = params[:email]&.downcase
    password = params[:password]

    # Validate required parameters
    if email.blank? || password.blank?
      return render_error("Email and password are required", :bad_request)
    end

    # Find user by email
    user = User.find_by(email: email)

    # Authenticate user with Devise
    if user&.valid_password?(password) && user.active?
      # Generate JWT token
      token = JwtService.generate_token(user)

      # Update last login time
      user.update_last_login!

      render_success({
        token: token,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          first_name: user.first_name,
          last_name: user.last_name,
          status: user.status,
          roles: user.roles.pluck(:name),
          permissions: user.permissions.pluck(:resource, :action).map { |r, a| "#{r}:#{a}" },
          last_login_at: user.last_login_at
        }
      })
    else
      render_error("Invalid email or password", :unauthorized)
    end
  end

  # POST /api/v1/auth/logout
  def logout
    # In a stateless JWT system, logout is handled client-side
    # by removing the token. However, we can log the logout event
    Rails.logger.info "User #{current_user.email} logged out"

    render_success({ message: "Logged out successfully" })
  end

  # POST /api/v1/auth/refresh
  def refresh
    # Generate a new token for the current user
    token = JwtService.generate_token(current_user)

    render_success({
      token: token,
      user: {
        id: current_user.id,
        email: current_user.email,
        name: current_user.name,
        first_name: current_user.first_name,
        last_name: current_user.last_name,
        status: current_user.status,
        roles: current_user.roles.pluck(:name),
        permissions: current_user.permissions.pluck(:resource, :action).map { |r, a| "#{r}:#{a}" },
        last_login_at: current_user.last_login_at
      }
    })
  end

  # GET /api/v1/auth/me
  def me
    render_success({
      user: {
        id: current_user.id,
        email: current_user.email,
        name: current_user.name,
        first_name: current_user.first_name,
        last_name: current_user.last_name,
        status: current_user.status,
        roles: current_user.roles.pluck(:name),
        permissions: current_user.permissions.pluck(:resource, :action).map { |r, a| "#{r}:#{a}" },
        last_login_at: current_user.last_login_at,
        created_at: current_user.created_at,
        updated_at: current_user.updated_at
      }
    })
  end

  # POST /api/v1/auth/validate
  def validate
    token = JwtService.extract_token(request.headers["Authorization"])

    if token.blank?
      return render_error("Authorization token is required", :unauthorized)
    end

    user = JwtService.verify_token(token)

    if user
      render_success({
        valid: true,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          roles: user.roles.pluck(:name)
        }
      })
    else
      render_error("Invalid or expired token", :unauthorized)
    end
  end

  private

  def render_success(data, status = :ok)
    render json: {
      success: true,
      data: data
    }, status: status
  end

  def render_error(message, status = :unprocessable_entity)
    render json: {
      success: false,
      error: message
    }, status: status
  end
end
