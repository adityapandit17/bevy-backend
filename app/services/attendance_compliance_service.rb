# Calculates worked hours vs company weekly-hour targets for attendance compliance.
class AttendanceComplianceService
  WORKDAYS_PER_WEEK = 5

  def initialize(employee:, start_date: nil, end_date: nil, as_of: Date.current)
    @employee = employee
    @start_date = start_date || as_of.beginning_of_month
    @end_date = end_date || as_of.end_of_month
    @as_of = [as_of, @end_date].min
    @company = Company.first
  end

  def weekly_working_hours
    (@company&.weekly_working_hours || 40).to_f
  end

  def daily_target_hours
    weekly_working_hours / WORKDAYS_PER_WEEK
  end

  def summary
    records = attendance_records_scope
    leave_days = approved_leave_dates

    total_hours = records.sum { |r| r.working_hours.to_f.positive? ? r.working_hours.to_f : r.total_hours.to_f }
    workdays_in_range = workdays_between(@start_date, @end_date)
    workdays_elapsed = workdays_between(@start_date, @as_of)
    required_full_month = daily_target_hours * workdays_in_range
    required_to_date = daily_target_hours * workdays_elapsed

    days_with_records = records.index_by(&:date)
    present_count = 0
    absent_count = 0
    not_marked_count = 0
    leave_count = 0

    (@start_date..@as_of).each do |day|
      next if weekend?(day)

      if leave_days.include?(day)
        leave_count += 1
        next
      end

      record = days_with_records[day]
      if record.nil?
        not_marked_count += 1 if day < @as_of
      elsif record.status == "absent"
        absent_count += 1
      else
        present_count += 1
      end
    end

    average_daily_hours = if present_count.positive?
      (total_hours / present_count).round(2)
    else
      0.0
    end

    hours_behind = [required_to_date - total_hours, 0].max.round(2)
    compliance_percent = if required_to_date.positive?
      [(total_hours / required_to_date * 100).round(1), 100].min
    else
      100.0
    end

    {
      weekly_working_hours: weekly_working_hours,
      daily_target_hours: daily_target_hours.round(2),
      workdays_in_month: workdays_in_range,
      workdays_elapsed: workdays_elapsed,
      total_hours_worked: total_hours.round(2),
      required_hours_month: required_full_month.round(2),
      required_hours_to_date: required_to_date.round(2),
      average_daily_hours: average_daily_hours,
      hours_behind_schedule: hours_behind,
      compliance_percent: compliance_percent,
      present_days: present_count,
      absent_days: absent_count,
      not_marked_days: not_marked_count,
      leave_days: leave_count,
      work_start_time: @company&.work_start_time || "09:00",
      work_end_time: @company&.work_end_time || "18:00"
    }
  end

  def calendar_days
    records = attendance_records_scope.index_by(&:date)
    leave_days = approved_leave_dates

    (@start_date..@end_date).map do |day|
      indicator = day_indicator(day, records[day], leave_days)
      record = records[day]
      {
        date: day.iso8601,
        indicator: indicator,
        status: record&.status,
        working_hours: record ? (record.working_hours.to_f.positive? ? record.working_hours.to_f : record.total_hours.to_f) : nil,
        status_label: record&.status_label
      }
    end
  end

  def self.team_report(start_date: nil, end_date: nil, as_of: Date.current, department_id: nil)
    start_date ||= as_of.beginning_of_month
    end_date ||= as_of.end_of_month

    scope = Employee.active.includes(:department)
    scope = scope.where(department_id: department_id) if department_id.present?

    scope.map do |employee|
      service = new(employee: employee, start_date: start_date, end_date: end_date, as_of: as_of)
      summary = service.summary
      {
        employee_id: employee.id,
        employee_name: employee.full_name,
        department_id: employee.department_id,
        department_name: employee.department&.name,
        **summary
      }
    end.sort_by { |row| -row[:hours_behind_schedule] }
  end

  private

  def attendance_records_scope
    AttendanceRecord.includes(:attendance_sessions)
                    .where(employee_id: @employee.id, date: @start_date..@end_date)
  end

  def approved_leave_dates
    LeaveRequest.where(employee_id: @employee.id, status: %w[approved manager_approved])
                .where("start_date <= ? AND end_date >= ?", @end_date, @start_date)
                .flat_map { |lr| (lr.start_date..lr.end_date).to_a }
                .to_set
  end

  def day_indicator(day, record, leave_days)
    return "future" if day > @as_of
    return "weekend" if weekend?(day)
    return "leave" if leave_days.include?(day)

    if record.nil?
      return "not_marked" if day <= @as_of
      return "none"
    end

    case record.status
    when "absent"
      "absent"
    when "present", "late", "half_day", "work_from_home"
      "present"
    else
      "not_marked"
    end
  end

  def workdays_between(from_date, to_date)
    return 0 if to_date < from_date

    (from_date..to_date).count { |d| !weekend?(d) }
  end

  def weekend?(day)
    day.saturday? || day.sunday?
  end
end
