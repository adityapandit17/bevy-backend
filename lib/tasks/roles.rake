# frozen_string_literal: true

namespace :roles do
  desc "Assign self-service attendance/leave permissions to Employee role (safe to re-run)"
  task sync_employee_self_service: :environment do
    Permission.create_default_permissions

    employee_role = Role.find_by(name: "Employee")
    unless employee_role
      puts "Employee role not found"
      next
    end

    names = %w[
      attendance_records.index
      leave_requests.index
      leave_requests.create
      leave_requests.cancel
    ]
    perms = Permission.where(name: names)
    employee_role.permission_ids = perms.pluck(:id)
    puts "Employee role: #{perms.pluck(:name).join(', ')}"
  end
end
