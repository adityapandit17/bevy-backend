require "test_helper"

class UserPermissionsTest < ActiveSupport::TestCase
  def setup
    # Create test roles
    @super_admin_role = Role.create!(name: "Super Admin", description: "Full system access")
    @hr_manager_role = Role.create!(name: "HR Manager", description: "HR management access")
    @employee_role = Role.create!(name: "Employee", description: "Basic employee access")
    @department_head_role = Role.create!(name: "Department Head", description: "Department management")

    # Create test permissions
    @employee_permissions = [
      Permission.create!(name: "employees.index", resource: "employees", action: "index", description: "View employees list"),
      Permission.create!(name: "employees.show", resource: "employees", action: "show", description: "View employee details"),
      Permission.create!(name: "employees.create", resource: "employees", action: "create", description: "Create employees"),
      Permission.create!(name: "employees.update", resource: "employees", action: "update", description: "Update employees"),
      Permission.create!(name: "employees.destroy", resource: "employees", action: "destroy", description: "Delete employees")
    ]

    @payroll_permissions = [
      Permission.create!(name: "payrolls.index", resource: "payrolls", action: "index", description: "View payroll list"),
      Permission.create!(name: "payrolls.create", resource: "payrolls", action: "create", description: "Create payroll records"),
      Permission.create!(name: "payrolls.update", resource: "payrolls", action: "update", description: "Update payroll records")
    ]

    @attendance_permissions = [
      Permission.create!(name: "attendance_records.index", resource: "attendance_records", action: "index", description: "View attendance records"),
      Permission.create!(name: "attendance_records.approve", resource: "attendance_records", action: "approve", description: "Approve attendance records")
    ]

    # Assign permissions to roles
    @super_admin_role.permissions = @employee_permissions + @payroll_permissions + @attendance_permissions
    @hr_manager_role.permissions = @employee_permissions + @payroll_permissions
    @department_head_role.permissions = @employee_permissions[0..2] + @attendance_permissions # Limited employee access + attendance approval
    @employee_role.permissions = [ @employee_permissions[0], @employee_permissions[1] ] # Only index and show

    # Create test users
    @super_admin = User.create!(
      email: "superadmin@test.com",
      password: "password123",
      first_name: "Super",
      last_name: "Admin",
      status: "active"
    )
    @super_admin.roles << @super_admin_role

    @hr_manager = User.create!(
      email: "hrmanager@test.com",
      password: "password123",
      first_name: "HR",
      last_name: "Manager",
      status: "active"
    )
    @hr_manager.roles << @hr_manager_role

    @department_head = User.create!(
      email: "depthead@test.com",
      password: "password123",
      first_name: "Department",
      last_name: "Head",
      status: "active"
    )
    @department_head.roles << @department_head_role

    @employee = User.create!(
      email: "employee@test.com",
      password: "password123",
      first_name: "Test",
      last_name: "Employee",
      status: "active"
    )
    @employee.roles << @employee_role

    @inactive_user = User.create!(
      email: "inactive@test.com",
      password: "password123",
      first_name: "Inactive",
      last_name: "User",
      status: "inactive"
    )
  end

  test "super admin has all permissions" do
    assert @super_admin.super_admin?
    assert @super_admin.has_permission?("employees", "index")
    assert @super_admin.has_permission?("employees", "create")
    assert @super_admin.has_permission?("employees", "update")
    assert @super_admin.has_permission?("employees", "destroy")
    assert @super_admin.has_permission?("payrolls", "index")
    assert @super_admin.has_permission?("payrolls", "create")
    assert @super_admin.has_permission?("attendance_records", "approve")
  end

  test "hr manager has employee and payroll permissions but not attendance approval" do
    assert @hr_manager.hr_manager?
    assert @hr_manager.has_permission?("employees", "index")
    assert @hr_manager.has_permission?("employees", "create")
    assert @hr_manager.has_permission?("employees", "update")
    assert @hr_manager.has_permission?("employees", "destroy")
    assert @hr_manager.has_permission?("payrolls", "index")
    assert @hr_manager.has_permission?("payrolls", "create")
    assert_not @hr_manager.has_permission?("attendance_records", "approve")
  end

  test "department head has limited employee access and attendance approval" do
    assert @department_head.department_head?
    assert @department_head.has_permission?("employees", "index")
    assert @department_head.has_permission?("employees", "show")
    assert @department_head.has_permission?("employees", "create")
    assert_not @department_head.has_permission?("employees", "update")
    assert_not @department_head.has_permission?("employees", "destroy")
    assert_not @department_head.has_permission?("payrolls", "index")
    assert @department_head.has_permission?("attendance_records", "approve")
  end

  test "employee has only read access to employees" do
    assert @employee.employee?
    assert @employee.has_permission?("employees", "index")
    assert @employee.has_permission?("employees", "show")
    assert_not @employee.has_permission?("employees", "create")
    assert_not @employee.has_permission?("employees", "update")
    assert_not @employee.has_permission?("employees", "destroy")
    assert_not @employee.has_permission?("payrolls", "index")
    assert_not @employee.has_permission?("attendance_records", "approve")
  end

  test "inactive user has no permissions" do
    assert @inactive_user.inactive?
    assert_not @inactive_user.has_permission?("employees", "index")
    assert_not @inactive_user.has_permission?("employees", "create")
    assert_not @inactive_user.has_permission?("payrolls", "index")
  end

  test "user with multiple roles gets combined permissions" do
    multi_role_user = User.create!(
      email: "multirole@test.com",
      password: "password123",
      first_name: "Multi",
      last_name: "Role",
      status: "active"
    )
    multi_role_user.roles << @hr_manager_role
    multi_role_user.roles << @department_head_role

    # Should have permissions from both roles
    assert multi_role_user.has_permission?("employees", "index")
    assert multi_role_user.has_permission?("employees", "create")
    assert multi_role_user.has_permission?("employees", "update")
    assert multi_role_user.has_permission?("employees", "destroy") # From HR Manager
    assert multi_role_user.has_permission?("payrolls", "index") # From HR Manager
    assert multi_role_user.has_permission?("attendance_records", "approve") # From Department Head
  end

  test "permissions method returns all user permissions" do
    super_admin_permissions = @super_admin.permissions
    assert_equal 10, super_admin_permissions.size # All permissions

    hr_manager_permissions = @hr_manager.permissions
    assert_equal 8, hr_manager_permissions.size # Employee + Payroll permissions

    employee_permissions = @employee.permissions
    assert_equal 2, employee_permissions.size # Only index and show
  end

  test "can_access_module? works correctly" do
    assert @super_admin.can_access_module?("employees")
    assert @super_admin.can_access_module?("payrolls")
    assert @super_admin.can_access_module?("attendance_records")

    assert @hr_manager.can_access_module?("employees")
    assert @hr_manager.can_access_module?("payrolls")
    assert_not @hr_manager.can_access_module?("attendance_records")

    assert @department_head.can_access_module?("employees")
    assert_not @department_head.can_access_module?("payrolls")
    assert @department_head.can_access_module?("attendance_records")

    assert @employee.can_access_module?("employees")
    assert_not @employee.can_access_module?("payrolls")
    assert_not @employee.can_access_module?("attendance_records")
  end

  test "can_manage_module? works correctly" do
    assert @super_admin.can_manage_module?("employees")
    assert @super_admin.can_manage_module?("payrolls")

    assert @hr_manager.can_manage_module?("employees")
    assert @hr_manager.can_manage_module?("payrolls")

    assert @department_head.can_manage_module?("employees") # Has create permission
    assert_not @department_head.can_manage_module?("payrolls")

    assert_not @employee.can_manage_module?("employees") # Only has index/show
    assert_not @employee.can_manage_module?("payrolls")
  end

  test "can_approve_in_module? works correctly" do
    assert @super_admin.can_approve_in_module?("attendance_records")
    assert @super_admin.can_approve_in_module?("leave_requests")

    assert_not @hr_manager.can_approve_in_module?("attendance_records")
    assert_not @hr_manager.can_approve_in_module?("leave_requests")

    assert @department_head.can_approve_in_module?("attendance_records")
    assert_not @department_head.can_approve_in_module?("leave_requests")

    assert_not @employee.can_approve_in_module?("attendance_records")
    assert_not @employee.can_approve_in_module?("leave_requests")
  end

  test "can_export_from_module? works correctly" do
    # Create export permissions
    export_permission = Permission.create!(
      name: "reports.export",
      resource: "reports",
      action: "export",
      description: "Export reports"
    )
    @super_admin_role.permissions << export_permission

    assert @super_admin.can_export_from_module?("reports")
    assert_not @hr_manager.can_export_from_module?("reports")
    assert_not @employee.can_export_from_module?("reports")
  end

  test "role checking methods work correctly" do
    assert @super_admin.super_admin?
    assert_not @super_admin.hr_manager?
    assert_not @super_admin.department_head?
    assert_not @super_admin.employee?

    assert_not @hr_manager.super_admin?
    assert @hr_manager.hr_manager?
    assert_not @hr_manager.department_head?
    assert_not @hr_manager.employee?

    assert_not @department_head.super_admin?
    assert_not @department_head.hr_manager?
    assert @department_head.department_head?
    assert_not @department_head.employee?

    assert_not @employee.super_admin?
    assert_not @employee.hr_manager?
    assert_not @employee.department_head?
    assert @employee.employee?
  end

  test "has_role? method works correctly" do
    assert @super_admin.has_role?("Super Admin")
    assert_not @super_admin.has_role?("HR Manager")

    assert @hr_manager.has_role?("HR Manager")
    assert_not @hr_manager.has_role?("Super Admin")

    assert @department_head.has_role?("Department Head")
    assert_not @department_head.has_role?("Employee")

    assert @employee.has_role?("Employee")
    assert_not @employee.has_role?("Super Admin")
  end

  test "status checking methods work correctly" do
    assert @super_admin.active?
    assert_not @super_admin.inactive?
    assert_not @super_admin.suspended?

    assert @inactive_user.inactive?
    assert_not @inactive_user.active?
    assert_not @inactive_user.suspended?

    # Test suspended user
    suspended_user = User.create!(
      email: "suspended@test.com",
      password: "password123",
      first_name: "Suspended",
      last_name: "User",
      status: "suspended"
    )

    assert suspended_user.suspended?
    assert_not suspended_user.active?
    assert_not suspended_user.inactive?
  end

  test "name method returns full name" do
    assert_equal "Super Admin", @super_admin.name
    assert_equal "HR Manager", @hr_manager.name
    assert_equal "Department Head", @department_head.name
    assert_equal "Test Employee", @employee.name
  end

  # test "jwt_payload includes all necessary information" do
  #   payload = @super_admin.jwt_payload

  #   assert_equal @super_admin.id, payload[:user_id]
  #   assert_equal @super_admin.email, payload[:email]
  #   assert_includes payload[:roles], "Super Admin"
  #   assert payload[:permissions].is_a?(Array)
  #   assert_equal "active", payload[:status]
  #   assert payload[:jti].present?
  # end

  # test "generate_jwt creates valid JWT token" do
  #   token = @super_admin.generate_jwt
  #   assert token.present?

  #   # Decode and verify token
  #   decoded = JWT.decode(token, Rails.application.secret_key_base, true, { algorithm: "HS256" }).first
  #   assert_equal @super_admin.id, decoded["user_id"]
  #   assert_equal @super_admin.email, decoded["email"]
  #   assert_includes decoded["roles"], "Super Admin"
  #   assert decoded["exp"].present?
  # end

  test "update_last_login! updates last_login_at" do
    initial_time = @super_admin.last_login_at
    @super_admin.update_last_login!

    assert_not_equal initial_time, @super_admin.reload.last_login_at
    assert @super_admin.last_login_at.present?
  end

  test "scopes work correctly" do
    # Test active scope
    active_users = User.active
    assert_includes active_users, @super_admin
    assert_includes active_users, @hr_manager
    assert_not_includes active_users, @inactive_user

    # Test inactive scope
    inactive_users = User.inactive
    assert_includes inactive_users, @inactive_user
    assert_not_includes inactive_users, @super_admin

    # Test role-based scopes
    super_admins = User.super_admins
    assert_includes super_admins, @super_admin
    assert_not_includes super_admins, @hr_manager

    hr_managers = User.hr_managers
    assert_includes hr_managers, @hr_manager
    assert_not_includes hr_managers, @super_admin

    employees = User.employees
    assert_includes employees, @employee
    assert_not_includes employees, @super_admin
  end

  test "permission checking is case sensitive - requires lowercase resource and action" do
    # The permission model stores lowercase resource/action keys - lookups must match exactly
    assert @super_admin.has_permission?("employees", "index")
    assert @super_admin.has_permission?("employees", "create")
    assert @super_admin.has_permission?("employees", "update")
    # Uppercase lookups do NOT match because the DB comparison is exact
    assert_not @super_admin.has_permission?("EMPLOYEES", "INDEX")
    assert_not @super_admin.has_permission?("Employees", "Create")
  end

  test "permission checking handles non-existent resources gracefully" do
    # Permissions are strictly role-based; no implicit super-admin bypass
    assert_not @super_admin.has_permission?("nonexistent", "index")
    assert_not @employee.has_permission?("nonexistent", "create")
  end

  test "permission checking handles non-existent actions gracefully" do
    # Non-existent actions return false even for super admin
    assert_not @super_admin.has_permission?("employees", "nonexistent")
    assert_not @employee.has_permission?("employees", "nonexistent")
  end

  test "user without roles has no permissions" do
    user_without_roles = User.create!(
      email: "noroles@test.com",
      password: "password123",
      first_name: "No",
      last_name: "Roles",
      status: "active"
    )

    assert_not user_without_roles.has_permission?("employees", "index")
    assert_not user_without_roles.has_permission?("payrolls", "create")
    assert_equal 0, user_without_roles.permissions.size
  end

  test "permission inheritance through multiple roles" do
    # Create user with overlapping permissions from different roles
    overlapping_user = User.create!(
      email: "overlapping@test.com",
      password: "password123",
      first_name: "Overlapping",
      last_name: "User",
      status: "active"
    )

    # Create two roles with some overlapping permissions
    role1 = Role.create!(name: "Role 1", description: "First role")
    role2 = Role.create!(name: "Role 2", description: "Second role")

    role1.permissions << @employee_permissions[0] # employees.index
    role1.permissions << @employee_permissions[1] # employees.show

    role2.permissions << @employee_permissions[1] # employees.show (overlap)
    role2.permissions << @employee_permissions[2] # employees.create

    overlapping_user.roles << role1
    overlapping_user.roles << role2

    # Should have unique permissions from both roles
    assert overlapping_user.has_permission?("employees", "index")
    assert overlapping_user.has_permission?("employees", "show")
    assert overlapping_user.has_permission?("employees", "create")
    assert_equal 3, overlapping_user.permissions.size # Should be unique
  end

  test "permission checking performance with many roles" do
    # Create user with many roles to test performance
    many_roles_user = User.create!(
      email: "manyroles@test.com",
      password: "password123",
      first_name: "Many",
      last_name: "Roles",
      status: "active"
    )

    # Create 10 roles with different permissions
    10.times do |i|
      role = Role.create!(name: "Role #{i}", description: "Role #{i}")
      permission = Permission.create!(
        name: "resource#{i}.action#{i}",
        resource: "resource#{i}",
        action: "action#{i}",
        description: "Permission #{i}"
      )
      role.permissions << permission
      many_roles_user.roles << role
    end

    # Should still work efficiently
    assert many_roles_user.has_permission?("resource0", "action0")
    assert many_roles_user.has_permission?("resource5", "action5")
    assert_not many_roles_user.has_permission?("resource0", "action1")
                                                                                                                                              end
end
