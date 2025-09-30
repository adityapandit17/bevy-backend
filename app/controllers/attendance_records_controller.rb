class AttendanceRecordsController < ApplicationController
  before_action :set_attendance_record, only: [ :show, :update, :destroy, :check_in, :check_out ]

  def index
    @attendance_records = AttendanceRecord.includes(:employee)

    # Apply filters
    @attendance_records = @attendance_records.by_employee(params[:employee_id]) if params[:employee_id].present?
    @attendance_records = @attendance_records.by_date(params[:date]) if params[:date].present?
    @attendance_records = @attendance_records.where(status: params[:status]) if params[:status].present?
    @attendance_records = @attendance_records.current_month if params[:current_month] == "true"
    @attendance_records = @attendance_records.current_year if params[:current_year] == "true"

    # Apply date range filter
    if params[:start_date].present? && params[:end_date].present?
      @attendance_records = @attendance_records.where(date: params[:start_date]..params[:end_date])
    end

    # Apply search
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @attendance_records = @attendance_records.joins(:employee)
        .where("employees.first_name ILIKE ? OR employees.last_name ILIKE ? OR employees.email ILIKE ?",
               search_term, search_term, search_term)
    end

    render json: @attendance_records.map { |record| format_attendance_record(record) }
  end

  def show
    render json: format_attendance_record(@attendance_record)
  end

  def create
    @attendance_record = AttendanceRecord.new(attendance_record_params)

    if @attendance_record.save
      render json: format_attendance_record(@attendance_record), status: :created
    else
      render json: { errors: @attendance_record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @attendance_record.update(attendance_record_params)
      render json: format_attendance_record(@attendance_record)
    else
      render json: { errors: @attendance_record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @attendance_record.destroy
    head :no_content
  end

  # Check in functionality
  def check_in
    if @attendance_record.check_in.present?
      render json: { error: "Already checked in" }, status: :unprocessable_entity
      return
    end

    @attendance_record.check_in = Time.current
    @attendance_record.status = "present"

    if @attendance_record.save
      render json: format_attendance_record(@attendance_record)
    else
      render json: { errors: @attendance_record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # Check out functionality
  def check_out
    if @attendance_record.check_out.present?
      render json: { error: "Already checked out" }, status: :unprocessable_entity
      return
    end

    if @attendance_record.check_in.blank?
      render json: { error: "Must check in before checking out" }, status: :unprocessable_entity
      return
    end

    @attendance_record.check_out = Time.current

    if @attendance_record.save
      render json: format_attendance_record(@attendance_record)
    else
      render json: { errors: @attendance_record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # Get today's attendance for an employee
  def today
    employee_id = params[:employee_id]
    today = Date.current

    @attendance_record = AttendanceRecord.find_by(employee_id: employee_id, date: today)

    if @attendance_record
      render json: format_attendance_record(@attendance_record)
    else
      # Create a new record for today if it doesn't exist
      @attendance_record = AttendanceRecord.create!(
        employee_id: employee_id,
        date: today,
        status: "absent"
      )
      render json: format_attendance_record(@attendance_record)
    end
  end

  # Get attendance statistics
  def stats
    employee_id = params[:employee_id]
    start_date = params[:start_date] || Date.current.beginning_of_month
    end_date = params[:end_date] || Date.current.end_of_month

    records = AttendanceRecord.where(employee_id: employee_id, date: start_date..end_date)

    stats = {
      total_days: records.count,
      present_days: records.present.count,
      absent_days: records.absent.count,
      late_days: records.late.count,
      half_days: records.half_day.count,
      work_from_home_days: records.work_from_home.count,
      total_working_hours: records.sum(:working_hours),
      average_working_hours: records.average(:working_hours)&.round(2) || 0,
      attendance_percentage: records.count > 0 ? ((records.present.count.to_f / records.count) * 100).round(2) : 0
    }

    render json: stats
  end

  # Get attendance calendar data
  def calendar
    employee_id = params[:employee_id]
    start_date = params[:start_date] || Date.current.beginning_of_month
    end_date = params[:end_date] || Date.current.end_of_month

    records = AttendanceRecord.where(employee_id: employee_id, date: start_date..end_date)

    calendar_data = records.map do |record|
      {
        date: record.date,
        status: record.status,
        check_in: record.formatted_check_in,
        check_out: record.formatted_check_out,
        working_hours: record.working_hours,
        is_late: record.is_late?,
        status_color: record.status_color,
        status_label: record.status_label
      }
    end

    render json: calendar_data
  end

  private

  def set_attendance_record
    if params[:action] == "today"
      employee_id = params[:employee_id]
      today = Date.current
      @attendance_record = AttendanceRecord.find_by(employee_id: employee_id, date: today)

      unless @attendance_record
        @attendance_record = AttendanceRecord.create!(
          employee_id: employee_id,
          date: today,
          status: "absent"
        )
      end
    else
      @attendance_record = AttendanceRecord.find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Attendance record not found" }, status: :not_found
  end

  def attendance_record_params
    params.require(:attendance_record).permit(:employee_id, :date, :check_in, :check_out, :status, :working_hours)
  end

  def format_attendance_record(record)
    {
      id: record.id,
      employee_id: record.employee_id,
      employee_name: record.employee_name,
      employee_email: record.employee_email,
      employee_department: record.employee_department,
      date: record.date,
      check_in: record.check_in,
      check_out: record.check_out,
      formatted_check_in: record.formatted_check_in,
      formatted_check_out: record.formatted_check_out,
      status: record.status,
      status_label: record.status_label,
      status_color: record.status_color,
      working_hours: record.working_hours,
      overtime_hours: record.overtime_hours,
      is_late: record.is_late?,
      created_at: record.created_at,
      updated_at: record.updated_at
    }
  end
end
