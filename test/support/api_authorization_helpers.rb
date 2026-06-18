# Helpers for JWT-authenticated API authorization tests
module ApiAuthorizationHelpers
  def without_authentication
    previous = @auth_headers
    @auth_headers = {}
    yield
  ensure
    @auth_headers = previous
  end

  def sign_in_as(user)
    @auth_user = user
    @auth_headers = auth_headers_for(user)
  end

  def assert_json_unauthorized
    assert_response :unauthorized
    body = json_response
    assert body["error"].present?, "expected error message in #{body.inspect}"
  end

  def assert_json_forbidden
    assert_response :forbidden
    body = json_response
    error = body["error"] || body["errors"]
    assert error.present?, "expected error in #{body.inspect}"
  end

  def grant_permissions_to_role(role, *permission_names)
    permission_names.flatten.each do |name|
      resource, action = name.split(".", 2)
      perm = Permission.find_or_create_by!(name: name) do |p|
        p.resource = resource
        p.action = action
        p.description = name
      end
      RolePermission.find_or_create_by!(role: role, permission: perm)
    end
    role.reload
  end

  def create_role_with_permissions(*permission_names, role_name: nil, company: nil)
    company ||= ActsAsTenant.current_tenant || companies(:one)
    role = Role.create!(
      name: role_name || "TestRole #{SecureRandom.hex(4)}",
      description: "Role for API authorization tests",
      company: company
    )
    grant_permissions_to_role(role, *permission_names)
    role
  end

  def create_api_user(permissions: [], employee: nil, email: nil, roles: [])
    company = employee&.company || ActsAsTenant.current_tenant || companies(:one)
    user = User.create!(
      email: email || "api.user.#{SecureRandom.hex(4)}@test.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      first_name: "API",
      last_name: "User",
      status: "active",
      employee_id: employee&.id,
      company: company
    )

    if permissions.present?
      role = create_role_with_permissions(*permissions)
      user.roles << role unless user.roles.include?(role)
    end

    roles.each do |role|
      user.roles << role unless user.roles.include?(role)
    end

    user.reload
  end

  def employee_self_service_permissions
    %w[
      attendance_records.index
      leave_requests.index
      leave_requests.create
      leave_requests.cancel
    ]
  end

  def hr_attendance_leave_permissions
    employee_self_service_permissions + %w[
      leave_management.index
      attendance_records.approve
      leave_requests.approve
      leave_requests.reject
    ]
  end

  def setup_manager_team!
    @manager_employee = employees(:two)
    @report_employee = employees(:one)
    @report_employee.update!(manager: @manager_employee)

    # Manager relies on direct-report relationship for approve/reject (no HR approve permission)
    @manager_user = create_api_user(
      permissions: employee_self_service_permissions,
      employee: @manager_employee,
      email: "manager.#{SecureRandom.hex(4)}@test.com"
    )

    @employee_user = create_api_user(
      permissions: employee_self_service_permissions,
      employee: @report_employee,
      email: "employee.#{SecureRandom.hex(4)}@test.com"
    )

    @hr_user = create_api_user(
      permissions: hr_attendance_leave_permissions,
      email: "hr.#{SecureRandom.hex(4)}@test.com"
    )
  end

  def future_leave_attributes(employee_id, overrides = {})
    {
      employee_id: employee_id,
      leave_type: "annual",
      start_date: Date.current + 2.weeks,
      end_date: Date.current + 3.weeks,
      reason: "Planned time off",
      status: "pending"
    }.merge(overrides)
  end
end

class ActionDispatch::IntegrationTest
  include ApiAuthorizationHelpers
end
