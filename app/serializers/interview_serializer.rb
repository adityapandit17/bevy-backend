class InterviewSerializer < Panko::Serializer
  attributes :id, :candidate_id, :interview_type, :scheduled_date, :scheduled_time,
             :interviewer, :status, :notes, :feedback, :rating,
             :google_calendar_event_id, :google_calendar_html_link, :google_meet_link,
             :created_at, :updated_at

  # Computed attributes
  attributes :is_today, :is_overdue, :is_upcoming,
             :formatted_time, :formatted_date, :status_color

  def is_today
    object.is_today?
  end

  def is_overdue
    object.is_overdue?
  end

  def is_upcoming
    object.is_upcoming?
  end

  def formatted_time
    object.formatted_time
  end

  def formatted_date
    object.formatted_date
  end

  def status_color
    object.status_color
  end
end
