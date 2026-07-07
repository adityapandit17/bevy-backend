class Employee < ApplicationRecord
  include TenantScoped
  belongs_to :department
  has_one :user, dependent: :destroy

  # Manager hierarchy
  belongs_to :manager, class_name: "Employee", foreign_key: :manager_id, optional: true
  has_many :direct_reports, class_name: "Employee", foreign_key: :manager_id, dependent: :nullify

  # Existing associations
  has_many :attendance_records, dependent: :destroy
  has_many :leave_requests, dependent: :destroy
  has_many :payrolls, dependent: :destroy
  has_many :salary_structures, dependent: :destroy
  has_many :assets, dependent: :destroy
  has_many :asset_allocations, dependent: :destroy
  has_many :onboarding_employees, dependent: :destroy

  # New associations for employee profile
  has_many :employee_documents, dependent: :destroy
  has_many :performance_reviews, dependent: :destroy
  has_many :performance_goals, dependent: :destroy
  has_many :timesheets, dependent: :destroy
  has_many :employee_benefits, dependent: :destroy
  has_many :employee_trainings, dependent: :destroy
  has_many :offboarding_employees, dependent: :destroy
  has_many :pending_tasks, as: :taskable, dependent: :destroy

  # Validations
  before_validation :normalize_phone
  before_validation :assign_employee_number, on: :create

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: { scope: :company_id }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true
  validate :phone_valid_for_company_country
  validates :designation, presence: true
  validates :date_of_joining, presence: true
  # validates :date_of_birth, presence: true
  validates :status, presence: true, inclusion: { in: %w[active inactive terminated probation onboarding] }
  validates :badge_level, inclusion: { in: %w[rockstar ninja champion expert pro rookie], allow_nil: true }
  validates :employee_number, presence: true, uniqueness: { scope: :company_id }

  enum :status, {
    active: "active",
    inactive: "inactive",
    terminated: "terminated",
    probation: "probation",
    onboarding: "onboarding"
  }, default: "onboarding"

  # Scopes
  scope :active, -> { where(status: "active") }
  scope :inactive, -> { where(status: "inactive") }
  scope :terminated, -> { where(status: "terminated") }
  scope :probation, -> { where(status: "probation") }
  scope :onboarding_pending, -> { where(status: "onboarding") }
  scope :by_department, ->(department_id) { where(department_id: department_id) }
  scope :by_designation, ->(designation) { where(designation: designation) }
  scope :recent_hires, -> { where("date_of_joining >= ?", 3.months.ago) }
  scope :long_term, -> { where("date_of_joining <= ?", 2.years.ago) }
  scope :birthday_today, -> { where("TO_CHAR(date_of_birth, 'MM-DD') = ?", Date.current.strftime("%m-%d")) }
  scope :birthday_this_week, -> {
    start_of_week = Date.current.beginning_of_week
    end_of_week = Date.current.end_of_week
    where("TO_CHAR(date_of_birth, 'MM-DD') BETWEEN ? AND ?",
          start_of_week.strftime("%m-%d"), end_of_week.strftime("%m-%d"))
  }
  scope :birthday_this_month, -> {
    where("TO_CHAR(date_of_birth, 'MM') = ?", Date.current.strftime("%m"))
  }

  # Helper methods
  def active?
    status == "active"
  end

  def inactive?
    status == "inactive"
  end

  # Soft-deactivate the employee record and revoke linked portal access.
  def deactivate!
    transaction do
      update!(status: "inactive") unless inactive?
      user&.update!(status: "inactive") unless user.nil? || user.inactive?
    end
    self
  end

  def terminated?
    status == "terminated"
  end

  def probation?
    status == "probation"
  end

  def onboarding_pending?
    status == "onboarding"
  end

  def name
    "#{first_name} #{last_name}"
  end

  def department_name
    department.name
  end

  def formatted_hire_date
    date_of_joining.strftime("%B %d, %Y")
  end

  def tenure_years
    ((Date.current - date_of_joining) / 365.25).to_i
  end

  def tenure_months
    ((Date.current - date_of_joining) / 30.44).to_i
  end

  def tenure_summary
    if tenure_years > 0
      "#{tenure_years} year#{tenure_years > 1 ? 's' : ''}"
    else
      "#{tenure_months} month#{tenure_months > 1 ? 's' : ''}"
    end
  end

  def status_color
    case status
    when "active"
      "green"
    when "inactive"
      "gray"
    when "terminated"
      "red"
    when "probation"
      "yellow"
    else
      "gray"
    end
  end

  def status_label
    status.titleize
  end

  def full_name
    name
  end

  def initials
    "#{first_name.first}#{last_name.first}".upcase
  end

  def avatar_url
    if user&.avatar&.attached?
      user.avatar_url
    else
      "https://ui-avatars.com/api/?name=#{URI.encode_www_form_component(name)}&background=random"
    end
  end

  def display_id
    code = company&.code.presence || "EMP"
    "#{code}-#{employee_number.to_s.rjust(3, '0')}"
  end

  def manager_name
    manager&.name
  end

  # Profile statistics
  def total_leave_days_this_year
    leave_requests.approved.current_year.sum(:days)
  end

  def pending_leave_requests
    leave_requests.pending.size
  end

  def total_assets
    assets.size
  end

  def assigned_assets
    assets.assigned.size
  end

  def total_documents
    employee_documents.size
  end

  def active_documents
    employee_documents.active.size
  end

  def expiring_documents
    employee_documents.expiring_soon.size
  end

  def latest_performance_review
    performance_reviews.first
  end

  def average_performance_rating
    reviews = performance_reviews.where.not(rating: nil)
    return 0 if reviews.empty?

    reviews.average(:rating).round(2)
  end

  def total_training_hours
    employee_trainings.completed.sum(:hours)
  end

  def active_trainings
    employee_trainings.in_progress.size
  end

  def total_benefits_cost
    employee_benefits.active.sum(:cost)
  end

  def weekly_hours_this_month
    timesheets.this_month.approved.sum(:hours)
  end

  def profile_completion_percentage
    # Calculate profile completion based on filled fields
    fields = [ first_name, last_name, email, phone, designation, date_of_joining, department_id ]
    filled_fields = fields.compact.size
    (filled_fields.to_f / fields.size * 100).round(1)
  end

  # Alias methods for compatibility
  def position
    designation
  end

  def hire_date
    date_of_joining
  end

  def salary
    # This would need to be implemented based on salary structure
    salary_structures.first&.basic || 0
  end

  # Birthday methods
  def birthday_today?
    return false unless date_of_birth

    date_of_birth.strftime("%m-%d") == Date.current.strftime("%m-%d")
  end

  def birthday_this_week?
    return false unless date_of_birth

    start_of_week = Date.current.beginning_of_week
    end_of_week = Date.current.end_of_week
    birthday_month_day = date_of_birth.strftime("%m-%d")
    start_month_day = start_of_week.strftime("%m-%d")
    end_month_day = end_of_week.strftime("%m-%d")

    birthday_month_day.between?(start_month_day, end_month_day)
  end

  def birthday_this_month?
    return false unless date_of_birth

    date_of_birth.strftime("%m") == Date.current.strftime("%m")
  end

  def age
    return nil unless date_of_birth

    today = Date.current
    age = today.year - date_of_birth.year
    age -= 1 if today < date_of_birth + age.years
    age
  end

  def next_birthday
    return nil unless date_of_birth

    today = Date.current
    this_year_birthday = Date.new(today.year, date_of_birth.month, date_of_birth.day)

    if this_year_birthday >= today
      this_year_birthday
    else
      Date.new(today.year + 1, date_of_birth.month, date_of_birth.day)
    end
  end

  def days_until_birthday
    return nil unless next_birthday

    (next_birthday - Date.current).to_i
  end

  def birthday_formatted
    return "Not set" unless date_of_birth

    date_of_birth.strftime("%B %d")
  end

  # Badge level methods
  def self.badge_levels
    %w[rockstar ninja champion expert pro rookie]
  end

  def badge_level_label
    return nil unless badge_level
    badge_level.titleize
  end

  def badge_level_color
    case badge_level
    when "rockstar"
      "purple"
    when "ninja"
      "indigo"
    when "champion"
      "gold"
    when "expert"
      "blue"
    when "pro"
      "green"
    when "rookie"
      "gray"
    else
      "gray"
    end
  end

  private

  # Normalizes phone numbers to either:
  # - "+<digits>" (E.164-like) when a leading "+" was provided, or
  # - "<digits>" when no "+" was provided
  # and strips spaces/dashes/parentheses.
  def normalize_phone
    return if phone.blank?

    raw = phone.to_s.strip

    # Keep leading plus if provided; otherwise strip everything to digits.
    if raw.start_with?("+")
      digits = raw.gsub(/\D/, "")
      self.phone = "+#{digits}"
      return
    end

    self.phone = raw.gsub(/\D/, "")
  end

  def phone_valid_for_company_country
    return if phone.blank?

    # Single-tenant: company settings come from the first (and only) Company record
    # Fallback to "IN" so validation is deterministic even if settings aren't saved yet.
    country = (company&.country_code.presence || ActsAsTenant.current_tenant&.country_code.presence || "IN").to_s.upcase

    # Phonelib expects ISO3166-1 alpha-2 (e.g. "IN", "US")
    raw = phone.to_s
    parsed = Phonelib.parse(raw, country)

    # India-specific tolerance:
    # - Allow leading 0 (common domestic format) by stripping it
    # - Allow numbers provided as 91XXXXXXXXXX without leading "+" by converting to +91XXXXXXXXXX
    if (country == "IN") && (!parsed.valid?)
      digits = raw.gsub(/\D/, "")

      if digits.length == 11 && digits.start_with?("0")
        parsed = Phonelib.parse(digits[1..], "IN")
        self.phone = digits[1..] if parsed.valid?
      elsif digits.length == 12 && digits.start_with?("91")
        parsed = Phonelib.parse("+#{digits}", "IN")
        self.phone = "+#{digits}" if parsed.valid?
      end
    end

    errors.add(:phone, "is not a valid phone number for country #{country}") unless parsed&.valid?
  rescue NameError
    # If phonelib isn't installed/loaded yet, fail safe with a minimal check
    errors.add(:phone, "must be a valid phone number")
  end

  def assign_employee_number
    return if employee_number.present?
    return if company_id.blank?

    scope = self.class.unscoped.where(company_id: company_id)
    scope = scope.where.not(id: id) if persisted?
    self.employee_number = (scope.maximum(:employee_number) || 0) + 1
  end
end
