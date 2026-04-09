class Permission < ApplicationRecord
  # Associations
  has_many :role_permissions, dependent: :destroy
  has_many :roles, through: :role_permissions

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :resource, presence: true
  validates :action, presence: true
  validates :resource, uniqueness: { scope: :action }

  # Scopes
  scope :by_resource, ->(resource) { where(resource: resource) }
  scope :by_action, ->(action) { where(action: action) }
  scope :by_resource_and_action, ->(resource, action) { where(resource: resource, action: action) }

  # Class methods
  def self.create_default_permissions
    permissions_data = [
      # Employee Management
      { name: "employees.index", resource: "employees", action: "index", description: "View employees list" },
      { name: "employees.show", resource: "employees", action: "show", description: "View employee details" },
      { name: "employees.create", resource: "employees", action: "create", description: "Create new employees" },
      { name: "employees.update", resource: "employees", action: "update", description: "Update employee information" },
      { name: "employees.destroy", resource: "employees", action: "destroy", description: "Delete employees" },

      # Payroll Management
      { name: "payrolls.index", resource: "payrolls", action: "index", description: "View payroll list" },
      { name: "payrolls.show", resource: "payrolls", action: "show", description: "View payroll details" },
      { name: "payrolls.create", resource: "payrolls", action: "create", description: "Create payroll records" },
      { name: "payrolls.update", resource: "payrolls", action: "update", description: "Update payroll records" },
      { name: "payrolls.destroy", resource: "payrolls", action: "destroy", description: "Delete payroll records" },

      # Attendance & Leave
      { name: "attendance_records.index", resource: "attendance_records", action: "index", description: "View attendance records" },
      { name: "attendance_records.approve", resource: "attendance_records", action: "approve", description: "Approve attendance records" },
      { name: "leave_requests.index", resource: "leave_requests", action: "index", description: "View leave requests" },
      { name: "leave_requests.approve", resource: "leave_requests", action: "approve", description: "Approve leave requests" },
      { name: "leave_requests.reject", resource: "leave_requests", action: "reject", description: "Reject leave requests" },
      { name: "leave_management.index", resource: "leave_management", action: "index", description: "Manage leave requests for all employees, apply leave on behalf of others, and approve pending leave requests" },

      # Recruitment
      { name: "candidates.index", resource: "candidates", action: "index", description: "View candidates list" },
      { name: "candidates.show", resource: "candidates", action: "show", description: "View candidate details" },
      { name: "candidates.create", resource: "candidates", action: "create", description: "Create new candidates" },
      { name: "candidates.update", resource: "candidates", action: "update", description: "Update candidate information" },
      { name: "candidates.destroy", resource: "candidates", action: "destroy", description: "Delete candidates" },
      { name: "job_openings.index", resource: "job_openings", action: "index", description: "View job openings list" },
      { name: "job_openings.show", resource: "job_openings", action: "show", description: "View job opening details" },
      { name: "job_openings.create", resource: "job_openings", action: "create", description: "Create new job openings" },
      { name: "job_openings.update", resource: "job_openings", action: "update", description: "Update job opening information" },
      { name: "job_openings.destroy", resource: "job_openings", action: "destroy", description: "Delete job openings" },
      { name: "interviews.index", resource: "interviews", action: "index", description: "View interviews list" },
      { name: "interviews.show", resource: "interviews", action: "show", description: "View interview details" },
      { name: "interviews.create", resource: "interviews", action: "create", description: "Schedule interviews" },
      { name: "interviews.update", resource: "interviews", action: "update", description: "Update interview details" },
      { name: "interviews.destroy", resource: "interviews", action: "destroy", description: "Delete interviews" },

      # Performance Management
      { name: "performance_reviews.index", resource: "performance_reviews", action: "index", description: "View performance reviews" },
      { name: "performance_reviews.create", resource: "performance_reviews", action: "create", description: "Create performance reviews" },
      { name: "performance_reviews.update", resource: "performance_reviews", action: "update", description: "Update performance reviews" },
      { name: "performance_goals.index", resource: "performance_goals", action: "index", description: "View performance goals" },
      { name: "performance_goals.create", resource: "performance_goals", action: "create", description: "Create performance goals" },

      # Asset Management
      { name: "assets.index", resource: "assets", action: "index", description: "View assets list" },
      { name: "assets.create", resource: "assets", action: "create", description: "Create new assets" },
      { name: "assets.update", resource: "assets", action: "update", description: "Update asset information" },
      { name: "assets.destroy", resource: "assets", action: "destroy", description: "Delete assets" },
      { name: "asset_allocations.index", resource: "asset_allocations", action: "index", description: "View asset allocations" },
      { name: "asset_allocations.create", resource: "asset_allocations", action: "create", description: "Allocate assets" },
      { name: "asset_allocations.update", resource: "asset_allocations", action: "update", description: "Update asset allocations" },
      { name: "asset_allocations.destroy", resource: "asset_allocations", action: "destroy", description: "Delete asset allocations" },
      { name: "maintenance_records.index", resource: "maintenance_records", action: "index", description: "View maintenance records" },
      { name: "maintenance_records.create", resource: "maintenance_records", action: "create", description: "Create maintenance records" },
      { name: "maintenance_records.update", resource: "maintenance_records", action: "update", description: "Update maintenance records" },
      { name: "maintenance_records.destroy", resource: "maintenance_records", action: "destroy", description: "Delete maintenance records" },

      # IT Helpdesk
      { name: "helpdesk_tickets.index", resource: "helpdesk_tickets", action: "index", description: "View helpdesk tickets" },
      { name: "helpdesk_tickets.show", resource: "helpdesk_tickets", action: "show", description: "View helpdesk ticket details" },
      { name: "helpdesk_tickets.create", resource: "helpdesk_tickets", action: "create", description: "Create helpdesk tickets" },
      { name: "helpdesk_tickets.update", resource: "helpdesk_tickets", action: "update", description: "Update helpdesk tickets" },
      { name: "helpdesk_tickets.destroy", resource: "helpdesk_tickets", action: "destroy", description: "Delete helpdesk tickets" },
      { name: "helpdesk_tickets.stats", resource: "helpdesk_tickets", action: "stats", description: "View helpdesk ticket stats" },
      { name: "ticket_comments.index", resource: "ticket_comments", action: "index", description: "View ticket comments" },
      { name: "ticket_comments.create", resource: "ticket_comments", action: "create", description: "Create ticket comments" },
      { name: "ticket_comments.update", resource: "ticket_comments", action: "update", description: "Update ticket comments" },
      { name: "ticket_comments.destroy", resource: "ticket_comments", action: "destroy", description: "Delete ticket comments" },

      # Reports
      { name: "reports.index", resource: "reports", action: "index", description: "View reports" },
      { name: "reports.export", resource: "reports", action: "export", description: "Export reports" },

      # User Management
      { name: "users.index", resource: "users", action: "index", description: "View users list" },
      { name: "users.create", resource: "users", action: "create", description: "Create new users" },
      { name: "users.update", resource: "users", action: "update", description: "Update user information" },
      { name: "users.destroy", resource: "users", action: "destroy", description: "Delete users" },
      { name: "roles.index", resource: "roles", action: "index", description: "View roles list" },
      { name: "roles.create", resource: "roles", action: "create", description: "Create new roles" },
      { name: "roles.update", resource: "roles", action: "update", description: "Update role information" },
      { name: "permissions.index", resource: "permissions", action: "index", description: "View permissions list" },

      # Settings
      { name: "settings.index", resource: "settings", action: "index", description: "View settings" },
      { name: "settings.update", resource: "settings", action: "update", description: "Update settings" },

      # Workspace Seating (UI access)
      { name: "workspace_seating.index", resource: "workspace_seating", action: "index", description: "View workspace seating map" }
    ]

    permissions_data.each do |permission_data|
      find_or_create_by(name: permission_data[:name]) do |permission|
        permission.resource = permission_data[:resource]
        permission.action = permission_data[:action]
        permission.description = permission_data[:description]
      end
    end
  end

  # Instance methods
  def resource_action
    "#{resource}##{action}"
  end
end
