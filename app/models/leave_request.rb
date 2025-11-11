class LeaveRequest < ApplicationRecord
  belongs_to :employee
  belongs_to :manager_approved_by, class_name: "User", optional: true
  belongs_to :hr_approved_by, class_name: "User", optional: true
  belongs_to :rejected_by, class_name: "User", optional: true

  # Validations
  validates :leave_type, presence: true, inclusion: { in: %w[annual sick personal maternity paternity unpaid other] }
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :reason, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending manager_approved approved rejected cancelled] }
  validate :end_date_after_start_date

  # Scopes
  scope :approved, -> { where(status: "approved") }
  scope :pending, -> { where(status: "pending") }
  scope :rejected, -> { where(status: "rejected") }
  scope :cancelled, -> { where(status: "cancelled") }
  scope :by_type, ->(type) { where(leave_type: type) }
  scope :by_employee, ->(employee_id) { where(employee_id: employee_id) }
  scope :current_year, -> { where("start_date >= ?", Date.current.beginning_of_year) }
  scope :upcoming, -> { where("start_date >= ?", Date.current) }
  scope :past, -> { where("end_date < ?", Date.current) }
  scope :pending_for_manager, ->(manager_employee_id) {
    joins(:employee)
      .where(employees: { manager_id: manager_employee_id })
      .where(status: "pending")
  }

  # Callbacks
  before_save :calculate_days
  before_create :set_default_status

  # Approval helpers
  def manager_approved?
    status == "manager_approved" || approved?
  end

  def hr_approved?
    approved?
  end

  # Helper methods
  def approved?
    status == "approved"
  end

  def pending?
    status == "pending"
  end

  def rejected?
    status == "rejected"
  end

  def cancelled?
    status == "cancelled"
  end

  def duration_days
    return 0 unless start_date && end_date

    if half_day?
      0.5
    else
      (end_date - start_date).to_i + 1
    end
  end

  def half_day?
    half_day == true
  end

  def full_day?
    !half_day?
  end

  def half_day_period_label
    case half_day_period
    when "morning"
      "Morning"
    when "afternoon"
      "Afternoon"
    else
      "Half Day"
    end
  end

  def is_current?
    start_date <= Date.current && end_date >= Date.current
  end

  def is_upcoming?
    start_date > Date.current
  end

  def is_past?
    end_date < Date.current
  end

  def employee_name
    employee.name
  end

  def employee_email
    employee.email
  end

  def employee_department
    employee.department&.name
  end

  def formatted_start_date
    start_date.strftime("%B %d, %Y")
  end

  def formatted_end_date
    end_date.strftime("%B %d, %Y")
  end

  def status_color
    case status
    when "approved"
      "green"
    when "rejected"
      "red"
    when "pending"
      "yellow"
    when "cancelled"
      "gray"
    else
      "gray"
    end
  end

  def status_label
    status.humanize
  end

  def leave_type_label
    case leave_type
    when "annual"
      "Annual Leave"
    when "sick"
      "Sick Leave"
    when "personal"
      "Personal Leave"
    when "maternity"
      "Maternity Leave"
    when "paternity"
      "Paternity Leave"
    when "unpaid"
      "Unpaid Leave"
    when "other"
      "Other"
    else
      leave_type.humanize
    end
  end

  def can_be_cancelled?
    pending? && start_date > Date.current
  end

  def can_be_modified?
    pending? && start_date > Date.current
  end

  def overlaps_with?(other_request)
    return false if other_request.id == id

    start_date <= other_request.end_date && end_date >= other_request.start_date
  end

  def self.employee_leave_balance(employee_id, leave_type, year = Date.current.year)
    start_of_year = Date.new(year, 1, 1)
    end_of_year = Date.new(year, 12, 31)

    approved_requests = where(
      employee_id: employee_id,
      leave_type: leave_type,
      status: "approved",
      start_date: start_of_year..end_of_year
    )

    total_days = approved_requests.sum(:days)

    # Get leave limit from policy
    policy = LeavePolicy.for_year(year)
    limit = policy.leave_limit_for_type(leave_type)
    remaining = [ limit - total_days, 0 ].max

    {
      total: limit,
      used: total_days,
      remaining: remaining
    }
  end

  def self.employee_leave_summary(employee_id, year = Date.current.year)
    leave_types = %w[annual sick personal maternity paternity unpaid other]

    leave_types.map do |type|
      balance = employee_leave_balance(employee_id, type, year)
      {
        leave_type: type,
        leave_type_label: type.humanize,
        total: balance[:total],
        used: balance[:used],
        remaining: balance[:remaining]
      }
    end
  end

  def self.team_leave_calendar(team_employee_ids, start_date, end_date)
    where(
      employee_id: team_employee_ids,
      start_date: start_date..end_date,
      status: "approved"
    ).includes(:employee).order(:start_date)
  end

  def self.department_leave_stats(department_id, year = Date.current.year)
    start_of_year = Date.new(year, 1, 1)
    end_of_year = Date.new(year, 12, 31)

    requests = joins(:employee)
              .where(employees: { department_id: department_id })
              .where(start_date: start_of_year..end_of_year)

    {
      total_requests: requests.size,
      approved_requests: requests.approved.size,
      pending_requests: requests.pending.size,
      rejected_requests: requests.rejected.size,
      total_days_taken: requests.approved.sum(:days),
      by_leave_type: requests.approved.group(:leave_type).sum(:days)
    }
  end

  private

  def calculate_days
    self.days = duration_days if start_date && end_date
  end

  def set_default_status
    self.status ||= "pending"
  end

  def end_date_after_start_date
    return unless start_date && end_date

    if end_date < start_date
      errors.add(:end_date, "must be after start date")
    end
  end
end
