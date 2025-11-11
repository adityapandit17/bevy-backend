# Create default roles and permissions
puts "Creating default roles..."
Role.create_default_roles

puts "Creating default demo permissions (8 total)..."
demo_permissions = [
  { name: "employees.index", resource: "employees", action: "index", description: "View employees list" },
  { name: "employees.create", resource: "employees", action: "create", description: "Create new employees" },
  { name: "employees.update", resource: "employees", action: "update", description: "Update employee information" },
  { name: "employees.destroy", resource: "employees", action: "destroy", description: "Delete employees" },
  { name: "payrolls.index", resource: "payrolls", action: "index", description: "View payroll list" },
  { name: "payrolls.create", resource: "payrolls", action: "create", description: "Create payroll records" },
  { name: "payrolls.update", resource: "payrolls", action: "update", description: "Update payroll records" },
  { name: "payrolls.destroy", resource: "payrolls", action: "destroy", description: "Delete payroll records" },
  # Needed for accessing RolesController
  { name: "roles.index", resource: "roles", action: "index", description: "View roles list" }
]

demo_permissions.each do |attrs|
  Permission.find_or_create_by!(name: attrs[:name]) do |p|
    p.resource = attrs[:resource]
    p.action = attrs[:action]
    p.description = attrs[:description]
  end
end

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

puts "User roles and permissions setup completed!"
