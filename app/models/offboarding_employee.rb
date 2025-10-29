class OffboardingEmployee < ApplicationRecord
  belongs_to :employee
  has_many :offboarding_tasks, dependent: :destroy

  # Validations
  validates :employee_id, presence: true, uniqueness: true
  validates :last_working_day, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending in_progress completed cancelled] }
  validates :progress, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  # Scopes
  scope :active, -> { where(status: [ "pending", "in_progress" ]) }
  scope :completed, -> { where(status: "completed") }
  scope :pending, -> { where(status: "pending") }
  scope :in_progress, -> { where(status: "in_progress") }
  scope :cancelled, -> { where(status: "cancelled") }
  scope :recent, -> { where("created_at >= ?", 30.days.ago) }
  scope :by_department, ->(department_id) { joins(:employee).where(employees: { department_id: department_id }) }

  # Callbacks
  before_save :calculate_progress
  after_update :update_status_based_on_progress

  # Helper methods
  def active?
    %w[pending in_progress].include?(status)
  end

  def completed?
    status == "completed"
  end

  def cancelled?
    status == "cancelled"
  end

  def days_remaining
    return 0 if last_working_day.nil?
    remaining = (last_working_day - Date.current).to_i
    remaining > 0 ? remaining : 0
  end

  def overdue?
    days_remaining == 0 && !completed?
  end

  def duration_days
    return 0 if start_date.nil?

    end_date = completed? ? updated_at.to_date : Date.current
    (end_date - start_date).to_i
  end

  def employee_name
    employee.name
  end

  def employee_email
    employee.email
  end

  def employee_department
    employee.department.name
  end

  def employee_position
    employee.designation
  end

  def employee_id_code
    employee.id
  end

  def start_date_formatted
    start_date&.strftime("%B %d, %Y")
  end

  def last_working_day_formatted
    last_working_day&.strftime("%B %d, %Y")
  end

  def status_label
    status.humanize
  end

  def status_color
    case status
    when "completed"
      "green"
    when "in_progress"
      "blue"
    when "pending"
      "yellow"
    when "cancelled"
      "red"
    else
      "gray"
    end
  end

  def calculate_progress
    return if offboarding_tasks.empty?

    completed_tasks = offboarding_tasks.where(is_completed: true).size
    total_tasks = offboarding_tasks.size
    self.progress = total_tasks > 0 ? ((completed_tasks.to_f / total_tasks) * 100).round : 0
  end

  private

  def update_status_based_on_progress
    return if status == "cancelled"

    if progress == 100
      update_column(:status, "completed") unless status == "completed"
    elsif progress > 0
      update_column(:status, "in_progress") unless status == "in_progress"
    else
      update_column(:status, "pending") unless status == "pending"
    end
  end
end
