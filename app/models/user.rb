class User < ApplicationRecord
  include TenantScoped

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associations
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  has_many :notifications, dependent: :destroy
  belongs_to :employee, optional: true
  has_one :user_preference, dependent: :destroy
  has_many :channel_memberships, dependent: :destroy
  has_many :channels, through: :channel_memberships
  has_many :created_channels, class_name: "Channel", foreign_key: "created_by_id", dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :started_huddles, class_name: "Huddle", foreign_key: "started_by_id", dependent: :destroy
  has_many :huddle_participants, dependent: :destroy
  has_many :huddles, through: :huddle_participants

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :status, presence: true, inclusion: { in: %w[active inactive suspended] }
  validates :email, uniqueness: { scope: :company_id, case_sensitive: false }
  validate :roles_belong_to_company

  # Scopes
  scope :active, -> { where(status: "active") }
  scope :inactive, -> { where(status: "inactive") }
  scope :suspended, -> { where(status: "suspended") }
  scope :super_admins, -> { joins(:roles).where(roles: { name: "Super Admin" }) }
  scope :hr_managers, -> { joins(:roles).where(roles: { name: "HR Manager" }) }
  scope :department_heads, -> { joins(:roles).where(roles: { name: "Department Head" }) }
  scope :employees, -> { joins(:roles).where(roles: { name: "Employee" }) }

  # Callbacks
  before_save :downcase_email

  # Instance methods
  def name
    "#{first_name} #{last_name}"
  end

  def active?
    status == "active"
  end

  def inactive?
    status == "inactive"
  end

  def suspended?
    status == "suspended"
  end

  def super_admin?
    has_role?("Super Admin")
  end

  def hr_manager?
    has_role?("HR Manager")
  end

  def department_head?
    has_role?("Department Head")
  end

  def employee?
    has_role?("Employee")
  end

  def has_role?(role_name)
    if association(:roles).loaded?
      roles.any? { |role| role.name == role_name }
    else
      roles.exists?(name: role_name)
    end
  end

  def has_permission?(resource, action)
    # Any role that can see Payroll / Salary Structures / Attendance / Leave
    # can also see basic employee information used in those modules.
    if resource == "employees" && action == "index"
      helper_modules = %w[payrolls salary_structures attendance_records leave_requests]
      if roles_with_permissions_loaded?
        has_helper = roles.any? do |role|
          role.permissions.any? { |p| helper_modules.include?(p.resource) && p.action == "index" }
        end
        return true if has_helper
      else
        has_helper_access = roles.joins(:permissions)
                                 .where(permissions: { resource: helper_modules, action: "index" })
                                 .exists?
        return true if has_helper_access
      end
    end

    if roles_with_permissions_loaded?
      return roles.any? do |role|
        role.permissions.any? { |p| p.resource == resource && p.action == action }
      end
    end

    user_role_ids = UserRole.where(user_id: id).pluck(:role_id)
    return false if user_role_ids.empty?

    RolePermission.joins(:role, :permission)
                  .where(roles: { id: user_role_ids })
                  .where(permissions: { resource: resource, action: action })
                  .exists?
  end

  def permission_strings
    if roles_with_permissions_loaded?
      roles.flat_map(&:permissions).uniq.map { |p| "#{p.resource}:#{p.action}" }
    else
      permissions.pluck(:resource, :action).map { |r, a| "#{r}:#{a}" }
    end
  end

  def permissions
    Permission.joins(role_permissions: :role).where(roles: { id: role_ids }).distinct
  end

  def can_access_module?(module_name)
    return true if super_admin?

    has_permission?(module_name, "index") || has_permission?(module_name, "show")
  end

  def can_manage_module?(module_name)
    return true if super_admin?

    has_permission?(module_name, "create") || has_permission?(module_name, "update") || has_permission?(module_name, "destroy")
  end

  def can_approve_in_module?(module_name)
    return true if super_admin?

    has_permission?(module_name, "approve") || has_permission?(module_name, "reject")
  end

  def can_export_from_module?(module_name)
    return true if super_admin?

    has_permission?(module_name, "export") || has_permission?(module_name, "download")
  end

  def update_last_login!
    # Use update_column to avoid clearing associations
    update_column(:last_login_at, Time.current)
    update_column(:updated_at, Time.current)
  end

  private

  def roles_with_permissions_loaded?
    association(:roles).loaded? && roles.all? { |role| role.association(:permissions).loaded? }
  end

  def downcase_email
    self.email = email.downcase if email.present?
  end

  def roles_belong_to_company
    return if company_id.blank?

    roles.each do |role|
      next if role.system_role?
      next if role.company_id == company_id

      errors.add(:roles, "cannot include roles from another company")
    end
  end
end
