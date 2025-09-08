class TestController < ApplicationController
  def auth_test
    if current_user
      render json: {
        message: 'Authentication working',
        user: {
          id: current_user.id,
          email: current_user.email,
          roles: current_user.roles.pluck(:name),
          permissions: current_user.permissions.pluck(:name)
        }
      }
    else
      render json: { error: 'Not authenticated' }, status: :unauthorized
    end
  end
end
