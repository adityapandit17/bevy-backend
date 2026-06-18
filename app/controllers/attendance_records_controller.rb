class AttendanceRecordsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_attendance_record, only: [ :show, :update, :destroy ]
  before_action :set_employee, only: [ :clock_in, :clock_out ]
  before_action :authorize_index!, only: [ :index ]
  before_action :authorize_clock_access!, only: [ :clock_in, :clock_out ]
  before_action :authorize_attendance_employee_access!, only: [ :today, :stats, :calendar ]
  before_action :authorize_compliance_report!, only: [ :compliance_report ]

  def index
    @attendance_records = AttendanceRecord.includes(:employee, :attendance_sessions)

    if can_view_all_attendance_records?
      if params[:employee_id].present?
        unless can_access_attendance_for_employee?(params[:employee_id])
          render json: { error: "You don't have permission to view this employee's attendance" }, status: :forbidden
          return
        end
      end
    elsif current_user&.employee_id.present?
      @attendance_records = @attendance_records.by_employee(current_user.employee_id)
    else
      render json: []
      return
    end

    # Apply filters
    @attendance_records = @attendance_records.by_employee(params[:employee_id]) if params[:employee_id].present?

    # Parse date parameter properly
    if params[:date].present?
      begin
        parsed_date = Date.parse(params[:date])
        @attendance_records = @attendance_records.by_date(parsed_date)
      rescue ArgumentError => e
        Rails.logger.error "Invalid date format: #{params[:date]} - #{e.message}"
        render json: { error: "Invalid date format. Please use YYYY-MM-DD format." }, status: :bad_request
        return
      end
    end

    @attendance_records = @attendance_records.where(status: params[:status]) if params[:status].present?
    @attendance_records = @attendance_records.current_month if params[:current_month] == "true"
    @attendance_records = @attendance_records.current_year if params[:current_year] == "true"

    # Apply date range filter
    if params[:start_date].present? && params[:end_date].present?
      begin
        start_date = Date.parse(params[:start_date])
        end_date = Date.parse(params[:end_date])
        @attendance_records = @attendance_records.where(date: start_date..end_date)
      rescue ArgumentError => e
        Rails.logger.error "Invalid date range format: #{e.message}"
        render json: { error: "Invalid date range format. Please use YYYY-MM-DD format." }, status: :bad_request
        return
      end
    end

    # Apply search
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @attendance_records = @attendance_records.joins(:employee)
        .where("employees.first_name ILIKE ? OR employees.last_name ILIKE ? OR employees.email ILIKE ?",
               search_term, search_term, search_term)
    end

    render json: @attendance_records.map { |record| format_attendance_record(record) }
  rescue => e
    Rails.logger.error "Error in attendance_records#index: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: "Failed to fetch attendance records", message: e.message }, status: :internal_server_error
  end

  def show
    render json: format_attendance_record(@attendance_record)
  end

  def create
    begin
      # Extract check_in and check_out from params before creating record (safely)
      attendance_params = params[:attendance_record] || {}
      check_in = attendance_params[:check_in]
      check_out = attendance_params[:check_out]

      @attendance_record = AttendanceRecord.new(attendance_record_params)

      if @attendance_record.save
        # Create attendance session if check_in or check_out is provided
        if check_in.present? || check_out.present?
          session_params = {}
          begin
            session_params[:check_in] = Time.parse(check_in) if check_in.present?
            session_params[:check_out] = Time.parse(check_out) if check_out.present?

            @attendance_record.attendance_sessions.create!(session_params)
            @attendance_record.reload
          rescue ArgumentError => e
            Rails.logger.error "Invalid time format: #{e.message}"
            render json: {
              error: "Invalid time format for check_in or check_out",
              message: e.message
            }, status: :bad_request
            return
          end
        end

        render json: format_attendance_record(@attendance_record), status: :created
      else
        error_messages = @attendance_record.errors.full_messages
        Rails.logger.error "Failed to create attendance record: #{error_messages.join(', ')}"
        render json: {
          error: error_messages.join(", "),
          errors: error_messages
        }, status: :unprocessable_entity
      end
    rescue => e
      Rails.logger.error "Error in attendance_records#create: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: {
        error: "Failed to create attendance record",
        message: e.message
      }, status: :internal_server_error
    end
  end

  def update
    begin
      # Extract check_in and check_out from params before updating record (safely)
      attendance_params = params[:attendance_record] || {}
      check_in = attendance_params[:check_in]
      check_out = attendance_params[:check_out]

      if @attendance_record.update(attendance_record_params)
        # Update or create attendance session if check_in or check_out are provided
        if check_in.present? || check_out.present?
          begin
            # Find existing session or create new one
            session = @attendance_record.attendance_sessions.order(created_at: :asc).first

            if session
              # Update existing session
              update_params = {}
              update_params[:check_in] = Time.parse(check_in) if check_in.present?
              update_params[:check_out] = Time.parse(check_out) if check_out.present?
              session.update!(update_params)
            else
              # Create new session
              session_params = {}
              session_params[:check_in] = Time.parse(check_in) if check_in.present?
              session_params[:check_out] = Time.parse(check_out) if check_out.present?
              @attendance_record.attendance_sessions.create!(session_params)
            end

            @attendance_record.reload
          rescue ArgumentError => e
            Rails.logger.error "Invalid time format: #{e.message}"
            render json: {
              error: "Invalid time format for check_in or check_out",
              message: e.message
            }, status: :bad_request
            return
          end
        end

        render json: format_attendance_record(@attendance_record)
      else
        error_messages = @attendance_record.errors.full_messages
        Rails.logger.error "Failed to update attendance record: #{error_messages.join(', ')}"
        render json: {
          error: error_messages.join(", "),
          errors: error_messages
        }, status: :unprocessable_entity
      end
    rescue => e
      Rails.logger.error "Error in attendance_records#update: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: {
        error: "Failed to update attendance record",
        message: e.message
      }, status: :internal_server_error
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
  # Returns the single attendance record for today with total hours and sessions
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

    # Get the single attendance record for today (only one per employee per day)
    record = AttendanceRecord
      .includes(:attendance_sessions)
      .find_by(employee_id: employee_id, date: today)

    # Calculate total hours from all sessions
    total_hours = 0.0
    all_sessions = []

    if record
      record.attendance_sessions.each do |session|
        if session.check_in.present? && session.check_out.present?
          duration = session.check_out - session.check_in
          hours = (duration / 1.hour)
          total_hours += hours if hours > 0 && hours < 24
        elsif session.session_hours.present?
          total_hours += session.session_hours if session.session_hours > 0 && session.session_hours < 24
        end

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
      total_hours = total_hours.round(2)
    end

    # Find if there's an active session (session without check_out)
    active_session = nil
    if record
      active_session = AttendanceSession
                        .where(attendance_record_id: record.id)
                        .where("check_out IS NULL")
                        .order(created_at: :desc)
                        .first
    end

    # Always return sessions array and total hours
    result = {
      total_hours_today: total_hours,
      total_sessions_today: all_sessions.count,
      sessions: all_sessions,
      attendance_records: record ? [ format_attendance_record(record) ] : []
    }

    # If there's an active session, also include it as the main record
    if record && active_session
      result.merge!({
        id: record.id,
        employee_id: employee_id,
        date: today,
        check_in: active_session.check_in,
        check_out: nil,
        status: record.status,
        current_session_id: active_session.id
      })
    elsif record
      result.merge!({
        id: record.id,
        employee_id: employee_id,
        date: today,
        check_in: nil,
        check_out: nil,
        status: record.status,
        current_session_id: nil
      })
    else
      # Return summary if no record exists
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
    employee = Employee.find(params[:employee_id])
    start_date = parse_date_param(params[:start_date]) || Date.current.beginning_of_month
    end_date = parse_date_param(params[:end_date]) || Date.current.end_of_month

    service = AttendanceComplianceService.new(employee: employee, start_date: start_date, end_date: end_date)
    compliance = service.summary

    records = AttendanceRecord.where(employee_id: employee.id, date: start_date..end_date)

    render json: {
      total_days: records.size,
      present_days: records.present.size,
      absent_days: records.absent.size,
      late_days: records.late.size,
      half_days: records.half_day.size,
      work_from_home_days: records.work_from_home.size,
      total_working_hours: compliance[:total_hours_worked],
      average_working_hours: compliance[:average_daily_hours],
      attendance_percentage: records.size.positive? ? ((records.present.size.to_f / records.size) * 100).round(2) : 0,
      compliance: compliance
    }
  end

  # Get attendance calendar data with day indicators (present / absent / leave / not_marked)
  def calendar
    employee = Employee.find(params[:employee_id])
    start_date = parse_date_param(params[:start_date]) || Date.current.beginning_of_month
    end_date = parse_date_param(params[:end_date]) || Date.current.end_of_month

    service = AttendanceComplianceService.new(employee: employee, start_date: start_date, end_date: end_date)

    render json: {
      days: service.calendar_days,
      compliance: service.summary
    }
  end

  # Admin report: hours worked vs required for all employees
  def compliance_report
    start_date = parse_date_param(params[:start_date]) || Date.current.beginning_of_month
    end_date = parse_date_param(params[:end_date]) || Date.current.end_of_month
    as_of = parse_date_param(params[:as_of]) || Date.current

    employees = AttendanceComplianceService.team_report(
      start_date: start_date,
      end_date: end_date,
      as_of: as_of,
      department_id: params[:department_id]
    )

    company = ActsAsTenant.current_tenant || current_user&.company
    render json: {
      start_date: start_date,
      end_date: end_date,
      as_of: as_of,
      weekly_working_hours: (company&.weekly_working_hours || 40).to_f,
      employees: employees,
      summary: {
        total_employees: employees.size,
        behind_schedule_count: employees.count { |e| e[:hours_behind_schedule].to_f.positive? },
        average_compliance_percent: employees.empty? ? 100 : (employees.sum { |e| e[:compliance_percent] } / employees.size.to_f).round(1)
      }
    }
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
    params.require(:attendance_record).permit(:employee_id, :date, :status, :working_hours)
  end

  def format_attendance_record(record)
    sessions = record.association(:attendance_sessions).loaded? ?
                record.attendance_sessions.sort_by(&:created_at) :
                record.attendance_sessions.order(created_at: :asc)

    first_session = sessions.first
    last_session  = sessions.last

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
      attendance_sessions: sessions.map do |session|
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

  def authorize_index!
    authorize!("attendance_records", "index")
  end

  def authorize_clock_access!
    unless authorize!("attendance_records", "index")
      return
    end

    employee_id = params[:employee_id].to_i
    return if can_access_attendance_for_employee?(employee_id)

    render json: { error: "You can only clock in/out for your own attendance" }, status: :forbidden
  end

  def authorize_attendance_employee_access!
    employee_id = params[:employee_id].to_i
    return if employee_id.positive? && can_access_attendance_for_employee?(employee_id)

    render json: { error: "You don't have permission to view this employee's attendance" }, status: :forbidden
  end

  def authorize_compliance_report!
    return if can_view_all_attendance_records? || current_user&.has_permission?("reports", "index")

    render json: { error: "Insufficient permissions" }, status: :forbidden
  end

  def parse_date_param(value)
    return nil if value.blank?

    Date.parse(value.to_s)
  rescue ArgumentError
    nil
  end
end
