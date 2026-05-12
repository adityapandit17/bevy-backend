class Interview < ApplicationRecord
  include BelongsToTenant

  belongs_to :candidate
  has_many :pending_tasks, as: :taskable, dependent: :destroy

  validates :interview_type, presence: true, inclusion: { in: %w[phone video onsite] }
  validates :scheduled_date, presence: true
  validates :scheduled_time, presence: true
  validates :interviewer, presence: true
  validates :status, presence: true, inclusion: { in: %w[scheduled completed cancelled no_show] }
  validates :rating, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }, allow_nil: true
  validate :candidate_not_rejected

  scope :scheduled, -> { where(status: "scheduled") }
  scope :completed, -> { where(status: "completed") }
  scope :upcoming, -> { where("scheduled_date >= ?", Date.current) }
  scope :past, -> { where("scheduled_date < ?", Date.current) }
  scope :today, -> { where(scheduled_date: Date.current) }
  scope :this_week, -> { where(scheduled_date: Date.current.beginning_of_week..Date.current.end_of_week) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_type, ->(interview_type) { where(interview_type: interview_type) }

  # Callbacks
  after_save :sync_pending_tasks
  after_destroy :cleanup_pending_tasks

  def scheduled_datetime
    DateTime.new(scheduled_date.year, scheduled_date.month, scheduled_date.day,
                 scheduled_time.hour, scheduled_time.min, scheduled_time.sec)
  end

  def is_today?
    scheduled_date == Date.current
  end

  def is_overdue?
    scheduled_date < Date.current && status == "scheduled"
  end

  def is_upcoming?
    scheduled_date > Date.current
  end

  def formatted_time
    scheduled_time.strftime("%I:%M %p")
  end

  def formatted_date
    scheduled_date.strftime("%B %d, %Y")
  end

  def status_color
    case status
    when "scheduled"
      "blue"
    when "completed"
      "green"
    when "cancelled"
      "red"
    when "no_show"
      "orange"
    else
      "gray"
    end
  end

  private

  def assign_company_from_current
    self.company_id ||= candidate&.company_id || Current.company&.id
  end

  def candidate_not_rejected
    if candidate&.status == "rejected"
      errors.add(:candidate, "cannot schedule interviews for rejected candidates")
    end
  end

  def sync_pending_tasks
    PendingTaskService.sync_interview(self)
  end

  def cleanup_pending_tasks
    pending_tasks.destroy_all
  end
end
