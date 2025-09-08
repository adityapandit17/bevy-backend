class RolesController < ApplicationController
  before_action :set_role, only: [:show, :update, :destroy]
  before_action :authorize_roles_access!

  # GET /roles
  def index
    @roles = Role.includes(:permissions, :users)
    
    render json: {
      roles: @roles.map { |role| format_role(role) },
      total_count: @roles.count
    }
  end

  # GET /roles/:id
  def show
    render json: {
      role: format_role(@role),
      permissions: @role.permissions.map { |permission| format_permission(permission) },
      users: @role.users.map { |user| format_user(user) }
    }
  end

  # POST /roles
  def create
    @role = Role.new(role_params)
    
    if @role.save
      # Assign permissions if provided
      if params[:permission_ids].present?
        @role.permission_ids = params[:permission_ids]
      end
      
      render json: {
        message: 'Role created successfully',
        role: format_role(@role)
      }, status: :created
    else
      render json: {
        message: 'Failed to create role',
        errors: @role.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /roles/:id
  def update
    if @role.update(role_params)
      # Update permissions if provided
      if params[:permission_ids].present?
        @role.permission_ids = params[:permission_ids]
      end
      
      render json: {
        message: 'Role updated successfully',
        role: format_role(@role)
      }
    else
      render json: {
        message: 'Failed to update role',
        errors: @role.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /roles/:id
  def destroy
    if @role.users.any?
      render json: { error: 'Cannot delete role with assigned users' }, status: :unprocessable_entity
      return
    end
    
    @role.destroy
    render json: { message: 'Role deleted successfully' }
  end

  # PATCH /roles/:id/update_permissions
  def update_permissions
    @role = Role.find(params[:id])
    
    if @role.update(permission_ids: params[:permission_ids])
      render json: {
        message: 'Role permissions updated successfully',
        role: format_role(@role)
      }
    else
      render json: {
        message: 'Failed to update role permissions',
        errors: @role.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def set_role
    @role = Role.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Role not found' }, status: :not_found
  end

  def role_params
    params.require(:role).permit(:name, :description)
  end

  def authorize_roles_access!
    authorize!('roles', 'index')
  end

  def format_role(role)
    {
      id: role.id,
      name: role.name,
      description: role.description,
      user_count: role.users.count,
      permission_count: role.permissions.count,
      created_at: role.created_at,
      updated_at: role.updated_at
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

  def format_user(user)
    {
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      name: user.name,
      status: user.status
    }
  end
end
