class PendingTask < ApplicationRecord
  belongs_to :taskable, polymorphic: true
  belongs_to :assigned_to, class_name: "Employee", foreign_key: :assigned_to_id, optional: true

  # Validations
  validates :title, presence: true
  validates :priority, presence: true, inclusion: { in: %w[low medium high] }
  validates :status, presence: true, inclusion: { in: %w[pending completed cancelled] }

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :completed, -> { where(status: "completed") }
  scope :cancelled, -> { where(status: "cancelled") }
  scope :high_priority, -> { where(priority: "high") }
  scope :medium_priority, -> { where(priority: "medium") }
  scope :low_priority, -> { where(priority: "low") }
  scope :overdue, -> { where("due_date < ?", Date.current).pending }
  scope :due_today, -> { where(due_date: Date.current).pending }
  scope :upcoming, -> { where("due_date >= ?", Date.current).pending }
  scope :for_employee, ->(employee_id) { where(assigned_to_id: employee_id) }
  scope :by_type, ->(type) { where(taskable_type: type) }

  # Instance methods
  def overdue?
    due_date.present? && due_date < Date.current && pending?
  end

  def due_today?
    due_date == Date.current && pending?
  end

  def upcoming?
    due_date.present? && due_date > Date.current && pending?
  end

  def pending?
    status == "pending"
  end

  def completed?
    status == "completed"
  end

  def cancelled?
    status == "cancelled"
  end

  def mark_completed!
    update(status: "completed")
  end

  def mark_cancelled!
    update(status: "cancelled")
  end
end
