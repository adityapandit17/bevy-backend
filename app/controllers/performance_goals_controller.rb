class PerformanceGoalsController < ApplicationController
  before_action :set_performance_goal, only: [ :show, :update, :destroy ]

  def index
    @performance_goals = PerformanceGoal.includes(:employee).recent
    @performance_goals = @performance_goals.by_employee(params[:employee_id]) if params[:employee_id].present?
    @performance_goals = @performance_goals.by_status(params[:status]) if params[:status].present?
    render json: @performance_goals.map { |g| format_goal(g) }
  end

  def by_employee
    employee_id = params[:employee_id]
    return render json: { error: "employee_id is required" }, status: :bad_request if employee_id.blank?

    goals = PerformanceGoal.includes(:employee).by_employee(employee_id).recent
    render json: goals.map { |g| format_goal(g) }
  end

  def overdue
    goals = PerformanceGoal.includes(:employee).overdue.recent
    render json: goals.map { |g| format_goal(g) }
  end

  def due_soon
    goals = PerformanceGoal.includes(:employee).due_soon.recent
    render json: goals.map { |g| format_goal(g) }
  end

  def update_progress
    @performance_goal = PerformanceGoal.find(params[:id])
    progress = params[:progress].to_i
    if @performance_goal.update(progress: progress)
      render json: format_goal(@performance_goal)
    else
      render json: { errors: @performance_goal.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Performance goal not found" }, status: :not_found
  end

  def show
    render json: format_goal(@performance_goal)
  end

  def create
    @performance_goal = PerformanceGoal.new(performance_goal_params)
    if @performance_goal.save
      render json: format_goal(@performance_goal), status: :created
    else
      render json: { errors: @performance_goal.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @performance_goal.update(performance_goal_params)
      render json: format_goal(@performance_goal)
    else
      render json: { errors: @performance_goal.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @performance_goal.destroy
    head :no_content
  end

  private

  def set_performance_goal
    @performance_goal = PerformanceGoal.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def performance_goal_params
    params.require(:performance_goal).permit(:employee_id, :title, :description, :target, :progress, :status, :due_date)
  end

  def format_goal(goal)
    goal.as_json.merge(
      "employee_name" => goal.employee_name,
      "employee_department" => goal.employee_department,
      "status_color" => goal.status_color,
      "status_label" => goal.status_label,
      "completion_status" => goal.completion_status,
      "formatted_due_date" => goal.formatted_due_date
    )
  end
end
