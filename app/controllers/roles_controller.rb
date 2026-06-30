class RolesController < ApplicationController
  before_action :set_role, only: [ :show, :update, :destroy ]
  # before_action :authorize_roles_access!

  def index
    company = current_company
    @roles = Role.assignable_for(company).includes(:permissions)
    role_ids = @roles.map(&:id)
    user_counts = User.joins(:user_roles)
                      .where(user_roles: { role_id: role_ids })
                      .where(company_id: company.id)
                      .group("user_roles.role_id")
                      .count

    render json: {
      roles: @roles.map { |role| format_role(role, user_count: user_counts[role.id] || 0) },
      total_count: @roles.size
    }
  end

  def show
    company_users = @role.users_in_company(current_company)

    render json: {
      role: format_role(@role, user_count: company_users.size),
      permissions: @role.permissions.map { |permission| format_permission(permission) },
      users: company_users.map { |user| format_user(user) }
    }
  end

  def create
    @role = Role.new(role_params)

    if @role.save
      # Assign permissions if provided
      if params[:permission_ids].present?
        @role.permission_ids = params[:permission_ids]
      end

      render json: {
        message: "Role created successfully",
        role: format_role(@role)
      }, status: :created
    else
      render json: {
        message: "Failed to create role",
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
        message: "Role updated successfully",
        role: format_role(@role)
      }
    else
      render json: {
        message: "Failed to update role",
        errors: @role.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /roles/:id
  def destroy
    if @role.users_in_company(current_company).any?
      render json: { error: "Cannot delete role with assigned users" }, status: :unprocessable_entity
      return
    end

    @role.destroy
    render json: { message: "Role deleted successfully" }
  end

  # PATCH /roles/:id/update_permissions
  def update_permissions
    @role = Role.find(params[:id])

    if @role.update(permission_ids: params[:permission_ids])
      render json: {
        message: "Role permissions updated successfully",
        role: format_role(@role)
      }
    else
      render json: {
        message: "Failed to update role permissions",
        errors: @role.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # GET /roles/:id/permissions_matrix
  # Returns all permissions with granted flag for this role, grouped by resource
  def permissions_matrix
    role = Role.includes(:role_permissions).find(params[:id])
    permissions = Permission.all
    granted_id_set = role.role_permissions.pluck(:permission_id).to_set

    serialized = permissions.map do |p|
      {
        id: p.id,
        name: p.name,
        resource: p.resource,
        action: p.action,
        description: p.description,
        granted: granted_id_set.include?(p.id)
      }
    end

    render json: {
      role: {
        id: role.id,
        name: role.name,
        description: role.description
      },
      permissions: serialized,
      grouped_permissions: serialized.group_by { |p| p[:resource] }
    }
  end

  # PATCH /roles/:id/toggle_permission
  # Params: permission_id OR resource+action
  def toggle_permission
    role = Role.find(params[:id])

    permission = if params[:permission_id].present?
      Permission.find_by(id: params[:permission_id])
    elsif params[:resource].present? && params[:action_name].present?
      Permission.find_by(resource: params[:resource], action: params[:action_name])
    end

    unless permission
      render json: { error: "Permission not found" }, status: :not_found and return
    end

    if role.permissions.exists?(id: permission.id)
      role.permissions.delete(permission)
      granted = false
    else
      role.permissions << permission
      granted = true
    end

    render json: { message: "Permission toggled", permission_id: permission.id, granted: granted }
  end

  # POST /roles/:id/add_default_module_permissions
  # Params: resource (module name)
  def add_default_module_permissions
    role = Role.find(params[:id])
    resource = params[:resource].to_s
    if resource.blank?
      render json: { error: "resource is required" }, status: :unprocessable_entity and return
    end

    default_actions = %w[index create update destroy]
    added = []

    default_actions.each do |action|
      name = "#{resource}.#{action}"
      permission = Permission.find_or_create_by!(name: name) do |p|
        p.resource = resource
        p.action = action
        p.description = "#{action.capitalize} #{resource.humanize}"
      end
      unless role.permissions.exists?(id: permission.id)
        role.permissions << permission
        added << permission.id
      end
    end

    render json: {
      message: "Default permissions added",
      added_permission_ids: added
    }
  end

  # POST /roles/:id/add_permission
  # Params: resource, action, description (optional)
  def add_permission
    role = Role.find(params[:id])
    resource = params[:resource].to_s
    action = params[:action_name].to_s
    description = params[:description].to_s.presence

    if resource.blank? || action.blank?
      render json: { error: "resource and action are required" }, status: :unprocessable_entity and return
    end

    name = "#{resource}.#{action}"
    permission = Permission.find_or_create_by!(name: name) do |p|
      p.resource = resource
      p.action = action
      p.description = description || "#{action.capitalize} #{resource.humanize}"
    end

    unless role.permissions.exists?(id: permission.id)
      role.permissions << permission
    end

    render json: {
      message: "Permission added",
      permission: {
        id: permission.id,
        name: permission.name,
        resource: permission.resource,
        action: permission.action,
        description: permission.description,
        granted: true
      }
    }
  end

  private

  def set_role
    @role = Role.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Role not found" }, status: :not_found
  end

  def role_params
    params.require(:role).permit(:name, :description)
  end

  def authorize_roles_access!
    authorize!("roles", "index")
  end

  def current_company
    ActsAsTenant.current_tenant || current_user&.company
  end

  def format_role(role, user_count: nil)
    user_count ||= role.users_in_company(current_company).count

    {
      id: role.id,
      name: role.name,
      description: role.description,
      user_count: user_count,
      permission_count: role.permissions.size,
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
