class PerformanceGoalsController < ApplicationController
  before_action :set_performance_goal, only: [ :show, :update, :destroy ]

  def index
    @performance_goals = PerformanceGoal.for_current_company
    render json: @performance_goals
  end

  def show
    render json: @performance_goal
  end

  def create
    @performance_goal = PerformanceGoal.new(performance_goal_params)
    if @performance_goal.save
      render json: @performance_goal, status: :created
    else
      render json: { errors: @performance_goal.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @performance_goal.update(performance_goal_params)
      render json: @performance_goal
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
    @performance_goal = find_in_tenant(PerformanceGoal, params[:id])
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def performance_goal_params
    params.require(:performance_goal).permit(:employee_id, :title, :description, :target, :progress, :status, :due_date)
  end
end
