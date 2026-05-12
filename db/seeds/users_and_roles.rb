# Create default roles and permissions
puts "Creating default roles..."
Role.create_default_roles

puts "Creating default permissions..."
Permission.create_default_permissions
puts "✓ Created #{Permission.count} permissions"

# Assign permissions to roles
puts "Assigning permissions to roles..."

# Super Admin - All permissions
super_admin = Role.find_by(name: 'Super Admin')
if super_admin
  super_admin.permission_ids = Permission.pluck(:id)
  puts "✓ Super Admin has all permissions"
end

# HR Manager - Employee, Payroll, Reports, User Management permissions
hr_manager = Role.find_by(name: 'HR Manager')
if hr_manager
  # 6 permissions (employees: index/create/update, payrolls: index/create, leave_management: index)
  hr_permission_names = [
    'employees.index', 'employees.create', 'employees.update',
    'payrolls.index', 'payrolls.create',
    'leave_management.index'
  ]
  hr_permissions = Permission.where(name: hr_permission_names)
  hr_manager.permission_ids = hr_permissions.pluck(:id)
  puts "✓ HR Manager permissions assigned"
end

# Department Head - Team management, attendance approval
dept_head = Role.find_by(name: 'Department Head')
if dept_head
  # 2 of 8 permissions (employees.index, payrolls.index)
  dept_permission_names = [ 'employees.index', 'payrolls.index' ]
  dept_permissions = Permission.where(name: dept_permission_names)
  dept_head.permission_ids = dept_permissions.pluck(:id)
  puts "✓ Department Head permissions assigned"
end

# Employee - Self-service portal access
employee_role = Role.find_by(name: 'Employee')
if employee_role
  # 0 permissions by default
  employee_role.permission_ids = []
  puts "✓ Employee permissions assigned"
end

# IT Asset Manager - Asset + allocation + maintenance access
it_asset_manager = Role.find_by(name: 'IT Asset Manager')
if it_asset_manager
  it_asset_permission_names = [
    'assets.index', 'assets.create', 'assets.update', 'assets.destroy',
    'asset_allocations.index', 'asset_allocations.create', 'asset_allocations.update', 'asset_allocations.destroy',
    'maintenance_records.index', 'maintenance_records.create', 'maintenance_records.update', 'maintenance_records.destroy'
  ]
  it_asset_permissions = Permission.where(name: it_asset_permission_names)
  it_asset_manager.permission_ids = it_asset_permissions.pluck(:id)
  puts "✓ IT Asset Manager permissions assigned"
end

# IT Support - Helpdesk ticket access (and read-only assets)
it_support = Role.find_by(name: 'IT Support')
if it_support
  it_support_permission_names = [
    'helpdesk_tickets.index', 'helpdesk_tickets.show', 'helpdesk_tickets.create', 'helpdesk_tickets.update', 'helpdesk_tickets.stats',
    'ticket_comments.index', 'ticket_comments.create', 'ticket_comments.update',
    'assets.index', 'asset_allocations.index', 'maintenance_records.index'
  ]
  it_support_permissions = Permission.where(name: it_support_permission_names)
  it_support.permission_ids = it_support_permissions.pluck(:id)
  puts "✓ IT Support permissions assigned"
end

# Create a default super admin user
puts "Creating default super admin user..."
admin_user = User.find_or_create_by(email: 'admin@hrms.com') do |user|
  user.first_name = 'Super'
  user.last_name = 'Admin'
  user.password = 'admin123'
  user.password_confirmation = 'admin123'
  user.status = 'active'
end

# Assign Super Admin role to the default user
if admin_user && super_admin
  admin_user.roles << super_admin unless admin_user.roles.include?(super_admin)
  puts "✓ Default super admin user created: admin@hrms.com / admin123"
end

# Create additional default users for role-based testing
puts "Creating default non-admin users for role-based access..."

def ensure_user_for_employee!(employee_email:, role_name:, password:)
  employee = Employee.find_by(email: employee_email)
  role = Role.find_by(name: role_name)

  unless employee
    puts "⚠ Employee not found for #{employee_email} (skipping user creation)"
    return
  end

  unless role
    puts "⚠ Role not found: #{role_name} (skipping user creation)"
    return
  end

  user = User.find_or_create_by!(email: employee.email) do |u|
    u.first_name = employee.first_name
    u.last_name = employee.last_name
    u.password = password
    u.password_confirmation = password
    u.status = "active"
    u.employee_id = employee.id
  end

  # Ensure linkage & active status even if user existed
  if user.employee_id != employee.id || user.status != "active"
    user.update!(employee_id: employee.id, status: "active")
  end

  user.roles << role unless user.roles.include?(role)
  puts "✓ #{role_name} user ready: #{user.email} / #{password}"
end

# HR Manager
ensure_user_for_employee!(
  employee_email: "sarah.miller@company.com",
  role_name: "HR Manager",
  password: "password123"
)

# Department Head
ensure_user_for_employee!(
  employee_email: "bob.wilson@company.com",
  role_name: "Department Head",
  password: "password123"
)

# Employee
ensure_user_for_employee!(
  employee_email: "john.doe@company.com",
  role_name: "Employee",
  password: "password123"
)

puts "User roles and permissions setup completed!"

# Multitenancy: ensure every user can access seed workspaces (subdomain dev: bevy / bis).
if defined?($seed_company) && $seed_company && defined?($seed_company_bis) && $seed_company_bis
  puts "Linking users to seed companies (#{$seed_company.code}, #{$seed_company_bis.code})..."
  User.find_each do |user|
    [ $seed_company, $seed_company_bis ].each do |co|
      CompanyMembership.find_or_create_by!(user_id: user.id, company_id: co.id) do |m|
        m.status = "active"
      end
    end
  end
  puts "✓ Company memberships ensured"
end
