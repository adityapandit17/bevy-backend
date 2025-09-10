class Role < ApplicationRecord
  # Associations
  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles
  has_many :role_permissions, dependent: :destroy
  has_many :permissions, through: :role_permissions

  # Validations
  validates :name, presence: true, uniqueness: true

  # Scopes
  scope :by_name, ->(name) { where(name: name) }

  # Class methods
  def self.create_default_roles
    roles_data = [
      {
        name: "Super Admin",
        description: "Full system access with all permissions"
      },
      {
        name: "HR Manager",
        description: "Employee management, payroll, reports access"
      },
      {
        name: "Department Head",
        description: "Team management, attendance approval access"
      },
      {
        name: "Employee",
        description: "Self-service portal access"
      }
    ]

    roles_data.each do |role_data|
      find_or_create_by(name: role_data[:name]) do |role|
        role.description = role_data[:description]
      end
    end
  end

  # Instance methods
  def add_permission(permission)
    permissions << permission unless permissions.include?(permission)
  end

  def remove_permission(permission)
    permissions.delete(permission)
  end

  def has_permission?(resource, action)
    permissions.exists?(resource: resource, action: action)
  end
end
