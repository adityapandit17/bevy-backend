class Role < ApplicationRecord
  SYSTEM_ROLE_NAMES = [
    "Super Admin",
    "HR Manager",
    "Department Head",
    "Employee",
    "IT Asset Manager",
    "IT Support"
  ].freeze

  # Associations
  belongs_to :company, optional: true
  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles
  has_many :role_permissions, dependent: :destroy
  has_many :permissions, through: :role_permissions

  # Validations
  validates :name, presence: true
  validates :name, uniqueness: { conditions: -> { where(company_id: nil) } }, if: :system_role?
  validates :name, uniqueness: { scope: :company_id }, if: :custom_role?
  validate :company_presence_matches_role_type

  # Scopes
  scope :by_name, ->(name) { where(name: name) }
  scope :system_roles, -> { where(company_id: nil) }
  scope :custom_roles, -> { where.not(company_id: nil) }
  scope :for_company, ->(company) { where(company_id: [ nil, company.id ]) }
  scope :assignable_for, ->(company) { for_company(company) }

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
      },
      {
        name: "IT Asset Manager",
        description: "Manages company assets and allocations"
      },
      {
        name: "IT Support",
        description: "Handles IT helpdesk tickets and hardware support"
      }
    ]

    roles_data.each do |role_data|
      find_or_create_by!(name: role_data[:name], company_id: nil) do |role|
        role.description = role_data[:description]
      end
    end
  end

  # Instance methods
  def system_role?
    company_id.nil?
  end

  def custom_role?
    company_id.present?
  end

  def add_permission(permission)
    permissions << permission unless permissions.include?(permission)
  end

  def remove_permission(permission)
    permissions.delete(permission)
  end

  def has_permission?(resource, action)
    permissions.exists?(resource: resource, action: action)
  end

  private

  def company_presence_matches_role_type
    if SYSTEM_ROLE_NAMES.include?(name) && company_id.present?
      errors.add(:company_id, "must be blank for system roles")
    end
  end
end
