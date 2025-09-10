# Create default roles and permissions
puts "Creating default roles..."
Role.create_default_roles

puts "Creating comprehensive permissions for all HRMS modules..."
Permission.create_default_permissions

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
  hr_permissions = Permission.where(
    resource: [ 'employees', 'payrolls', 'reports', 'users', 'roles', 'permissions', 'settings' ]
  )
  hr_manager.permission_ids = hr_permissions.pluck(:id)
  puts "✓ HR Manager permissions assigned"
end

# Department Head - Team management, attendance approval
dept_head = Role.find_by(name: 'Department Head')
if dept_head
  dept_permissions = Permission.where(
    resource: [ 'employees', 'attendance_records', 'leave_requests', 'performance_reviews', 'performance_goals' ]
  ).where.not(action: 'destroy')
  dept_head.permission_ids = dept_permissions.pluck(:id)
  puts "✓ Department Head permissions assigned"
end

# Employee - Self-service portal access
employee_role = Role.find_by(name: 'Employee')
if employee_role
  employee_permissions = Permission.where(
    resource: [ 'employees', 'attendance_records', 'leave_requests', 'performance_reviews', 'performance_goals', 'timesheets', 'employee_benefits', 'employee_trainings' ]
  ).where(action: [ 'index', 'show' ])
  employee_role.permission_ids = employee_permissions.pluck(:id)
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
