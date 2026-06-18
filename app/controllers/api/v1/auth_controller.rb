class Api::V1::AuthController < ApplicationController
  # Skip CSRF protection for API endpoints
  skip_before_action :verify_authenticity_token
  before_action :authenticate_user!, only: [ :logout, :refresh, :me, :change_password ]

  # POST /api/v1/auth/login
  def login
    email = params[:email]&.downcase&.strip
    password = params[:password]
    company_code = params[:company_code]&.upcase&.strip

    # Validate required parameters
    if email.blank? || password.blank?
      return render_error("Email and password are required", :bad_request)
    end

    user = find_user_for_login(email, company_code)

    if user.nil? && company_code.blank? && User.unscoped.where(email: email).count > 1
      return render_error("Company code is required for this email", :unauthorized)
    end

    # Authenticate user with Devise
    if user&.valid_password?(password) && user.active?
      token = JwtService.generate_token(user)
      user.update_last_login!

      render_success({
        token: token,
        user: user_payload(user),
        company: company_payload(user.company)
      })
    else
      render_error("Invalid email or password", :unauthorized)
    end
  end

  # POST /api/v1/auth/forgot_password
  # Sends reset instructions to the user's email (always returns success to avoid enumeration).
  def forgot_password
    email = params[:email]&.downcase&.strip

    if email.blank?
      return render_error("Email is required", :bad_request)
    end

    user = User.find_by(email: email)
    if user&.active?
      raw_token = user.send(:set_reset_password_token)
      PasswordResetMailer.reset_password_email(user, raw_token).deliver_now
    end

    render_success({
      message: "If an account exists for that email, you will receive password reset instructions shortly."
    })
  end

  # POST /api/v1/auth/reset_password
  # Completes Devise recoverable flow using the raw token from the reset link (frontend flow).
  def reset_password
    token = params[:reset_password_token].presence
    password = params[:password].presence
    password_confirmation = params[:password_confirmation].presence || password

    if token.blank? || password.blank?
      return render_error("Reset token and password are required", :bad_request)
    end

    if password != password_confirmation
      return render_error("Password and confirmation do not match", :bad_request)
    end

    user = User.reset_password_by_token(
      reset_password_token: token,
      password: password,
      password_confirmation: password_confirmation
    )

    if user.errors.any?
      return render_error(user.errors.full_messages.join(", "), :unprocessable_entity)
    end

    unless user.active?
      return render_error("Your account is not active. Please contact HR.", :forbidden)
    end

    jwt = JwtService.generate_token(user)
    user.update_last_login!

    render_success({
      token: jwt,
      message: "Password reset successfully",
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        first_name: user.first_name,
        last_name: user.last_name,
        status: user.status,
        roles: user.roles.pluck(:name),
        permissions: user.permissions.pluck(:resource, :action).map { |r, a| "#{r}:#{a}" },
        last_login_at: user.last_login_at,
        employee_id: user.employee_id
      }
    })
  end

  # POST /api/v1/auth/accept_invitation
  # Completes Devise Invitable signup using the raw token from the invitation link (frontend flow).
  def accept_invitation
    token = params[:invitation_token].presence
    password = params[:password].presence
    password_confirmation = params[:password_confirmation].presence || password
    first_name = params[:first_name].presence
    last_name = params[:last_name].presence

    if token.blank? || password.blank?
      return render_error("Invitation token and password are required", :bad_request)
    end

    if password != password_confirmation
      return render_error("Password and confirmation do not match", :bad_request)
    end

    attrs = {
      invitation_token: token,
      password: password,
      password_confirmation: password_confirmation
    }
    attrs[:first_name] = first_name if first_name
    attrs[:last_name] = last_name if last_name

    user = User.accept_invitation!(attrs)

    if user.errors.any?
      return render_error(user.errors.full_messages.join(", "), :unprocessable_entity)
    end

    unless user.active?
      return render_error("Your account is not active. Please contact HR.", :forbidden)
    end

    jwt = JwtService.generate_token(user)
    user.update_last_login!

    render_success({
      token: jwt,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        first_name: user.first_name,
        last_name: user.last_name,
        status: user.status,
        roles: user.roles.pluck(:name),
        permissions: user.permissions.pluck(:resource, :action).map { |r, a| "#{r}:#{a}" },
        last_login_at: user.last_login_at,
        employee_id: user.employee_id
      }
    })
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
        last_login_at: current_user.last_login_at,
        employee_id: current_user.employee_id
      }
    })
  end

  # GET /api/v1/auth/me
  def me
    render_success({
      user: user_payload(current_user),
      company: company_settings_payload
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

  # POST /api/v1/auth/change_password
  def change_password
    current_password = params[:current_password]
    new_password = params[:new_password]
    confirm_password = params[:confirm_password]

    # Validate required parameters
    if current_password.blank? || new_password.blank? || confirm_password.blank?
      return render_error("Current password, new password, and confirmation are required", :bad_request)
    end

    # Validate password confirmation
    if new_password != confirm_password
      return render_error("New password and confirmation do not match", :bad_request)
    end

    # Validate password length
    if new_password.length < 8
      return render_error("Password must be at least 8 characters long", :bad_request)
    end

    # Verify current password
    unless current_user.valid_password?(current_password)
      return render_error("Current password is incorrect", :unauthorized)
    end

    # Update password
    if current_user.update(password: new_password, password_confirmation: confirm_password)
      render_success({ message: "Password changed successfully" })
    else
      errors = current_user.errors.full_messages.join(", ")
      render_error("Failed to change password: #{errors}", :unprocessable_entity)
    end
  end

  private

  def user_payload(user)
    {
      id: user.id,
      email: user.email,
      name: user.name,
      first_name: user.first_name,
      last_name: user.last_name,
      status: user.status,
      company_id: user.company_id,
      roles: user.roles.pluck(:name),
      permissions: user.permissions.pluck(:resource, :action).map { |r, a| "#{r}:#{a}" },
      last_login_at: user.last_login_at,
      created_at: user.created_at,
      updated_at: user.updated_at,
      employee_id: user.employee_id
    }
  end

  def company_settings_payload
    company_payload(current_user.company)
  end

  def company_payload(company)
    return {} unless company

    Company.dashboard_layout_for(company).then do |layout|
      company.settings_json.merge(dashboard_layout: layout)
    end
  end

  def find_user_for_login(email, company_code)
    scope = User.unscoped.includes(:company).where(email: email)

    if company_code.present?
      scope.joins(:company).find_by(companies: { code: company_code })
    else
      matches = scope.to_a
      matches.size == 1 ? matches.first : nil
    end
  end

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
