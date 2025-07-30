class EmployeeTraining < ApplicationRecord
  belongs_to :employee

  # Validations
  validates :name, presence: true
  validates :training_type, presence: true, inclusion: { in: %w[technical soft_skills compliance leadership certification other] }
  validates :provider, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :status, presence: true, inclusion: { in: %w[not_started in_progress completed cancelled failed] }
  validates :progress, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :cost, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Scopes
  scope :by_employee, ->(employee_id) { where(employee_id: employee_id) }
  scope :by_type, ->(type) { where(training_type: type) }
  scope :by_status, ->(status) { where(status: status) }
  scope :completed, -> { where(status: 'completed') }
  scope :in_progress, -> { where(status: 'in_progress') }
  scope :not_started, -> { where(status: 'not_started') }
  scope :by_provider, ->(provider) { where(provider: provider) }
  scope :current, -> { where('start_date <= ? AND end_date >= ?', Date.current, Date.current) }
  scope :upcoming, -> { where('start_date > ?', Date.current) }
  scope :past, -> { where('end_date < ?', Date.current) }
  scope :recent, -> { order(start_date: :desc) }

  # Callbacks
  before_save :update_status_based_on_progress
  before_save :check_completion_status

  # Helper methods
  def not_started?
    status == 'not_started'
  end

  def in_progress?
    status == 'in_progress'
  end

  def completed?
    status == 'completed'
  end

  def cancelled?
    status == 'cancelled'
  end

  def failed?
    status == 'failed'
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

  def is_overdue?
    end_date < Date.current && !completed? && !cancelled?
  end

  def days_until_start
    return nil if is_past?
    (start_date - Date.current).to_i
  end

  def days_until_end
    return nil if is_past?
    (end_date - Date.current).to_i
  end

  def duration_days
    (end_date - start_date).to_i + 1
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

  def training_type_label
    training_type.titleize
  end

  def formatted_start_date
    start_date.strftime('%B %d, %Y')
  end

  def formatted_end_date
    end_date.strftime('%B %d, %Y')
  end

  def status_color
    case status
    when 'completed'
      'green'
    when 'in_progress'
      'blue'
    when 'not_started'
      'gray'
    when 'cancelled'
      'gray'
    when 'failed'
      'red'
    else
      'gray'
    end
  end

  def status_label
    case status
    when 'not_started'
      'Not Started'
    when 'in_progress'
      'In Progress'
    when 'completed'
      'Completed'
    when 'cancelled'
      'Cancelled'
    when 'failed'
      'Failed'
    else
      status.titleize
    end
  end

  def progress_color
    if progress >= 80
      'green'
    elsif progress >= 60
      'blue'
    elsif progress >= 40
      'yellow'
    else
      'red'
    end
  end

  def cost_formatted
    "₹#{cost.to_f.round(2)}"
  end

  def skills_list
    skills&.split(',')&.map(&:strip) || []
  end

  def has_certificate?
    certificate.present?
  end

  def certificate_url
    certificate if has_certificate?
  end

  def training_summary
    "#{name} (#{provider})"
  end

  def duration_summary
    "#{formatted_start_date} to #{formatted_end_date} (#{duration_days} days)"
  end

  def completion_status
    if completed?
      "Completed on #{formatted_end_date}"
    elsif in_progress?
      "#{progress}% complete"
    elsif is_overdue?
      "#{days_until_end.abs} days overdue"
    elsif is_upcoming?
      "Starts in #{days_until_start} days"
    else
      "Not started"
    end
  end

  def can_edit?
    !completed? && !cancelled?
  end

  def can_cancel?
    in_progress? || not_started?
  end

  def can_mark_complete?
    in_progress? && progress >= 100
  end

  private

  def update_status_based_on_progress
    if progress == 100 && in_progress?
      self.status = 'completed'
    elsif progress > 0 && not_started?
      self.status = 'in_progress'
    end
  end

  def check_completion_status
    if end_date < Date.current && in_progress? && progress < 100
      self.status = 'failed'
    end
  end
end
