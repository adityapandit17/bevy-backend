class LeaveRequest < ApplicationRecord
  belongs_to :employee

  # Validations
  validates :leave_type, presence: true, inclusion: { in: %w[annual sick personal maternity paternity unpaid other] }
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :reason, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending approved rejected cancelled] }
  validate :end_date_after_start_date

  # Scopes
  scope :approved, -> { where(status: "approved") }
  scope :pending, -> { where(status: "pending") }
  scope :rejected, -> { where(status: "rejected") }
  scope :by_type, ->(type) { where(leave_type: type) }
  scope :by_employee, ->(employee_id) { where(employee_id: employee_id) }
  scope :current_year, -> { where("start_date >= ?", Date.current.beginning_of_year) }
  scope :upcoming, -> { where("start_date >= ?", Date.current) }
  scope :past, -> { where("end_date < ?", Date.current) }

  # Callbacks
  before_save :calculate_days
  before_create :set_default_status

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
    (end_date - start_date).to_i + 1
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
    when "pending"
      "yellow"
    when "rejected"
      "red"
    when "cancelled"
      "gray"
    else
      "gray"
    end
  end

  def leave_type_label
    leave_type.titleize
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
