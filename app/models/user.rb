class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associations
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  belongs_to :employee, optional: true

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :status, presence: true, inclusion: { in: %w[active inactive suspended] }

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }
  scope :suspended, -> { where(status: 'suspended') }
  scope :super_admins, -> { joins(:roles).where(roles: { name: 'Super Admin' }) }
  scope :hr_managers, -> { joins(:roles).where(roles: { name: 'HR Manager' }) }
  scope :department_heads, -> { joins(:roles).where(roles: { name: 'Department Head' }) }
  scope :employees, -> { joins(:roles).where(roles: { name: 'Employee' }) }

  # Callbacks
  before_save :downcase_email

  # Instance methods
  def name
    "#{first_name} #{last_name}"
  end

  def active?
    status == 'active'
  end

  def inactive?
    status == 'inactive'
  end

  def suspended?
    status == 'suspended'
  end

  def super_admin?
    has_role?('Super Admin')
  end

  def hr_manager?
    has_role?('HR Manager')
  end

  def department_head?
    has_role?('Department Head')
  end

  def employee?
    has_role?('Employee')
  end

  def has_role?(role_name)
    roles.exists?(name: role_name)
  end

  def has_permission?(resource, action)
    return true if super_admin? # Super admin has all permissions
    roles.joins(:permissions).where(permissions: { resource: resource, action: action }).exists?
  end

  def permissions
    return Permission.all if super_admin?
    Permission.joins(role_permissions: :role).where(roles: { id: role_ids }).distinct
  end

  def can_access_module?(module_name)
    return true if super_admin?
    has_permission?(module_name, 'index') || has_permission?(module_name, 'show')
  end

  def can_manage_module?(module_name)
    return true if super_admin?
    has_permission?(module_name, 'create') || has_permission?(module_name, 'update') || has_permission?(module_name, 'destroy')
  end

  def can_approve_in_module?(module_name)
    return true if super_admin?
    has_permission?(module_name, 'approve') || has_permission?(module_name, 'reject')
  end

  def can_export_from_module?(module_name)
    return true if super_admin?
    has_permission?(module_name, 'export') || has_permission?(module_name, 'download')
  end

  def update_last_login!
    update!(last_login_at: Time.current)
  end


  private

  def downcase_email
    self.email = email.downcase if email.present?
  end
end
