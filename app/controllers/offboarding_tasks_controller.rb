class OffboardingTasksController < ApplicationController
  before_action :set_offboarding_task, only: [ :show, :update, :destroy, :toggle ]

  def index
    @offboarding_tasks = OffboardingTask.includes(:offboarding_employee)

    # Apply filters
    @offboarding_tasks = @offboarding_tasks.where(is_completed: params[:completed]) if params[:completed].present?
    @offboarding_tasks = @offboarding_tasks.by_category(params[:category]) if params[:category].present?
    @offboarding_tasks = @offboarding_tasks.by_priority(params[:priority]) if params[:priority].present?

    # Apply special filters
    @offboarding_tasks = @offboarding_tasks.overdue if params[:overdue] == "true"
    @offboarding_tasks = @offboarding_tasks.due_soon if params[:due_soon] == "true"

    render json: @offboarding_tasks.map { |task| format_task(task) }
  end

  def show
    render json: format_task(@offboarding_task)
  end

  def create
    @offboarding_task = OffboardingTask.new(offboarding_task_params)

    if @offboarding_task.save
      render json: format_task(@offboarding_task), status: :created
    else
      render json: { errors: @offboarding_task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @offboarding_task.update(offboarding_task_params)
      render json: format_task(@offboarding_task)
    else
      render json: { errors: @offboarding_task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @offboarding_task.destroy
    head :no_content
  end

  def toggle
    @offboarding_task.toggle_completion!
    render json: format_task(@offboarding_task)
  end

  def overdue
    @overdue_tasks = OffboardingTask.includes(:offboarding_employee).overdue
    render json: @overdue_tasks.map { |task| format_task_with_employee(task) }
  end

  def due_soon
    @due_soon_tasks = OffboardingTask.includes(:offboarding_employee).due_soon
    render json: @due_soon_tasks.map { |task| format_task_with_employee(task) }
  end

  def by_employee
    employee_id = params[:employee_id]
    @tasks = OffboardingTask.joins(:offboarding_employee)
      .where(offboarding_employees: { employee_id: employee_id })
      .includes(:offboarding_employee)

    render json: @tasks.map { |task| format_task(task) }
  end

  def stats
    total_tasks = OffboardingTask.count
    completed_tasks = OffboardingTask.completed.count
    pending_tasks = OffboardingTask.pending.count
    overdue_tasks = OffboardingTask.overdue.count
    due_soon_tasks = OffboardingTask.due_soon.count

    # Category breakdown
    category_stats = OffboardingTask.group(:category).count

    # Priority breakdown
    priority_stats = OffboardingTask.group(:priority).count

    # Completion rate
    completion_rate = total_tasks > 0 ? ((completed_tasks.to_f / total_tasks) * 100).round(1) : 0

    render json: {
      total_tasks: total_tasks,
      completed_tasks: completed_tasks,
      pending_tasks: pending_tasks,
      overdue_tasks: overdue_tasks,
      due_soon_tasks: due_soon_tasks,
      completion_rate: completion_rate,
      category_stats: category_stats,
      priority_stats: priority_stats
    }
  end

  private

  def set_offboarding_task
    @offboarding_task = OffboardingTask.find(params[:id])
  end

  def offboarding_task_params
    params.require(:offboarding_task).permit(
      :offboarding_employee_id,
      :title,
      :description,
      :category,
      :priority,
      :due_date,
      :assigned_to,
      :is_completed,
      :completed_date,
      :documents
    )
  end

  def format_task(task)
    {
      id: task.id,
      offboardingEmployeeId: task.offboarding_employee_id,
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
      categoryIcon: task.category_icon,
      priorityLabel: task.priority_label,
      dueDateFormatted: task.due_date_formatted,
      completedDateFormatted: task.completed_date_formatted,
      createdAt: task.created_at.iso8601,
      updatedAt: task.updated_at.iso8601
    }
  end

  def format_task_with_employee(task)
    task_data = format_task(task)
    task_data[:employee] = {
      id: task.offboarding_employee.employee_id_code,
      name: task.offboarding_employee.employee_name,
      email: task.offboarding_employee.employee_email,
      department: task.offboarding_employee.employee_department,
      position: task.offboarding_employee.employee_position
    }
    task_data
  end
end
