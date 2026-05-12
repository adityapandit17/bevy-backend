class Timesheet < ApplicationRecord
  include BelongsToTenant

  belongs_to :employee

  # Validations
  validates :date, presence: true
  validates :hours, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 24 }
  validates :project, presence: true
  validates :task, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending approved rejected] }

  # Scopes
  scope :by_employee, ->(employee_id) { where(employee_id: employee_id) }
  scope :by_status, ->(status) { where(status: status) }
  scope :approved, -> { where(status: "approved") }
  scope :pending, -> { where(status: "pending") }
  scope :rejected, -> { where(status: "rejected") }
  scope :by_project, ->(project) { where(project: project) }
  scope :by_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :this_week, -> { where(date: Date.current.beginning_of_week..Date.current.end_of_week) }
  scope :this_month, -> { where(date: Date.current.beginning_of_month..Date.current.end_of_month) }
  scope :recent, -> { order(date: :desc) }

  # Callbacks
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

  def employee_name
    employee.name
  end

  def employee_email
    employee.email
  end

  def employee_department
    employee.department&.name
  end

  def formatted_date
    date.strftime("%B %d, %Y")
  end

  def formatted_hours
    "#{hours} hours"
  end

  def status_color
    case status
    when "approved"
      "green"
    when "pending"
      "yellow"
    when "rejected"
      "red"
    else
      "gray"
    end
  end

  def status_label
    status.titleize
  end

  def is_today?
    date == Date.current
  end

  def is_this_week?
    date.between?(Date.current.beginning_of_week, Date.current.end_of_week)
  end

  def is_this_month?
    date.between?(Date.current.beginning_of_month, Date.current.end_of_month)
  end

  def hours_decimal
    hours.to_f
  end

  def hours_formatted
    hours_decimal == hours_decimal.to_i ? hours_decimal.to_i.to_s : hours_decimal.to_s
  end

  def project_task_summary
    "#{project} - #{task}"
  end

  def approval_status
    if approved?
      "Approved by #{approved_by}" if approved_by.present?
    elsif rejected?
      "Rejected by #{approved_by}" if approved_by.present?
    else
      "Pending approval"
    end
  end

  def can_edit?
    pending? || (approved? && date >= 1.week.ago)
  end

  def can_delete?
    pending?
  end

  private

  def set_default_status
    self.status ||= "pending"
  end
end
