class PerformanceGoal < ApplicationRecord
  include TenantScoped
  belongs_to :employee

  # Validations
  validates :title, presence: true
  validates :description, presence: true
  validates :target, presence: true
  validates :progress, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :status, presence: true, inclusion: { in: %w[not_started in_progress completed overdue cancelled] }
  validates :due_date, presence: true

  # Scopes
  scope :by_employee, ->(employee_id) { where(employee_id: employee_id) }
  scope :by_status, ->(status) { where(status: status) }
  scope :completed, -> { where(status: "completed") }
  scope :in_progress, -> { where(status: "in_progress") }
  scope :overdue, -> { where("due_date < ? AND status != ?", Date.current, "completed") }
  scope :due_soon, -> { where("due_date BETWEEN ? AND ? AND status != ?", Date.current, Date.current + 7.days, "completed") }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  before_save :update_status_based_on_progress
  before_save :check_overdue_status

  # Helper methods
  def not_started?
    status == "not_started"
  end

  def in_progress?
    status == "in_progress"
  end

  def completed?
    status == "completed"
  end

  def overdue?
    status == "overdue"
  end

  def cancelled?
    status == "cancelled"
  end

  def is_overdue?
    due_date < Date.current && !completed?
  end

  def is_due_soon?
    due_date.between?(Date.current, Date.current + 7.days) && !completed?
  end

  def days_until_due
    return nil if completed?

    (due_date - Date.current).to_i
  end

  def days_overdue
    return 0 unless is_overdue?

    (Date.current - due_date).to_i
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

  def formatted_due_date
    due_date.strftime("%B %d, %Y")
  end

  def status_color
    case status
    when "completed"
      "green"
    when "in_progress"
      "blue"
    when "overdue"
      "red"
    when "not_started"
      "gray"
    when "cancelled"
      "gray"
    else
      "gray"
    end
  end

  def progress_color
    if progress >= 80
      "green"
    elsif progress >= 60
      "blue"
    elsif progress >= 40
      "yellow"
    else
      "red"
    end
  end

  def status_label
    case status
    when "not_started"
      "Not Started"
    when "in_progress"
      "In Progress"
    when "completed"
      "Completed"
    when "overdue"
      "Overdue"
    when "cancelled"
      "Cancelled"
    else
      status.titleize
    end
  end

  def completion_status
    if completed?
      "Completed"
    elsif is_overdue?
      "#{days_overdue} days overdue"
    elsif is_due_soon?
      "Due in #{days_until_due} days"
    else
      "Due on #{formatted_due_date}"
    end
  end

  private

  def update_status_based_on_progress
    if progress == 100
      self.status = "completed"
    elsif progress > 0
      self.status = "in_progress"
    end
  end

  def check_overdue_status
    if due_date < Date.current && !completed? && status != "cancelled"
      self.status = "overdue"
    end
  end
end
