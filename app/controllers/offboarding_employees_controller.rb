class OffboardingEmployeesController < ApplicationController
  before_action :set_offboarding_employee, only: [:show, :update, :destroy, :update_status]

  def index
    @offboarding_employees = OffboardingEmployee.includes(:employee, :offboarding_tasks)
    
    # Apply filters
    @offboarding_employees = @offboarding_employees.where(status: params[:status]) if params[:status].present?
    @offboarding_employees = @offboarding_employees.by_department(params[:department_id]) if params[:department_id].present?
    
    # Apply search
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @offboarding_employees = @offboarding_employees.joins(:employee)
        .where("employees.first_name ILIKE ? OR employees.last_name ILIKE ? OR employees.email ILIKE ?", 
               search_term, search_term, search_term)
    end

    render json: @offboarding_employees.map { |oe| format_offboarding_employee(oe) }
  end

  def show
    render json: format_offboarding_employee_with_tasks(@offboarding_employee)
  end

  def create
    @offboarding_employee = OffboardingEmployee.new(offboarding_employee_params)
    @offboarding_employee.start_date = Date.current
    @offboarding_employee.progress = 0

    if @offboarding_employee.save
      create_default_tasks(@offboarding_employee)
      render json: format_offboarding_employee_with_tasks(@offboarding_employee), status: :created
    else
      render json: { errors: @offboarding_employee.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @offboarding_employee.update(offboarding_employee_params)
      render json: format_offboarding_employee_with_tasks(@offboarding_employee)
    else
      render json: { errors: @offboarding_employee.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @offboarding_employee.destroy
    head :no_content
  end

  def update_status
    if @offboarding_employee.update(status: params[:status])
      render json: format_offboarding_employee(@offboarding_employee)
    else
      render json: { errors: @offboarding_employee.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def stats
    total_offboarding = OffboardingEmployee.count
    active_offboarding = OffboardingEmployee.active.count
    completed_offboarding = OffboardingEmployee.completed.count
    pending_offboarding = OffboardingEmployee.pending.count
    cancelled_offboarding = OffboardingEmployee.cancelled.count

    # Calculate average duration
    completed_offboardings = OffboardingEmployee.completed
    avg_duration = completed_offboardings.any? ? 
      (completed_offboardings.sum(&:duration_days).to_f / completed_offboardings.count).round : 0

    # Task category breakdown
    task_categories = OffboardingTask.group(:category).count

    render json: {
      total_offboarding: total_offboarding,
      active_offboarding: active_offboarding,
      completed_offboarding: completed_offboarding,
      pending_offboarding: pending_offboarding,
      cancelled_offboarding: cancelled_offboarding,
      avg_duration_days: avg_duration,
      task_categories: task_categories,
      recent_activity: get_recent_activity
    }
  end

  private

  def set_offboarding_employee
    @offboarding_employee = OffboardingEmployee.find(params[:id])
  end

  def offboarding_employee_params
    params.require(:offboarding_employee).permit(
      :employee_id, 
      :last_working_day, 
      :status, 
      :assigned_to, 
      :notes,
      :progress
    )
  end

  def format_offboarding_employee(offboarding_employee)
    {
      id: offboarding_employee.id,
      employeeId: offboarding_employee.employee_id_code,
      name: offboarding_employee.employee_name,
      email: offboarding_employee.employee_email,
      department: offboarding_employee.employee_department,
      position: offboarding_employee.employee_position,
      startDate: offboarding_employee.start_date&.iso8601,
      lastWorkingDay: offboarding_employee.last_working_day&.iso8601,
      status: offboarding_employee.status,
      progress: offboarding_employee.progress,
      assignedTo: offboarding_employee.assigned_to,
      notes: offboarding_employee.notes,
      daysRemaining: offboarding_employee.days_remaining,
      overdue: offboarding_employee.overdue?,
      durationDays: offboarding_employee.duration_days,
      createdAt: offboarding_employee.created_at.iso8601,
      updatedAt: offboarding_employee.updated_at.iso8601
    }
  end

  def format_offboarding_employee_with_tasks(offboarding_employee)
    employee_data = format_offboarding_employee(offboarding_employee)
    employee_data[:tasks] = offboarding_employee.offboarding_tasks.map { |task| format_task(task) }
    employee_data
  end

  def format_task(task)
    {
      id: task.id,
      title: task.title,
      description: task.description,
      category: task.category,
      priority: task.priority,
      dueDate: task.due_date.iso8601,
      assignedTo: task.assigned_to,
      isCompleted: task.is_completed,
      completedDate: task.completed_date&.iso8601,
      overdue: task.overdue?,
      dueSoon: task.due_soon?,
      daysUntilDue: task.days_until_due,
      statusLabel: task.status_label,
      statusColor: task.status_color,
      priorityColor: task.priority_color,
      categoryIcon: task.category_icon
    }
  end

  def create_default_tasks(offboarding_employee)
    default_tasks = [
      {
        title: "Return Company Laptop",
        description: "Return all company equipment including laptop, charger, and accessories",
        category: "Equipment",
        priority: "high",
        due_date: offboarding_employee.last_working_day - 1.day,
        assigned_to: "IT Department"
      },
      {
        title: "Exit Interview",
        description: "Conduct exit interview with HR manager",
        category: "HR",
        priority: "high",
        due_date: offboarding_employee.last_working_day - 1.day,
        assigned_to: "HR Department"
      },
      {
        title: "Knowledge Transfer",
        description: "Transfer knowledge and handover ongoing projects",
        category: "Knowledge Transfer",
        priority: "medium",
        due_date: offboarding_employee.last_working_day,
        assigned_to: offboarding_employee.assigned_to
      },
      {
        title: "Cancel Benefits",
        description: "Cancel health insurance and other benefits",
        category: "Benefits",
        priority: "medium",
        due_date: offboarding_employee.last_working_day,
        assigned_to: "HR Department"
      },
      {
        title: "Return Access Cards",
        description: "Return office access cards and keys",
        category: "Access",
        priority: "high",
        due_date: offboarding_employee.last_working_day,
        assigned_to: "Facilities Department"
      },
      {
        title: "Final Documentation",
        description: "Complete final documentation and handover reports",
        category: "Documentation",
        priority: "medium",
        due_date: offboarding_employee.last_working_day,
        assigned_to: offboarding_employee.assigned_to
      }
    ]

    default_tasks.each do |task_attrs|
      offboarding_employee.offboarding_tasks.create!(task_attrs)
    end
  end

  def get_recent_activity
    recent_tasks = OffboardingTask.includes(:offboarding_employee)
      .where('completed_date >= ?', 7.days.ago)
      .order(completed_date: :desc)
      .limit(5)

    recent_tasks.map do |task|
      {
        id: task.id,
        title: task.title,
        employeeName: task.offboarding_employee.employee_name,
        completedDate: task.completed_date.iso8601,
        category: task.category
      }
    end
  end
end 