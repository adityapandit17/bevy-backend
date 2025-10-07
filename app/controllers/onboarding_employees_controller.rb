class OnboardingEmployeesController < ApplicationController
  before_action :set_onboarding_employee, only: [ :show, :update, :destroy ]

  # GET /onboarding_employees
  def index
    @onboarding_employees = OnboardingEmployee.includes(:employee, :onboarding_tasks)

    # Apply filters
    @onboarding_employees = @onboarding_employees.by_status(params[:status]) if params[:status].present?
    @onboarding_employees = @onboarding_employees.joins(:employee).where("employees.first_name ILIKE ? OR employees.last_name ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?

    render json: @onboarding_employees.map { |oe| format_onboarding_employee(oe) }
  end

  # GET /onboarding_employees/:id
  def show
    render json: format_onboarding_employee(@onboarding_employee)
  end

  # POST /onboarding_employees
  def create
    @onboarding_employee = OnboardingEmployee.new(onboarding_employee_params)

    if @onboarding_employee.save
      # Create default onboarding tasks
      create_default_tasks(@onboarding_employee)

      render json: format_onboarding_employee(@onboarding_employee), status: :created
    else
      render json: { errors: @onboarding_employee.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /onboarding_employees/:id
  def update
    if @onboarding_employee.update(onboarding_employee_params)
      render json: format_onboarding_employee(@onboarding_employee)
    else
      render json: { errors: @onboarding_employee.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /onboarding_employees/:id
  def destroy
    @onboarding_employee.destroy
    head :no_content
  end

  # GET /onboarding_employees/stats
  def stats
    stats = {
      active_onboarding: OnboardingEmployee.active.size,
      completed_this_month: OnboardingEmployee.completed.where("updated_at >= ?", 1.month.ago).size,
      completed_this_week: OnboardingEmployee.completed.where("updated_at >= ?", 1.week.ago).size,
      total_onboarding: OnboardingEmployee.count,
      pending_status: OnboardingEmployee.pending.size,
      in_progress_status: OnboardingEmployee.in_progress.size,
      completed_total: OnboardingEmployee.completed.size,
      pending_tasks: OnboardingTask.pending.size,
      completed_tasks: OnboardingTask.where(is_completed: true).size,
      total_tasks: OnboardingTask.count,
      documents_pending: OnboardingTask.where("documents IS NOT NULL AND documents != ''").pending.size,
      overdue_tasks: OnboardingTask.where("due_date < ? AND is_completed = ?", Date.current, false).size,
      due_soon_tasks: OnboardingTask.where("due_date BETWEEN ? AND ? AND is_completed = ?", Date.current, 3.days.from_now, false).size
    }

    render json: stats
  end

  # GET /onboarding_employees/check_employee/:employee_id
  def check_employee
    employee_id = params[:employee_id]

    if employee_id.blank?
      render json: { error: "Employee ID is required" }, status: :bad_request
      return
    end

    onboarding_status = {
      employee_id: employee_id,
      is_onboarded: OnboardingEmployee.employee_onboarded?(employee_id),
      is_in_onboarding: OnboardingEmployee.employee_in_onboarding?(employee_id),
      available_for_onboarding: OnboardingEmployee.available_for_onboarding?(employee_id)
    }

    render json: onboarding_status
  end

  private

  def set_onboarding_employee
    @onboarding_employee = OnboardingEmployee.find(params[:id])
  end

  def onboarding_employee_params
    params.require(:onboarding_employee).permit(:employee_id, :start_date, :status, :progress, :notes)
  end

  def format_onboarding_employee(onboarding_employee)
    {
      id: onboarding_employee.id,
      employee_id: onboarding_employee.employee_id,
      name: onboarding_employee.employee_name,
      email: onboarding_employee.email,
      position: onboarding_employee.position,
      department: onboarding_employee.department_name,
      start_date: onboarding_employee.start_date,
      status: onboarding_employee.status,
      progress: onboarding_employee.progress,
      notes: onboarding_employee.notes,
      tasks: onboarding_employee.onboarding_tasks.map { |task| format_task(task) },
      created_at: onboarding_employee.created_at,
      updated_at: onboarding_employee.updated_at
    }
  end

  def format_task(task)
    {
      id: task.id,
      title: task.title,
      description: task.description,
      category: task.category,
      is_completed: task.is_completed,
      due_date: task.due_date,
      assigned_to: task.assigned_to,
      priority: task.priority,
      documents: task.documents_list,
      overdue: task.overdue?,
      due_soon: task.due_soon?
    }
  end

  def create_default_tasks(onboarding_employee)
    default_tasks = [
      {
        title: "Complete HR Paperwork",
        description: "Fill out all required HR forms and documentation",
        category: "HR",
        priority: "high",
        due_date: onboarding_employee.start_date - 5.days,
        assigned_to: "HR Team",
        documents: [ "Employment Contract", "Tax Forms", "Emergency Contact" ]
      },
      {
        title: "IT Setup",
        description: "Configure laptop, email, and access to company systems",
        category: "IT",
        priority: "high",
        due_date: onboarding_employee.start_date - 3.days,
        assigned_to: "IT Team"
      },
      {
        title: "Department Orientation",
        description: "Meet with team lead and understand team processes",
        category: "Department",
        priority: "medium",
        due_date: onboarding_employee.start_date + 1.day,
        assigned_to: "Team Lead"
      },
      {
        title: "Company Policy Training",
        description: "Complete mandatory company policy and compliance training",
        category: "Training",
        priority: "medium",
        due_date: onboarding_employee.start_date + 3.days,
        assigned_to: "Training Team"
      }
    ]

    default_tasks.each do |task_attrs|
      onboarding_employee.onboarding_tasks.create!(task_attrs)
    end
  end
end
