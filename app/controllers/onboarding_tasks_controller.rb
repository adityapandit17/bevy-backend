class OnboardingTasksController < ApplicationController
  before_action :set_onboarding_task, only: [ :show, :update, :destroy ]

  # GET /onboarding_tasks
  def index
    @onboarding_tasks = OnboardingTask.includes(:onboarding_employee)

    # Apply filters
    @onboarding_tasks = @onboarding_tasks.where(onboarding_employee_id: params[:onboarding_employee_id]) if params[:onboarding_employee_id].present?
    @onboarding_tasks = @onboarding_tasks.by_status(params[:status]) if params[:status].present?
    @onboarding_tasks = @onboarding_tasks.by_category(params[:category]) if params[:category].present?
    @onboarding_tasks = @onboarding_tasks.by_priority(params[:priority]) if params[:priority].present?

    render json: @onboarding_tasks.map { |task| format_task(task) }
  end

  # GET /onboarding_tasks/:id
  def show
    render json: format_task(@onboarding_task)
  end

  # POST /onboarding_tasks
  def create
    @onboarding_task = OnboardingTask.new(onboarding_task_params)

    if @onboarding_task.save
      # Update the onboarding employee's progress
      @onboarding_task.onboarding_employee.save

      render json: format_task(@onboarding_task), status: :created
    else
      render json: { errors: @onboarding_task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /onboarding_tasks/:id
  def update
    if @onboarding_task.update(onboarding_task_params)
      # Update the onboarding employee's progress
      @onboarding_task.onboarding_employee.save

      render json: format_task(@onboarding_task)
    else
      render json: { errors: @onboarding_task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /onboarding_tasks/:id
  def destroy
    onboarding_employee = @onboarding_task.onboarding_employee
    @onboarding_task.destroy

    # Update the onboarding employee's progress
    onboarding_employee.save

    head :no_content
  end

  # PATCH /onboarding_tasks/:id/toggle
  def toggle
    @onboarding_task = OnboardingTask.find(params[:id])
    @onboarding_task.update(is_completed: !@onboarding_task.is_completed)

    # Update the onboarding employee's progress
    @onboarding_task.onboarding_employee.save

    render json: format_task(@onboarding_task)
  end

  # GET /onboarding_tasks/overdue
  def overdue
    @overdue_tasks = OnboardingTask.overdue.includes(:onboarding_employee)
    render json: @overdue_tasks.map { |task| format_task(task) }
  end

  # GET /onboarding_tasks/due_soon
  def due_soon
    @due_soon_tasks = OnboardingTask.where("due_date <= ? AND is_completed = ?", Date.current + 3.days, false).includes(:onboarding_employee)
    render json: @due_soon_tasks.map { |task| format_task(task) }
  end

  private

  def set_onboarding_task
    @onboarding_task = OnboardingTask.find(params[:id])
  end

  def onboarding_task_params
    params.require(:onboarding_task).permit(:onboarding_employee_id, :title, :description, :category, :priority, :due_date, :assigned_to, :is_completed, :documents)
  end

  def format_task(task)
    {
      id: task.id,
      onboarding_employee_id: task.onboarding_employee_id,
      title: task.title,
      description: task.description,
      category: task.category,
      is_completed: task.is_completed,
      due_date: task.due_date,
      assigned_to: task.assigned_to,
      priority: task.priority,
      documents: task.documents_list,
      overdue: task.overdue?,
      due_soon: task.due_soon?,
      created_at: task.created_at,
      updated_at: task.updated_at
    }
  end
end
