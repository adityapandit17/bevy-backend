class Interview < ApplicationRecord
  belongs_to :candidate
  belongs_to :interviewer_employee, class_name: "Employee", optional: true
  has_many :pending_tasks, as: :taskable, dependent: :destroy

  validates :interview_type, presence: true, inclusion: { in: %w[phone video onsite] }
  validates :scheduled_date, presence: true
  validates :scheduled_time, presence: true
  validates :interviewer, presence: true
  validates :status, presence: true, inclusion: { in: %w[scheduled completed cancelled no_show] }
  validates :duration_minutes, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 480 }, allow_nil: true
  validates :rating, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }, allow_nil: true
  validate :candidate_not_rejected
  validate :scheduled_datetime_not_in_past, if: :scheduled_status_with_datetime?

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
  after_commit :enqueue_google_calendar_sync, on: %i[create update]
  before_destroy :capture_google_calendar_event_id
  after_commit :enqueue_google_calendar_deletion, on: :destroy

  def scheduled_datetime
    zone = ActiveSupport::TimeZone[calendar_time_zone] || Time.zone
    time_value = scheduled_time
    time_str = if time_value.respond_to?(:strftime)
      time_value.strftime("%H:%M:%S")
    else
      time_value.to_s
    end

    zone.parse("#{scheduled_date} #{time_str}") || zone.local(
      scheduled_date.year,
      scheduled_date.month,
      scheduled_date.day,
      time_value.hour,
      time_value.min,
      time_value.sec
    )
  end

  def calendar_time_zone
    GoogleCalendarTimezone.normalize(Company.first&.timezone)
  rescue NameError
    ENV.fetch("GOOGLE_CALENDAR_TIME_ZONE", "UTC")
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

  def candidate_not_rejected
    if candidate&.status == "rejected"
      errors.add(:candidate, "cannot schedule interviews for rejected candidates")
    end
  end

  def scheduled_status_with_datetime?
    status == "scheduled" && scheduled_date.present? && scheduled_time.present?
  end

  def scheduled_datetime_not_in_past
    dt = scheduled_datetime
    return unless dt

    if dt < Time.current
      errors.add(:base, "cannot schedule interviews in the past")
    end
  end

  def sync_pending_tasks
    PendingTaskService.sync_interview(self)
  end

  def cleanup_pending_tasks
    pending_tasks.destroy_all
  end

  def enqueue_google_calendar_sync
    return unless GoogleCalendarService.enabled?
    return unless status == "scheduled" || google_calendar_event_id.present?

    SyncInterviewCalendarJob.perform_later(id)
  end

  def capture_google_calendar_event_id
    @google_calendar_event_id_for_deletion = google_calendar_event_id
  end

  def enqueue_google_calendar_deletion
    return unless GoogleCalendarService.enabled?
    return if @google_calendar_event_id_for_deletion.blank?

    SyncInterviewCalendarJob.perform_later(
      nil,
      google_calendar_event_id: @google_calendar_event_id_for_deletion
    )
  end
end
