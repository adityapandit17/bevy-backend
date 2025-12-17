module Authorization
  extend ActiveSupport::Concern

  private

  def authorize!(resource, action)
    unless current_user&.has_permission?(resource, action)
      render json: { error: "Insufficient permissions" }, status: :forbidden
      return
    end
  end

  def authorize_role!(role_name)
    unless current_user&.has_role?(role_name)
      render json: { error: "Insufficient role permissions" }, status: :forbidden
      return
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
    return false unless current_user

    return true if current_user.has_role?("Super Admin") || current_user.has_role?("HR Manager") || current_user.has_role?("HR")

    return true if current_user.employee_id == employee_id.to_i

    return true if current_user.has_role?("Department Head") &&
                  current_user.employee&.department_id == Employee.find(employee_id).department_id

    false
  end

  def can_apply_leave_for?(employee_id)
    return false unless current_user

    # Super Admin and HR Manager can apply for anyone
    return true if current_user.has_role?("Super Admin") || current_user.has_role?("HR Manager") || current_user.has_role?("HR")

    # Users with any leave_requests permission can apply for anyone (management access)
    return true if current_user.has_permission?("leave_requests", "create") ||
                  current_user.has_permission?("leave_requests", "approve") ||
                  current_user.has_permission?("leave_requests", "index")

    # Users can always apply for their own leave
    return true if current_user.employee_id == employee_id.to_i

    false
  end
end
