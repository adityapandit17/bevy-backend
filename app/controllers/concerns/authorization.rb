module Authorization
  extend ActiveSupport::Concern

  private

  def authorize!(resource, action)
    unless current_user&.has_permission?(resource, action)
      render json: { error: "Insufficient permissions" }, status: :forbidden
    end
  end

  def authorize_role!(role_name)
    unless current_user&.has_role?(role_name)
      render json: { error: "Insufficient role permissions" }, status: :forbidden
    end
  end

  def require_super_admin!
    authorize_role!("Super Admin")
  end

  def require_hr_manager!
    authorize_role!("HR Manager")
  end

  def require_department_head!
    authorize_role!("Department Head")
  end

  def can_access_employee_data?(employee_id)
    return true if current_user.has_role?("Super Admin") || current_user.has_role?("HR Manager")
    return true if current_user.employee_id == employee_id.to_i
    return true if current_user.has_role?("Department Head") &&
                  current_user.employee&.department_id == Employee.find(employee_id).department_id
    false
  end
end
