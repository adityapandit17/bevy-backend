class UsersController < ApplicationController
  include ActiveStorageUrlHelper

  before_action :authenticate_user!
  before_action :set_user, only: [ :show, :update, :destroy, :change_password, :update_profile, :preferences, :update_preferences ]
  before_action :authorize_users_access!, except: [ :change_password, :update_profile, :preferences, :update_preferences ]

  # GET /users
  def index
    @users = User.includes(:roles, :employee)

    # Apply filters
    @users = @users.where(status: params[:status]) if params[:status].present?
    @users = @users.joins(:roles).where(roles: { name: params[:role] }) if params[:role].present?

    # Search functionality
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @users = @users.where(
        "users.first_name ILIKE ? OR users.last_name ILIKE ? OR users.email ILIKE ?",
        search_term, search_term, search_term
      )
    end

    @users = @users.order(:first_name, :last_name)

    render json: {
      users: @users.map { |user| format_user(user) },
      total_count: @users.size,
      roles: Role.all.map { |role| { id: role.id, name: role.name, description: role.description } }
    }
  end

  # GET /users/:id
  def show
    render json: {
      user: format_user(@user),
      roles: @user.roles.map { |role| { id: role.id, name: role.name, description: role.description } },
      permissions: @user.permissions.map { |permission| format_permission(permission) }
    }
  end

  # POST /users
  def create
    @user = User.new(user_params)

    if @user.save
      # Assign roles if provided
      if params[:role_ids].present?
        @user.role_ids = params[:role_ids]
      end

      render json: {
        message: "User created successfully",
        user: format_user(@user)
      }, status: :created
    else
      render json: {
        message: "Failed to create user",
        errors: @user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /users/:id
  def update
    if @user.update(user_params)
      # Update roles if provided
      if params[:role_ids].present?
        @user.role_ids = params[:role_ids]
      end

      render json: {
        message: "User updated successfully",
        user: format_user(@user)
      }
    else
      render json: {
        message: "Failed to update user",
        errors: @user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /users/:id
  def destroy
    if @user == current_user
      render json: { error: "Cannot delete your own account" }, status: :unprocessable_entity
      return
    end

    @user.destroy
    render json: { message: "User deleted successfully" }
  end

  # PATCH /users/:id/update_roles
  def update_roles
    @user = User.find(params[:id])

    if @user.update(role_ids: params[:role_ids])
      render json: {
        message: "User roles updated successfully",
        user: format_user(@user)
      }
    else
      render json: {
        message: "Failed to update user roles",
        errors: @user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # POST /users/:id/invite
  def invite
    @user = User.find(params[:id])

    if @user.invited_to_sign_up?
      render json: { error: "User has already been invited" }, status: :unprocessable_entity
      return
    end

    if @user.invite!(current_user)
      render json: {
        message: "Invitation sent successfully",
        user: format_user(@user)
      }
    else
      render json: {
        message: "Failed to send invitation",
        errors: @user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH /users/:id/resend_invitation
  def resend_invitation
    @user = User.find(params[:id])

    unless @user.invited_to_sign_up?
      render json: { error: "User has not been invited yet" }, status: :unprocessable_entity
      return
    end

    if @user.invite!(current_user)
      render json: {
        message: "Invitation resent successfully",
        user: format_user(@user)
      }
    else
      render json: {
        message: "Failed to resend invitation",
        errors: @user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # GET /users/invitations
  def invitations
    @invited_users = User.invitation_not_accepted.includes(:roles, :invited_by)

    render json: {
      invitations: @invited_users.map { |user| format_invitation(user) },
      total_count: @invited_users.count
    }
  end

  # PATCH /users/:id/change_password
  def change_password
    unless @user == current_user
      render json: { error: "You can only change your own password" }, status: :forbidden
      return
    end

    current_password = params[:current_password]
    new_password = params[:new_password]
    confirm_password = params[:confirm_password]

    # Validate current password
    unless @user.valid_password?(current_password)
      render json: { error: "Current password is incorrect" }, status: :unprocessable_entity
      return
    end

    # Validate new password
    if new_password.blank? || new_password.length < 8
      render json: { error: "New password must be at least 8 characters long" }, status: :unprocessable_entity
      return
    end

    if new_password != confirm_password
      render json: { error: "New password and confirmation do not match" }, status: :unprocessable_entity
      return
    end

    # Update password
    if @user.update(password: new_password, password_confirmation: confirm_password)
      render json: { message: "Password changed successfully" }
    else
      render json: { error: "Failed to change password", errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /users/:id/profile
  def update_profile
    unless @user == current_user
      render json: { error: "You can only update your own profile" }, status: :forbidden
      return
    end

    @user.assign_attributes(profile_params) if params[:user].present?

    begin
      handle_avatar_on_update
    rescue ArgumentError => e
      render json: { error: e.message }, status: :unprocessable_entity
      return
    end

    if @user.save
      render json: {
        message: "Profile updated successfully",
        user: format_user(@user)
      }
    else
      render json: {
        message: "Failed to update profile",
        errors: @user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # GET /users/:id/preferences
  def preferences
    unless @user == current_user
      render json: { error: "You can only view your own preferences" }, status: :forbidden
      return
    end

    pref = UserPreference.for_user(@user)
    render json: format_preferences(pref)
  end

  # PATCH /users/:id/preferences
  def update_preferences
    unless @user == current_user
      render json: { error: "You can only update your own preferences" }, status: :forbidden
      return
    end

    pref = UserPreference.for_user(@user)
    if pref.update(preference_params)
      render json: {
        message: "Preferences updated successfully",
        preferences: format_preferences(pref)
      }
    else
      render json: {
        message: "Failed to update preferences",
        errors: pref.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "User not found" }, status: :not_found
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name, :status, :employee_id)
  end

  def profile_params
    return {} unless params[:user].present?

    params.require(:user).permit(:first_name, :last_name)
  end

  def handle_avatar_on_update
    if ActiveModel::Type::Boolean.new.cast(params[:remove_avatar])
      @user.remove_avatar!
    elsif params[:avatar].present?
      @user.attach_avatar!(params[:avatar])
    end
  end

  def preference_params
    params.require(:preferences).permit(
      :language, :timezone, :date_format, :theme,
      :email_notifications, :push_notifications, :leave_notifications,
      :attendance_notifications, :payroll_notifications, :system_notifications
    )
  end

  def format_preferences(pref)
    {
      id: pref.id,
      language: pref.language,
      timezone: pref.timezone,
      date_format: pref.date_format,
      theme: pref.theme,
      email_notifications: pref.email_notifications,
      push_notifications: pref.push_notifications,
      leave_notifications: pref.leave_notifications,
      attendance_notifications: pref.attendance_notifications,
      payroll_notifications: pref.payroll_notifications,
      system_notifications: pref.system_notifications,
      created_at: pref.created_at,
      updated_at: pref.updated_at
    }
  end

  def authorize_users_access!
    authorize!("users", "index")
  end

  def format_user(user)
    {
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      name: user.name,
      avatar_url: user.avatar_url,
      status: user.status,
      last_login_at: user.last_login_at,
      employee: user.employee ? {
        id: user.employee.id,
        name: user.employee.name,
        department: user.employee.department&.name
      } : nil,
      roles: user.roles.map { |role| { id: role.id, name: role.name, description: role.description } },
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end

  def format_permission(permission)
    {
      id: permission.id,
      name: permission.name,
      resource: permission.resource,
      action: permission.action,
      description: permission.description
    }
  end

  def format_invitation(user)
    {
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      name: user.name,
      status: user.status,
      invitation_sent_at: user.invitation_sent_at,
      invitation_accepted_at: user.invitation_accepted_at,
      invited_by: user.invited_by ? {
        id: user.invited_by.id,
        name: user.invited_by.name,
        email: user.invited_by.email
      } : nil,
      roles: user.roles.map { |role| { id: role.id, name: role.name, description: role.description } },
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end
end
