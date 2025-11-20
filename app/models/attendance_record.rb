class AttendanceRecord < ApplicationRecord
  belongs_to :employee
  has_many :attendance_sessions, dependent: :destroy

  # Validations
  validates :date, presence: true
  validates :status, presence: true, inclusion: { in: %w[present absent late half_day work_from_home early_departure] }
  # Removed uniqueness validation to allow multiple check-ins/check-outs per day
  # Removed check_out_after_check_in validation as check_in/check_out are now on sessions
  validate :date_not_in_future

  # Scopes
  scope :present, -> { where(status: "present") }
  scope :absent, -> { where(status: "absent") }
  scope :late, -> { where(status: "late") }
  scope :half_day, -> { where(status: "half_day") }
  scope :work_from_home, -> { where(status: "work_from_home") }
  scope :by_date, ->(date) { where(date: date) }
  scope :by_employee, ->(employee_id) { where(employee_id: employee_id) }
  scope :current_month, -> { where(date: Date.current.beginning_of_month..Date.current.end_of_month) }
  scope :current_year, -> { where(date: Date.current.beginning_of_year..Date.current.end_of_year) }
  scope :recent, -> { where("date >= ?", 30.days.ago) }

  # Callbacks
  before_save :update_working_hours_from_sessions
  before_save :determine_status_from_sessions

  # Helper methods
  def total_hours
    attendance_sessions.sum(:session_hours) || 0.0
  end

  def update_total_hours!
    update(working_hours: total_hours)
  end
  
  def present?
    status == "present"
  end

  def absent?
    status == "absent"
  end

  def late?
    status == "late"
  end

  def half_day?
    status == "half_day"
  end

  def work_from_home?
    status == "work_from_home"
  end

  def working_hours
    # Use stored working_hours if available, otherwise calculate from sessions
    return read_attribute(:working_hours) if read_attribute(:working_hours).present?
    return total_hours if total_hours > 0
    0
  end

  def overtime_hours
    hours = working_hours
    return 0 unless hours > 8
    hours - 8
  end

  def is_late?
    first_session = attendance_sessions.order(created_at: :asc).first
    return false unless first_session&.check_in
    first_session.check_in > Time.parse("09:00")
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

  def formatted_check_in
    first_session = attendance_sessions.order(created_at: :asc).first
    first_session&.check_in&.strftime("%I:%M %p")
  end

  def formatted_check_out
    last_session = attendance_sessions.order(created_at: :desc).first
    last_session&.check_out&.strftime("%I:%M %p")
  end

  def status_color
    case status
    when "present"
      "green"
    when "absent"
      "red"
    when "late"
      "yellow"
    when "half_day"
      "blue"
    when "work_from_home"
      "purple"
    else
      "gray"
    end
  end

  def status_label
    case status
    when "present"
      "Present"
    when "absent"
      "Absent"
    when "late"
      "Late"
    when "half_day"
      "Half Day"
    when "work_from_home"
      "Work from Home"
    else
      status.humanize
    end
  end

  # Class method to calculate total hours for an employee on a specific date
  def self.total_hours_for_day(employee_id, date)
    records = where(employee_id: employee_id, date: date)
    total = 0.0
    
    records.each do |record|
      if record.check_in && record.check_out
        # Calculate hours from check_in and check_out
        duration = record.check_out - record.check_in
        hours = (duration / 1.hour)
        total += hours if hours > 0 && hours < 24 # Sanity check: hours should be between 0 and 24
      elsif record.read_attribute(:working_hours)
        # Use stored working_hours if available
        stored_hours = record.read_attribute(:working_hours)
        if stored_hours && stored_hours > 0 && stored_hours < 24
          total += stored_hours
        end
      end
    end
    
    total.round(2)
  end

  private

  def update_working_hours_from_sessions
    # Update working_hours from sessions - always recalculate to ensure accuracy
    if attendance_sessions.any?
      calculated_hours = total_hours
      # Always update working_hours to be the sum of all session hours
      self.working_hours = calculated_hours.round(2)
    else
      # No sessions means no working hours
      self.working_hours = 0.0
    end
  end

  def determine_status_from_sessions
    return if status.present? && status != "present"

    if attendance_sessions.empty?
      self.status = "absent"
    else
      # Check if there's an active session (no check_out)
      active_session = attendance_sessions.where(check_out: nil).first
      if active_session
        self.status = "present"
      else
        # All sessions are closed, determine status based on hours
        hours = total_hours
        if hours < 4
          self.status = "half_day"
        elsif is_late?
          self.status = "late"
        else
          self.status = "present"
        end
      end
    end
  end

  def date_not_in_future
    return unless date

    errors.add(:date, "cannot be in the future") if date > Date.current
  end
end
