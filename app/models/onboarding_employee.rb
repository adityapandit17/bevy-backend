class OnboardingEmployee < ApplicationRecord
  belongs_to :employee
  has_many :onboarding_tasks, dependent: :destroy

  validates :start_date, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending in_progress completed] }
  validates :progress, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  before_save :calculate_progress

  scope :active, -> { where(status: %w[pending in_progress]) }
  scope :completed, -> { where(status: 'completed') }
  scope :pending, -> { where(status: 'pending') }
  scope :in_progress, -> { where(status: 'in_progress') }
  scope :by_status, ->(status) { where(status: status) }

  def calculate_progress
    return if onboarding_tasks.empty?
    
    completed_tasks = onboarding_tasks.where(is_completed: true).count
    total_tasks = onboarding_tasks.count
    self.progress = total_tasks > 0 ? ((completed_tasks.to_f / total_tasks) * 100).round : 0
    
    # Update status based on progress
    if self.progress == 100
      self.status = 'completed'
    elsif self.progress > 0
      self.status = 'in_progress'
    else
      self.status = 'pending'
    end
  end

  def employee_name
    "#{employee.first_name} #{employee.last_name}"
  end

  def department_name
    employee.department&.name
  end

  def position
    employee.designation
  end

  def email
    employee.email
  end
end
