class Employee < ApplicationRecord
  belongs_to :department

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

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true
  validates :designation, presence: true
  validates :date_of_joining, presence: true
  # validates :date_of_birth, presence: true
  # validates :status, presence: true, inclusion: { in: %w[active inactive terminated probation] }

  # Scopes
  scope :active, -> { where(status: "active") }
  scope :inactive, -> { where(status: "inactive") }
  scope :terminated, -> { where(status: "terminated") }
  scope :probation, -> { where(status: "probation") }
  scope :by_department, ->(department_id) { where(department_id: department_id) }
  scope :by_designation, ->(designation) { where(designation: designation) }
  scope :recent_hires, -> { where("date_of_joining >= ?", 3.months.ago) }
  scope :long_term, -> { where("date_of_joining <= ?", 2.years.ago) }
  scope :birthday_today, -> { where("strftime('%m-%d', date_of_birth) = ?", Date.current.strftime("%m-%d")) }
  scope :birthday_this_week, -> {
    start_of_week = Date.current.beginning_of_week
    end_of_week = Date.current.end_of_week
    where("strftime('%m-%d', date_of_birth) BETWEEN ? AND ?",
          start_of_week.strftime("%m-%d"), end_of_week.strftime("%m-%d"))
  }
  scope :birthday_this_month, -> {
    where("strftime('%m', date_of_birth) = ?", Date.current.strftime("%m"))
  }

  # Helper methods
  def active?
    status == "active"
  end

  def inactive?
    status == "inactive"
  end

  def terminated?
    status == "terminated"
  end

  def probation?
    status == "probation"
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
    # Placeholder for avatar functionality
    "https://ui-avatars.com/api/?name=#{URI.encode_www_form_component(name)}&background=random"
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
    performance_reviews.recent.first
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
    salary_structures.recent.first&.basic || 0
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
end
