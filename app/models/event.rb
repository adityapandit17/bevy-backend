class Event < ApplicationRecord
  belongs_to :organizer, class_name: "User", foreign_key: :organizer_id, optional: true

  # Validations
  validates :title, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :event_type, inclusion: { in: %w[meeting event training workshop other] }
  validates :status, inclusion: { in: %w[scheduled cancelled completed postponed] }

  validate :end_time_after_start_time

  # Scopes
  scope :upcoming, -> { where("start_time >= ?", Time.current).order(start_time: :asc) }
  scope :past, -> { where("end_time < ?", Time.current).order(start_time: :desc) }
  scope :scheduled, -> { where(status: "scheduled") }
  scope :by_type, ->(type) { where(event_type: type) }
  scope :by_date_range, ->(start_date, end_date) { where(start_time: start_date..end_date) }

  # Serialize attendee_ids as array
  serialize :attendee_ids, type: Array, coder: JSON

  # Helper methods
  def attendee_ids_list
    attendee_ids || []
  end

  def attendee_ids_list=(value)
    self.attendee_ids = value.is_a?(Array) ? value : []
  end

  def formatted_start_time
    start_time&.strftime("%B %d, %Y at %I:%M %p")
  end

  def formatted_end_time
    end_time&.strftime("%B %d, %Y at %I:%M %p")
  end

  def duration_hours
    return 0 unless start_time && end_time
    ((end_time - start_time) / 1.hour).round(2)
  end

  def is_upcoming?
    start_time >= Time.current
  end

  def is_past?
    end_time < Time.current
  end

  def is_ongoing?
    Time.current >= start_time && Time.current <= end_time
  end

  private

  def end_time_after_start_time
    return unless start_time && end_time

    if end_time <= start_time
      errors.add(:end_time, "must be after start time")
    end
  end
end
