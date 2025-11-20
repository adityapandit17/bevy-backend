class AttendanceRecordsController < ApplicationController
  before_action :set_attendance_record, only: [ :show, :update, :destroy ]
  before_action :set_employee, only: [:clock_in, :clock_out]

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

  def clock_in
    unless @employee
      render json: { error: "Employee not found" }, status: :not_found
      return
    end
    
    service = AttendanceService.new(@employee)
    result = service.clock_in

    if result.is_a?(Hash) && result[:error]
      render json: { error: result[:error] }, status: :unprocessable_entity
    else
      # Reload to ensure we have all associations
      result.reload
      
      # Query sessions directly to ensure we get fresh data
      sessions = AttendanceSession
                  .where(attendance_record_id: result.id)
                  .order(created_at: :asc)
      
      Rails.logger.info "Clock in response: Record #{result.id}, Sessions count: #{sessions.count}"
      
      render json: {
        message: "Clock-in successful",
        attendance_record: format_attendance_record(result),
        sessions: sessions.map do |session|
          {
            id: session.id,
            check_in: session.check_in,
            check_out: session.check_out,
            session_hours: session.session_hours,
            created_at: session.created_at,
            updated_at: session.updated_at
          }
        end
      }, status: :ok
    end
  rescue => e
    Rails.logger.error "Error in clock_in: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { 
      error: "Failed to clock in",
      message: e.message
    }, status: :internal_server_error
  end

  def clock_out
    unless @employee
      render json: { error: "Employee not found" }, status: :not_found
      return
    end
    
    service = AttendanceService.new(@employee)
    result = service.clock_out

    if result.is_a?(Hash) && result[:error]
      render json: { error: result[:error] }, status: :unprocessable_entity
    else
      # Reload to ensure we have all associations
      result.reload
      render json: {
        message: "Clock-out successful",
        attendance_record: format_attendance_record(result),
        sessions: result.attendance_sessions.reload.map do |session|
          {
            id: session.id,
            check_in: session.check_in,
            check_out: session.check_out,
            session_hours: session.session_hours,
            created_at: session.created_at,
            updated_at: session.updated_at
          }
        end
      }, status: :ok
    end
  rescue => e
    Rails.logger.error "Error in clock_out: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { 
      error: "Failed to clock out",
      message: e.message
    }, status: :internal_server_error
  end


  # Get today's attendance for an employee
  # Returns all records for today with total hours and sessions
  def today
    employee_id = params[:employee_id]
    
    unless employee_id.present?
      render json: { error: "employee_id parameter is required" }, status: :bad_request
      return
    end
    
    # Convert to integer if it's a string
    employee_id = employee_id.to_i
    
    unless employee_id > 0
      render json: { error: "Invalid employee_id" }, status: :bad_request
      return
    end
    
    today = Date.current

    # Get all records for today with sessions
    records = AttendanceRecord
      .includes(:attendance_sessions)
      .where(employee_id: employee_id, date: today)
      .order(created_at: :asc)

    # Calculate total hours from all sessions across all records
    total_hours = 0.0
    records.each do |record|
      record.attendance_sessions.each do |session|
        if session.check_in.present? && session.check_out.present?
          duration = session.check_out - session.check_in
          hours = (duration / 1.hour)
          total_hours += hours if hours > 0 && hours < 24
        elsif session.session_hours.present?
          total_hours += session.session_hours if session.session_hours > 0 && session.session_hours < 24
        end
      end
    end
    total_hours = total_hours.round(2)

    # Find if there's an active session (any session without check_out)
    # Use direct SQL query to ensure we get fresh data
    active_session = nil
    active_record = nil
    records.each do |record|
      session = AttendanceSession
                  .where(attendance_record_id: record.id)
                  .where("check_out IS NULL")
                  .order(created_at: :desc)
                  .first
      if session
        active_session = session
        active_record = record
        break
      end
    end

    # Collect all sessions from all records
    all_sessions = []
    records.each do |record|
      record.attendance_sessions.each do |session|
        all_sessions << {
          id: session.id,
          attendance_record_id: record.id,
          check_in: session.check_in,
          check_out: session.check_out,
          session_hours: session.session_hours,
          created_at: session.created_at,
          updated_at: session.updated_at
        }
      end
    end

    # Always return sessions array and total hours
    result = {
      total_hours_today: total_hours,
      total_sessions_today: all_sessions.count,
      sessions: all_sessions,
      attendance_records: records.map { |r| format_attendance_record(r) }
    }
    
    # If there's an active session, also include it as the main record
    if active_record && active_session
      result.merge!({
        id: active_record.id,
        employee_id: employee_id,
        date: today,
        check_in: active_session.check_in,
        check_out: nil,
        status: "present",
        current_session_id: active_session.id
      })
    else
      # Return summary if no active session
      result.merge!({
        id: nil,
        employee_id: employee_id,
        date: today,
        check_in: nil,
        check_out: nil,
        status: "absent",
        current_session_id: nil
      })
    end
    
    render json: result
  rescue => e
    Rails.logger.error "Error in today endpoint: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { 
      error: "Failed to fetch today's attendance",
      message: e.message
    }, status: :internal_server_error
  end

  # Get attendance statistics
  def stats
    employee_id = params[:employee_id]
    start_date = params[:start_date] || Date.current.beginning_of_month
    end_date = params[:end_date] || Date.current.end_of_month

    records = AttendanceRecord.where(employee_id: employee_id, date: start_date..end_date)

    stats = {
      total_days: records.size,
      present_days: records.present.size,
      absent_days: records.absent.size,
      late_days: records.late.size,
      half_days: records.half_day.size,
      work_from_home_days: records.work_from_home.size,
      total_working_hours: records.sum(:working_hours),
      average_working_hours: records.average(:working_hours)&.round(2) || 0,
      attendance_percentage: records.size > 0 ? ((records.present.size.to_f / records.size) * 100).round(2) : 0
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

  def set_employee
    employee_id = params[:employee_id]
    
    unless employee_id.present?
      render json: { error: "employee_id parameter is required" }, status: :bad_request
      return
    end
    
    @employee = Employee.find(employee_id)
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Employee not found" }, status: :not_found
  end

  def set_attendance_record
    @attendance_record = AttendanceRecord.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Attendance record not found" }, status: :not_found
  end

  def attendance_record_params
    params.require(:attendance_record).permit(:employee_id, :date, :check_in, :check_out, :status, :working_hours)
  end

  def format_attendance_record(record)
    # Get first session's check_in and last session's check_out for backward compatibility
    first_session = record.attendance_sessions.order(created_at: :asc).first
    last_session = record.attendance_sessions.order(created_at: :desc).first
    
    {
      id: record.id,
      employee_id: record.employee_id,
      employee_name: record.employee_name,
      employee_email: record.employee_email,
      employee_department: record.employee_department,
      date: record.date,
      check_in: first_session&.check_in,
      check_out: last_session&.check_out,
      formatted_check_in: first_session&.check_in&.strftime("%I:%M %p"),
      formatted_check_out: last_session&.check_out&.strftime("%I:%M %p"),
      status: record.status,
      status_label: record.status_label,
      status_color: record.status_color,
      working_hours: record.working_hours || record.total_hours,
      overtime_hours: (record.working_hours || record.total_hours) > 8 ? ((record.working_hours || record.total_hours) - 8) : 0,
      is_late: first_session&.check_in ? (first_session.check_in > Time.parse("09:00")) : false,
      created_at: record.created_at,
      updated_at: record.updated_at,
      attendance_sessions: record.attendance_sessions.map do |session|
        {
          id: session.id,
          check_in: session.check_in,
          check_out: session.check_out,
          session_hours: session.session_hours,
          created_at: session.created_at,
          updated_at: session.updated_at
        }
      end
    }
  end
end
