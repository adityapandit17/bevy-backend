class AttendanceRecord < ApplicationRecord
  belongs_to :employee

  # Validations
  validates :date, presence: true
  validates :status, presence: true, inclusion: { in: %w[present absent late half_day work_from_home early_departure] }
  validates :employee_id, uniqueness: { scope: :date, message: "already has attendance record for this date" }
  validate :check_out_after_check_in
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
  before_save :calculate_working_hours
  before_save :determine_status

  # Helper methods
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
    return 0 unless check_in && check_out
    ((check_out - check_in) / 1.hour).round(2)
  end

  def overtime_hours
    return 0 unless working_hours > 8
    working_hours - 8
  end

  def is_late?
    return false unless check_in
    check_in > Time.parse("09:00")
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
    check_in&.strftime("%I:%M %p")
  end

  def formatted_check_out
    check_out&.strftime("%I:%M %p")
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

  private

  def calculate_working_hours
    return unless check_in && check_out
    self.working_hours = ((check_out - check_in) / 1.hour).round(2)
  end

  def determine_status
    return if status.present? && status != "present"
    
    if check_in.blank? && check_out.blank?
      self.status = "absent"
    elsif check_in.present? && check_out.blank?
      self.status = "present"
    elsif check_in.present? && check_out.present?
      if working_hours < 4
        self.status = "half_day"
      elsif is_late?
        self.status = "late"
      else
        self.status = "present"
      end
    end
  end

  def check_out_after_check_in
    return unless check_in && check_out
    errors.add(:check_out, "must be after check in time") if check_out <= check_in
  end

  def date_not_in_future
    return unless date
    errors.add(:date, "cannot be in the future") if date > Date.current
  end
end
