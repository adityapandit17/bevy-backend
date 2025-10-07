class PermissionsController < ApplicationController
  before_action :set_permission, only: [ :show, :update, :destroy ]
  # before_action :authorize_permissions_access!

  # GET /permissions
  def index
    @permissions = Permission.all

    # Group by resource for better organization
    grouped_permissions = @permissions.group_by(&:resource)

    render json: {
      permissions: @permissions.map { |permission| format_permission(permission) },
      grouped_permissions: grouped_permissions.transform_values { |perms| perms.map { |p| format_permission(p) } },
      total_count: @permissions.size
    }
  end

  # GET /permissions/:id
  def show
    render json: {
      permission: format_permission(@permission),
      roles: @permission.roles.map { |role| format_role(role) }
    }
  end

  # POST /permissions
  def create
    @permission = Permission.new(permission_params)

    if @permission.save
      render json: {
        message: "Permission created successfully",
        permission: format_permission(@permission)
      }, status: :created
    else
      render json: {
        error: "Failed to create permission",
        errors: @permission.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /permissions/:id
  def update
    if @permission.update(permission_params)
      render json: {
        message: "Permission updated successfully",
        permission: format_permission(@permission)
      }
    else
      render json: {
        error: "Failed to update permission",
        errors: @permission.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /permissions/:id
  def destroy
    if @permission.destroy
      render json: { message: "Permission deleted successfully" }
    else
      render json: {
        error: "Failed to delete permission",
        errors: @permission.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def set_permission
    @permission = Permission.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Permission not found" }, status: :not_found
  end

  def authorize_permissions_access!
    case action_name
    when "index", "show"
      authorize!("permissions", "index")
    when "create"
      authorize!("permissions", "create")
    when "update"
      authorize!("permissions", "update")
    when "destroy"
      authorize!("permissions", "destroy")
    end
  end

  def permission_params
    params.require(:permission).permit(:name, :resource, :action, :description)
  end

  def format_permission(permission)
    {
      id: permission.id,
      name: permission.name,
      resource: permission.resource,
      action: permission.action,
      description: permission.description,
      resource_action: permission.resource_action,
      created_at: permission.created_at,
      updated_at: permission.updated_at
    }
  end

  def format_role(role)
    {
      id: role.id,
      name: role.name,
      description: role.description
    }
  end
end
