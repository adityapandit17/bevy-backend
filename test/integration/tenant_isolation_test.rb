# frozen_string_literal: true

require "test_helper"

class TenantIsolationTest < ActionDispatch::IntegrationTest
  setup do
    @company_a = companies(:one)
    @company_b = companies(:two)

    ActsAsTenant.with_tenant(@company_a) do
      @dept_a = Department.find_or_create_by!(name: "Tenant A Dept", company: @company_a)
      @employee_a = Employee.find_or_create_by!(email: "tenant-a-employee@example.com", company: @company_a) do |e|
        e.first_name = "Tenant"
        e.last_name = "A"
        e.phone = "+1 415 555 0101"
        e.department = @dept_a
        e.designation = "Engineer"
        e.date_of_joining = Date.current
        e.status = "active"
      end
      @user_a = User.find_or_create_by!(email: "tenant-a-admin@example.com", company: @company_a) do |u|
        u.first_name = "Admin"
        u.last_name = "A"
        u.password = "Password123!"
        u.status = "active"
        u.employee = @employee_a
      end
    end

    ActsAsTenant.with_tenant(@company_b) do
      @dept_b = Department.find_or_create_by!(name: "Tenant B Dept", company: @company_b)
      @employee_b = Employee.find_or_create_by!(email: "tenant-b-employee@example.com", company: @company_b) do |e|
        e.first_name = "Tenant"
        e.last_name = "B"
        e.phone = "+1 212 555 0102"
        e.department = @dept_b
        e.designation = "Engineer"
        e.date_of_joining = Date.current
        e.status = "active"
      end
      @user_b = User.find_or_create_by!(email: "tenant-b-admin@example.com", company: @company_b) do |u|
        u.first_name = "Admin"
        u.last_name = "B"
        u.password = "Password123!"
        u.status = "active"
        u.employee = @employee_b
      end
    end

    role = Role.system_roles.find_or_create_by!(name: "Super Admin")
    Permission.find_or_create_by!(resource: "employees", action: "index") do |p|
      p.name = "employees.index"
      p.description = "List employees"
    end
    perm = Permission.find_by!(resource: "employees", action: "index")
    role.permissions << perm unless role.permissions.include?(perm)
    show_perm = Permission.find_or_create_by!(resource: "employees", action: "show") do |p|
      p.name = "employees.show"
      p.description = "Show employee"
    end
    role.permissions << show_perm unless role.permissions.include?(show_perm)

    [ @user_a, @user_b ].each do |user|
      user.roles << role unless user.roles.include?(role)
    end

    @headers_a = auth_headers_for(@user_a)
    @headers_b = auth_headers_for(@user_b)
  end

  test "tenant A cannot access tenant B employee by id" do
    get "/employees/#{@employee_b.id}", headers: @headers_a
    assert_response :not_found
  end

  test "tenant B cannot list tenant A employees in detail" do
    get "/employees/#{@employee_a.id}", headers: @headers_b
    assert_response :not_found
  end

  test "tenant JWT with mismatched company_id is rejected" do
    payload = {
      aud: "tenant",
      user_id: @user_a.id,
      company_id: @company_b.id,
      email: @user_a.email,
      name: @user_a.name,
      roles: [],
      iat: Time.current.to_i,
      jti: SecureRandom.uuid
    }
    bad_token = JwtService.encode(payload)

    get "/employees", headers: { "Authorization" => "Bearer #{bad_token}", "Accept" => "application/json" }
    assert_response :unauthorized
  end

  test "platform JWT cannot access tenant employees API" do
    admin = PlatformAdminUser.find_or_create_by!(email: "isolation-platform@bevyhr.com") do |a|
      a.first_name = "P"
      a.last_name = "Admin"
      a.password = "admin123"
      a.password_confirmation = "admin123"
      a.role = "super_admin"
      a.status = "active"
    end
    token = PlatformJwtService.generate_token(admin)

    get "/employees", headers: { "Authorization" => "Bearer #{token}", "Accept" => "application/json" }
    assert_response :unauthorized
  end

  test "tenant JWT cannot access platform API" do
    get "/api/v1/platform/auth/me", headers: @headers_a
    assert_response :unauthorized
  end

  test "role user counts and assigned users are scoped to current company" do
    role = Role.system_roles.find_by!(name: "Super Admin")

    get "/roles", headers: @headers_a
    assert_response :success
    body_a = JSON.parse(response.body)
    role_a = body_a.fetch("roles").find { |r| r["id"] == role.id }
    assert_equal 1, role_a["user_count"]

    get "/roles/#{role.id}", headers: @headers_a
    assert_response :success
    show_a = JSON.parse(response.body)
    assert_equal 1, show_a.dig("role", "user_count")
    assert_equal [ @user_a.id ], show_a.fetch("users").map { |u| u["id"] }

    get "/roles", headers: @headers_b
    assert_response :success
    body_b = JSON.parse(response.body)
    role_b = body_b.fetch("roles").find { |r| r["id"] == role.id }
    assert_equal 1, role_b["user_count"]

    get "/roles/#{role.id}", headers: @headers_b
    assert_response :success
    show_b = JSON.parse(response.body)
    assert_equal 1, show_b.dig("role", "user_count")
    assert_equal [ @user_b.id ], show_b.fetch("users").map { |u| u["id"] }
  end

  test "trial signup creates isolated tenant data" do
    email = "new-tenant-#{SecureRandom.hex(4)}@example.com"

    assert_difference "Company.count", 1 do
      post "/api/v1/public/signup", params: {
        company_name: "Isolation Test Co",
        admin_email: email,
        admin_password: "password123",
        admin_first_name: "New",
        admin_last_name: "Admin"
      }, as: :json
    end

    assert_response :created
    body = JSON.parse(response.body)
    company = Company.find(body.dig("data", "company", "id"))

    ActsAsTenant.with_tenant(company) do
      assert Employee.exists?(email: email)
      assert User.exists?(email: email)
      assert Department.exists?(name: "General")
    end

    assert_not Employee.unscoped.where(company_id: @company_a.id).exists?(email: email)
  end
end
