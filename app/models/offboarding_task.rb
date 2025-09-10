class OffboardingTask < ApplicationRecord
  belongs_to :offboarding_employee

  # Validations
  validates :title, presence: true
  validates :description, presence: true
  validates :category, presence: true
  validates :priority, presence: true, inclusion: { in: %w[high medium low] }
  validates :due_date, presence: true
  validates :assigned_to, presence: true

  # Scopes
  scope :completed, -> { where(is_completed: true) }
  scope :pending, -> { where(is_completed: false) }
  scope :overdue, -> { where("due_date < ? AND is_completed = ?", Date.current, false) }
  scope :due_soon, -> { where("due_date BETWEEN ? AND ? AND is_completed = ?", Date.current, 3.days.from_now, false) }
  scope :by_category, ->(category) { where(category: category) }
  scope :by_priority, ->(priority) { where(priority: priority) }
  scope :high_priority, -> { where(priority: "high") }
  scope :medium_priority, -> { where(priority: "medium") }
  scope :low_priority, -> { where(priority: "low") }

  # Callbacks
  before_save :set_completed_date
  after_save :update_offboarding_progress

  # Helper methods
  def overdue?
    due_date < Date.current && !is_completed?
  end

  def due_soon?
    due_date.between?(Date.current, 3.days.from_now) && !is_completed?
  end

  def completed_today?
    completed_date == Date.current
  end

  def days_until_due
    return 0 if is_completed?
    (due_date - Date.current).to_i
  end

  def priority_label
    priority.humanize
  end

  def priority_color
    case priority
    when "high"
      "red"
    when "medium"
      "yellow"
    when "low"
      "green"
    else
      "gray"
    end
  end

  def category_icon
    case category.downcase
    when "equipment"
      "laptop"
    when "hr"
      "users"
    when "knowledge transfer"
      "file-text"
    when "benefits"
      "shield"
    when "access"
      "key"
    when "documentation"
      "file-text"
    else
      "check-square"
    end
  end

  def due_date_formatted
    due_date.strftime("%B %d, %Y")
  end

  def completed_date_formatted
    completed_date&.strftime("%B %d, %Y")
  end

  def status_label
    if is_completed?
      "Completed"
    elsif overdue?
      "Overdue"
    elsif due_soon?
      "Due Soon"
    else
      "Pending"
    end
  end

  def status_color
    if is_completed?
      "green"
    elsif overdue?
      "red"
    elsif due_soon?
      "yellow"
    else
      "gray"
    end
  end

  def toggle_completion!
    update(is_completed: !is_completed)
  end

  private

  def set_completed_date
    if is_completed? && completed_date.nil?
      self.completed_date = Date.current
    elsif !is_completed?
      self.completed_date = nil
    end
  end

  def update_offboarding_progress
    offboarding_employee.calculate_progress
    offboarding_employee.save
  end
end
