class UsersController < ApplicationController
  before_action :set_user, only: [ :show, :update, :destroy ]
  before_action :authorize_users_access!

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

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "User not found" }, status: :not_found
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name, :status, :employee_id)
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
end
