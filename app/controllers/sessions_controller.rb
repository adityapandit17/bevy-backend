class SessionsController < ApplicationController
  def create
    user = User.find_by(email: params[:email]&.downcase)
    
    if user&.valid_password?(params[:password])
      if user.active?
        session[:user_id] = user.id
        render json: {
          message: 'Login successful',
          user: format_user(user),
          roles: user.roles.map { |role| { id: role.id, name: role.name, description: role.description } },
          permissions: user.permissions.map { |permission| format_permission(permission) }
        }
      else
        render json: { error: 'Account is inactive' }, status: :unauthorized
      end
    else
      render json: { error: 'Invalid email or password' }, status: :unauthorized
    end
  end

  def destroy
    session[:user_id] = nil
    render json: { message: 'Logout successful' }
  end

  def current
    if current_user
      render json: {
        user: format_user(current_user),
        roles: current_user.roles.map { |role| { id: role.id, name: role.name, description: role.description } },
        permissions: current_user.permissions.map { |permission| format_permission(permission) }
      }
    else
      render json: { error: 'Not authenticated' }, status: :unauthorized
    end
  end

  private

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
