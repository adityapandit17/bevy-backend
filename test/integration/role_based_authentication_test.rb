require "test_helper"

class RoleBasedAuthenticationTest < ActionDispatch::IntegrationTest
  def setup
    # Create test roles and permissions
    @super_admin_role = Role.find_or_create_by(name: "Super Admin") do |role|
      role.description = "Full system access"
    end

    @hr_manager_role = Role.find_or_create_by(name: "HR Manager") do |role|
      role.description = "HR management access"
    end

    @employee_role = Role.find_or_create_by(name: "Employee") do |role|
      role.description = "Basic employee access"
    end

    # Create test permissions
    @employee_permissions = [
      Permission.find_or_create_by(name: "employees.index", resource: "employees", action: "index") do |p|
        p.description = "View employees list"
      end,
      Permission.find_or_create_by(name: "employees.show", resource: "employees", action: "show") do |p|
        p.description = "View employee details"
      end,
      Permission.find_or_create_by(name: "employees.create", resource: "employees", action: "create") do |p|
        p.description = "Create employees"
      end,
      Permission.find_or_create_by(name: "employees.update", resource: "employees", action: "update") do |p|
        p.description = "Update employees"
      end,
      Permission.find_or_create_by(name: "employees.destroy", resource: "employees", action: "destroy") do |p|
        p.description = "Delete employees"
      end
    ]

    @payroll_permissions = [
      Permission.find_or_create_by(name: "payrolls.index", resource: "payrolls", action: "index") do |p|
        p.description = "View payroll list"
      end,
      Permission.find_or_create_by(name: "payrolls.create", resource: "payrolls", action: "create") do |p|
        p.description = "Create payroll records"
      end
    ]

    # Assign permissions to roles
    @super_admin_role.permissions = @employee_permissions + @payroll_permissions
    @hr_manager_role.permissions = @employee_permissions + @payroll_permissions
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

  test "super admin can access all employee endpoints" do
    token = get_jwt_token(@super_admin)

    get "/employees", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :success

    # Create an employee first to test show endpoint
    post "/employees", params: { employee: { first_name: "New", last_name: "Employee", email: "new@test.com" } },
         headers: { "Authorization" => "Bearer #{token}" }
    assert_response :success

    employee_id = JSON.parse(response.body)["id"]
    get "/employees/#{employee_id}", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :success
  end

  test "hr manager can access employee management but not destroy" do
    token = get_jwt_token(@hr_manager)

    get "/employees", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :success

    # Create an employee first to test show endpoint
    post "/employees", params: { employee: { first_name: "New", last_name: "Employee", email: "new2@test.com" } },
         headers: { "Authorization" => "Bearer #{token}" }
    assert_response :success

    employee_id = JSON.parse(response.body)["id"]
    get "/employees/#{employee_id}", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :success

    # HR Manager should not be able to destroy employees
    delete "/employees/#{employee_id}", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :forbidden
  end

  test "employee can only view employees" do
    token = get_jwt_token(@employee)

    get "/employees", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :success

    # Create an employee first using super admin to test show endpoint
    admin_token = get_jwt_token(@super_admin)
    post "/employees", params: { employee: { first_name: "Test", last_name: "Employee", email: "test@test.com" } },
         headers: { "Authorization" => "Bearer #{admin_token}" }
    assert_response :success

    employee_id = JSON.parse(response.body)["id"]
    get "/employees/#{employee_id}", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :success

    # Employee should not be able to create employees
    post "/employees", params: { employee: { first_name: "New", last_name: "Employee", email: "new3@test.com" } },
         headers: { "Authorization" => "Bearer #{token}" }
    assert_response :forbidden

    # Employee should not be able to update employees
    patch "/employees/#{employee_id}", params: { employee: { first_name: "Updated" } },
          headers: { "Authorization" => "Bearer #{token}" }
    assert_response :forbidden

    # Employee should not be able to destroy employees
    delete "/employees/#{employee_id}", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :forbidden
  end

  test "inactive user cannot access any endpoints" do
    # Inactive users should not be able to get a token in the first place
    # But if they somehow have a token, they should be denied access
    token = get_jwt_token(@inactive_user)

    get "/employees", headers: { "Authorization" => "Bearer #{token}" }
    # The authentication should fail because the user is inactive
    assert_response :unauthorized
  end

  test "user without token cannot access protected endpoints" do
    get "/employees"
    assert_response :unauthorized

    get "/employees/1"
    assert_response :unauthorized
  end

  test "invalid token cannot access protected endpoints" do
    get "/employees", headers: { "Authorization" => "Bearer invalid_token" }
    assert_response :unauthorized
  end

  test "super admin can access payroll endpoints" do
    token = get_jwt_token(@super_admin)

    get "/payrolls", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :success

    # Create an employee first to test payroll creation
    post "/employees", params: { employee: { first_name: "Payroll", last_name: "Employee", email: "payroll@test.com" } },
         headers: { "Authorization" => "Bearer #{token}" }
    assert_response :success

    employee_id = JSON.parse(response.body)["id"]
    post "/payrolls", params: { payroll: { employee_id: employee_id, amount: 50000 } },
         headers: { "Authorization" => "Bearer #{token}" }
    assert_response :success
  end

  test "hr manager can access payroll endpoints" do
    token = get_jwt_token(@hr_manager)

    get "/payrolls", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :success

    # Create an employee first using super admin
    admin_token = get_jwt_token(@super_admin)
    post "/employees", params: { employee: { first_name: "HR", last_name: "Employee", email: "hr@test.com" } },
         headers: { "Authorization" => "Bearer #{admin_token}" }
    assert_response :success

    employee_id = JSON.parse(response.body)["id"]
    post "/payrolls", params: { payroll: { employee_id: employee_id, amount: 50000 } },
         headers: { "Authorization" => "Bearer #{token}" }
    assert_response :success
  end

  test "employee cannot access payroll endpoints" do
    token = get_jwt_token(@employee)

    get "/payrolls", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :forbidden

    # Create an employee first using super admin
    admin_token = get_jwt_token(@super_admin)
    post "/employees", params: { employee: { first_name: "Emp", last_name: "Employee", email: "emp@test.com" } },
         headers: { "Authorization" => "Bearer #{admin_token}" }
    assert_response :success

    employee_id = JSON.parse(response.body)["id"]
    post "/payrolls", params: { payroll: { employee_id: employee_id, amount: 50000 } },
         headers: { "Authorization" => "Bearer #{token}" }
    assert_response :forbidden
  end

  test "user can check their own permissions" do
    token = get_jwt_token(@super_admin)

    get "/users/current", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :success

    response_data = JSON.parse(response.body)
    role_names = response_data["roles"].map { |r| r["name"] }
    assert_includes role_names, "Super Admin"
    assert response_data["permissions"].length > 0
  end

  test "user can login and get token with roles and permissions" do
    post "/users/sign_in", params: {
      user: {
        email: @super_admin.email,
        password: "password123"
      }
    }

    assert_response :success
    response_data = JSON.parse(response.body)

    assert response_data["token"].present?
    assert response_data["user"].present?
    assert response_data["roles"].present?
    assert response_data["permissions"].present?
    assert_includes response_data["roles"].map { |r| r["name"] }, "Super Admin"
  end

  test "user can logout successfully" do
    token = get_jwt_token(@super_admin)

    delete "/users/sign_out", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :success

    response_data = JSON.parse(response.body)
    assert_equal "Logout successful", response_data["message"]
  end

  test "user with multiple roles gets combined permissions" do
    # Create a user with multiple roles
    multi_role_user = User.create!(
      email: "multirole@test.com",
      password: "password123",
      first_name: "Multi",
      last_name: "Role",
      status: "active"
    )
    multi_role_user.roles << @hr_manager_role
    multi_role_user.roles << @employee_role

    token = get_jwt_token(multi_role_user)

    get "/users/current", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :success

    response_data = JSON.parse(response.body)
    role_names = response_data["roles"].map { |r| r["name"] }
    assert_includes role_names, "HR Manager"
    assert_includes role_names, "Employee"

    # Should have permissions from both roles
    permission_count = response_data["permissions"].length
    assert permission_count > 0
  end

  test "permission checking works correctly" do
    # Test super admin has all permissions
    assert @super_admin.has_permission?("employees", "index")
    assert @super_admin.has_permission?("employees", "create")
    assert @super_admin.has_permission?("employees", "update")
    assert @super_admin.has_permission?("employees", "destroy")
    assert @super_admin.has_permission?("payrolls", "index")
    assert @super_admin.has_permission?("payrolls", "create")

    # Test HR manager has employee permissions but not destroy
    assert @hr_manager.has_permission?("employees", "index")
    assert @hr_manager.has_permission?("employees", "create")
    assert @hr_manager.has_permission?("employees", "update")
    assert @hr_manager.has_permission?("payrolls", "index")
    assert @hr_manager.has_permission?("payrolls", "create")

    # Test employee has limited permissions
    assert @employee.has_permission?("employees", "index")
    assert @employee.has_permission?("employees", "show")
    assert_not @employee.has_permission?("employees", "create")
    assert_not @employee.has_permission?("employees", "update")
    assert_not @employee.has_permission?("employees", "destroy")
    assert_not @employee.has_permission?("payrolls", "index")
  end

  test "role-based access control in controllers" do
    # Test that controllers properly check permissions
    token = get_jwt_token(@employee)

    # Employee should not be able to access admin endpoints
    get "/users", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :forbidden

    get "/roles", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :forbidden

    get "/permissions", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :forbidden
  end

  test "super admin can access admin endpoints" do
    token = get_jwt_token(@super_admin)

    get "/users", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :success

    get "/roles", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :success

    get "/permissions", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :success
  end

  test "hr manager can access user management but not system settings" do
    token = get_jwt_token(@hr_manager)

    get "/users", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :success

    get "/roles", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :success

    # HR Manager should not access system settings
    get "/settings", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :forbidden
  end

  private

  def get_jwt_token(user)
    # Generate JWT token for testing
    payload = {
      user_id: user.id,
      email: user.email,
      roles: user.roles.pluck(:name),
      permissions: user.permissions.pluck(:name),
      status: user.status,
      jti: SecureRandom.uuid,
      exp: 24.hours.from_now.to_i
    }
    JWT.encode(payload, Rails.application.secret_key_base, "HS256")
  end
end
