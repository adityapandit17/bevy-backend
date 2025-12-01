class LeaveRequestsController < ApplicationController
  before_action :set_leave_request, only: [ :show, :update, :destroy, :approve, :reject, :cancel ]
  # before_action :authenticate_user!

  def index
    @leave_requests = LeaveRequest.includes(:employee)

    # For regular employees (not HR/Admin), filter by their employee_id
    is_admin_or_hr = current_user&.has_role?("Super Admin") ||
                     current_user&.has_role?("HR Manager") ||
                     current_user&.has_role?("HR") ||
                     current_user&.has_permission?("leave_requests", "index")

    unless is_admin_or_hr
      if current_user&.employee_id.present?
        @leave_requests = @leave_requests.by_employee(current_user.employee_id)
      else
        # If user has no employee_id, return empty array
        render json: []
        return
      end
    end

    # Apply filters (only for HR/Admin or if explicitly provided)
    @leave_requests = @leave_requests.by_employee(params[:employee_id]) if params[:employee_id].present?
    @leave_requests = @leave_requests.by_type(params[:leave_type]) if params[:leave_type].present?
    @leave_requests = @leave_requests.where(status: params[:status]) if params[:status].present?
    @leave_requests = @leave_requests.current_year if params[:current_year] == "true"
    @leave_requests = @leave_requests.upcoming if params[:upcoming] == "true"
    @leave_requests = @leave_requests.past if params[:past] == "true"

    # Apply date range filter
    if params[:start_date].present? && params[:end_date].present?
      @leave_requests = @leave_requests.where(start_date: params[:start_date]..params[:end_date])
    end

    # Filter by manager pending approvals
    if params[:manager_pending] == "true" && current_user&.employee
      manager_employee_id = current_user.employee.id
      @leave_requests = @leave_requests.pending_for_manager(manager_employee_id)
    end

    # Apply search
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @leave_requests = @leave_requests.joins(:employee)
        .where("employees.first_name ILIKE ? OR employees.last_name ILIKE ? OR employees.email ILIKE ?",
               search_term, search_term, search_term)
    end

    render json: @leave_requests.map { |request| format_leave_request(request) }
  end

  def show
    render json: format_leave_request(@leave_request)
  end

  def create
    @leave_request = LeaveRequest.new(leave_request_params)

    # Check authorization: user can only apply for their own leave unless they're HR/Admin
    unless can_apply_leave_for?(@leave_request.employee_id)
      render json: { errors: [ "You don't have permission to apply leave for this employee" ] }, status: :forbidden
      return
    end

    # Assign approvers context (manager inferred from employee)
    if @leave_request.employee&.manager
      # no persisted field needed now; used for UI
    end

    # Check for overlapping leave requests
    if overlapping_requests_exist?
      render json: { errors: [ "You already have a leave request for this period" ] }, status: :unprocessable_entity
      return
    end

    if @leave_request.save
      create_leave_request_notification(@leave_request, current_user)
      render json: format_leave_request(@leave_request), status: :created
    else
      render json: { errors: @leave_request.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @leave_request.can_be_modified?
      if @leave_request.update(leave_request_params)
        render json: format_leave_request(@leave_request)
      else
        render json: { errors: @leave_request.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { errors: [ "This leave request cannot be modified" ] }, status: :unprocessable_entity
    end
  end

  def destroy
    if @leave_request.can_be_cancelled?
      @leave_request.destroy
      head :no_content
    else
      render json: { errors: [ "This leave request cannot be cancelled" ] }, status: :unprocessable_entity
    end
  end

  # Approve leave request (stepwise: manager then HR)
  def approve
    unless current_user
      render json: { errors: [ "Authentication required" ] }, status: :unauthorized
      return
    end

    # Check if user is HR Manager or has HR approval permission
    if current_user.hr_manager? || current_user.has_permission?("leave_requests", "approve")
      if @leave_request.manager_approved? || @leave_request.pending?
        @leave_request.update!(
          status: "approved",
          hr_approved_by: current_user,
          hr_approved_at: Time.current
        )
        create_leave_approved_notification(@leave_request, current_user)
        render json: format_leave_request(@leave_request)
      else
        render json: { errors: [ "Manager approval required before HR approval" ] }, status: :unprocessable_entity
      end
    else
      # Check if current_user is the manager of the employee
      employee = @leave_request.employee
      manager_employee = current_user.employee

      unless manager_employee && employee.manager_id == manager_employee.id
        render json: { errors: [ "You are not authorized to approve this leave request. Only the employee's manager can approve." ] }, status: :forbidden
        return
      end

      # Manager approval
      if @leave_request.pending?
        @leave_request.update!(
          status: "manager_approved",
          manager_approved_by: current_user,
          manager_approved_at: Time.current
        )
        render json: format_leave_request(@leave_request)
      else
        render json: { errors: [ "Only pending requests can be manager-approved" ] }, status: :unprocessable_entity
      end
    end
  end

  # Reject leave request
  def reject
    unless current_user
      render json: { errors: [ "Authentication required" ] }, status: :unauthorized
      return
    end

    if @leave_request.pending? || @leave_request.manager_approved?
      @leave_request.update!(
        status: "rejected",
        rejected_by: current_user,
        rejected_at: Time.current,
        rejected_reason: params[:reason]
      )
      create_leave_rejected_notification(@leave_request, current_user)
      render json: format_leave_request(@leave_request)
    else
      render json: { errors: [ "Only pending or manager-approved requests can be rejected" ] }, status: :unprocessable_entity
    end
  end

  # Cancel leave request
  def cancel
    if @leave_request.can_be_cancelled?
      @leave_request.update!(status: "cancelled")
      render json: format_leave_request(@leave_request)
    else
      render json: { errors: [ "This leave request cannot be cancelled" ] }, status: :unprocessable_entity
    end
  end

  # Get leave balance for an employee
  def balance
    employee_id = params[:employee_id]
    year = params[:year] || Date.current.year

    # If employee_id is provided, validate access
    if employee_id.present?
      unless can_access_employee_data?(employee_id)
        render json: { error: "You don't have permission to view this employee's leave balance" }, status: :forbidden
        return
      end
    else
      # If no employee_id provided, use current user's employee_id
      if current_user&.employee_id.present?
        employee_id = current_user.employee_id
      else
        render json: { error: "Employee ID is required" }, status: :bad_request
        return
      end
    end

    balance = LeaveRequest.employee_leave_summary(employee_id, year)
    render json: balance
  end

  # Get leave calendar for team/department
  def calendar
    employee_ids = params[:employee_ids]&.split(",") || []
    start_date = params[:start_date] || Date.current.beginning_of_month
    end_date = params[:end_date] || Date.current.end_of_month

    if employee_ids.any?
      calendar_data = LeaveRequest.team_leave_calendar(employee_ids, start_date, end_date)
      render json: calendar_data.map { |request| format_leave_request(request) }
    else
      render json: { error: "Employee IDs required" }, status: :bad_request
    end
  end

  # Get leave statistics
  def stats
    department_id = params[:department_id]
    year = params[:year] || Date.current.year

    if department_id.present?
      stats = LeaveRequest.department_leave_stats(department_id, year)
    else
      # Overall stats
      start_of_year = Date.new(year, 1, 1)
      end_of_year = Date.new(year, 12, 31)

      requests = LeaveRequest.where(start_date: start_of_year..end_of_year)

      stats = {
        total_requests: requests.size,
        approved_requests: requests.approved.size,
        pending_requests: requests.pending.size,
        rejected_requests: requests.rejected.size,
        total_days_taken: requests.approved.sum(:days),
        by_leave_type: requests.approved.group(:leave_type).sum(:days),
        by_status: requests.group(:status).size
      }
    end

    render json: stats
  end

  # Get approvers for an employee (manager, HR)
  def approvers
    employee_id = params[:employee_id]
    employee = Employee.find_by(id: employee_id)
    if employee
      render json: approvers_for(employee)
    else
      render json: { error: "Employee not found" }, status: :not_found
    end
  end

  # Optimized endpoint: Get pending leave requests from PendingTask
  def pending_from_tasks
    return render json: [], status: :ok unless current_user&.employee

    employee_id = current_user.employee.id

    # Get pending tasks for leave requests assigned to this employee
    pending_tasks = PendingTask.pending
                                .by_type("LeaveRequest")
                                .for_employee(employee_id)
                                .includes(taskable: { employee: :department })

    # For HR/Admin users who are NOT managers (no direct reports), show all pending leaves
    is_admin_or_hr = current_user.has_role?("Super Admin") ||
                     current_user.has_role?("HR Manager") ||
                     current_user.has_role?("HR") ||
                     current_user.has_permission?("leave_requests", "index")

    has_direct_reports = current_user.employee.direct_reports.active.exists?

    # Only show all pending leaves if user is HR/Admin AND has no direct reports
    if is_admin_or_hr && !has_direct_reports && pending_tasks.empty?
      pending_tasks = PendingTask.pending
                                  .by_type("LeaveRequest")
                                  .joins("INNER JOIN leave_requests ON pending_tasks.taskable_id = leave_requests.id")
                                  .joins("INNER JOIN employees ON leave_requests.employee_id = employees.id")
                                  .where("employees.status = ?", "active")
                                  .includes(taskable: { employee: :department })
                                  .distinct
    end

    # Format the response to match what frontend expects
    leave_requests = pending_tasks.map do |task|
      leave_request = task.taskable
      next unless leave_request.is_a?(LeaveRequest)

      format_leave_request(leave_request)
    end.compact

    render json: leave_requests
  end

  private

  def set_leave_request
    @leave_request = LeaveRequest.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Leave request not found" }, status: :not_found
  end

  def leave_request_params
    params.require(:leave_request).permit(
      :employee_id,
      :leave_type,
      :start_date,
      :end_date,
      :reason,
      :status,
      :half_day,
      :half_day_period,
      :emergency_contact,
      :handover_notes
    )
  end

  def overlapping_requests_exist?
    return false unless @leave_request.employee_id && @leave_request.start_date && @leave_request.end_date

    existing_requests = LeaveRequest.where(employee_id: @leave_request.employee_id)
                                  .where.not(id: @leave_request.id)
                                  .where(status: [ "pending", "approved" ])

    existing_requests.any? { |request| @leave_request.overlaps_with?(request) }
  end

  def format_leave_request(request)
    {
      id: request.id,
      employee_id: request.employee_id,
      employee_name: request.employee_name,
      employee_email: request.employee_email,
      employee_department: request.employee_department,
      leave_type: request.leave_type,
      leave_type_label: request.leave_type_label,
      start_date: request.start_date,
      end_date: request.end_date,
      formatted_start_date: request.formatted_start_date,
      formatted_end_date: request.formatted_end_date,
      days: request.days,
      duration_days: request.duration_days,
      reason: request.reason,
      status: request.status,
      status_label: request.status_label,
      status_color: request.status_color,
      manager_approved_by: request.manager_approved_by&.name,
      manager_approved_at: request.manager_approved_at,
      hr_approved_by: request.hr_approved_by&.name,
      hr_approved_at: request.hr_approved_at,
      rejected_by: request.rejected_by&.name,
      rejected_at: request.rejected_at,
      rejected_reason: request.rejected_reason,
      is_current: request.is_current?,
      is_upcoming: request.is_upcoming?,
      is_past: request.is_past?,
      can_be_cancelled: request.can_be_cancelled?,
      can_be_modified: request.can_be_modified?,
      half_day: request.half_day,
      half_day_period: request.half_day_period,
      half_day_period_label: request.half_day_period_label,
      emergency_contact: request.emergency_contact,
      handover_notes: request.handover_notes,
      approvers: approvers_for(request.employee),
      created_at: request.created_at,
      updated_at: request.updated_at
    }
  end

  def create_leave_approved_notification(leave_request, approver)
    employee_user = leave_request.employee&.user
    return unless employee_user

    begin
      employee_user.notifications.create!(
        notification_type: "leave",
        title: "Leave Request Approved",
        message: "Your leave request for #{leave_request.formatted_start_date} to #{leave_request.formatted_end_date} has been approved by #{approver.name}.",
        action_url: "/attendance"
      )
    rescue => e
      Rails.logger.error "Failed to create leave approval notification for LeaveRequest #{leave_request.id}: #{e.message}"
    end
  end

  def create_leave_rejected_notification(leave_request, rejecter)
    employee_user = leave_request.employee&.user
    return unless employee_user

    begin
      employee_user.notifications.create!(
        notification_type: "leave",
        title: "Leave Request Rejected",
        message: "Your leave request for #{leave_request.formatted_start_date} to #{leave_request.formatted_end_date} has been rejected by #{rejecter.name}.",
        action_url: "/attendance"
      )
    rescue => e
      Rails.logger.error "Failed to create leave approval notification for LeaveRequest #{leave_request.id}: #{e.message}"
    end
  end

  def create_leave_request_notification(leave_request, user)
    employee_user = leave_request.employee&.user
    return unless employee_user

    begin
      employee_user.notifications.create!(
        notification_type: "leave",
        title: "Leave Applied",
        message: "Your leave request for #{leave_request.formatted_start_date} to #{leave_request.formatted_end_date} has been applied.",
        action_url: "/attendance"
      )
    rescue => e
      Rails.logger.error "Failed to create leave approval notification for LeaveRequest #{leave_request.id}: #{e.message}"
    end
  end

  def approvers_for(employee)
    return {} unless employee

    manager_user = employee.manager&.user
    hr_user = User.hr_managers.first
    {
      manager: manager_user ? { id: manager_user.id, name: manager_user.name, email: manager_user.email } : nil,
      hr: hr_user ? { id: hr_user.id, name: hr_user.name, email: hr_user.email } : nil
    }
  end
end
